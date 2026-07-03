import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../providers/tasks_provider.dart';

String _todayKey() {
  final d = DateTime.now();
  return 'checkin_done_${d.year}_${d.month}_${d.day}';
}

class MorningCheckInModal extends ConsumerStatefulWidget {
  const MorningCheckInModal({super.key});

  static Future<void> showIfNeeded(BuildContext context, WidgetRef ref) async {
    // 1. Local cache check — zero API calls if already done today
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_todayKey()) == true) return;

    // 2. Only show before noon
    if (DateTime.now().hour >= 12) return;

    // 3. Confirm with API — if it fails for any reason, do NOT show the modal
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/checkin');
      if (resp.data != null) {
        await prefs.setBool(_todayKey(), true); // cache it
        return;
      }
    } catch (_) {
      return; // API error (expired token, network) → skip silently
    }

    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MorningCheckInModal(),
    );
  }

  @override
  ConsumerState<MorningCheckInModal> createState() => _MorningCheckInModalState();
}

class _MorningCheckInModalState extends ConsumerState<MorningCheckInModal> {
  int _mood = 3;
  int _energy = 3;
  final List<TextEditingController> _intentionCtrls = List.generate(3, (_) => TextEditingController());
  bool _loading = false;
  int _xpEarned = 0;
  bool _done = false;

  @override
  void dispose() {
    for (final c in _intentionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: _done ? _doneView() : _checkInForm(),
    );
  }

  Widget _doneView() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Morning set!', style: AppTypography.headlineSmall),
          const SizedBox(height: 8),
          Text('+$_xpEarned XP earned', style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Let\'s go', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      );

  Widget _checkInForm() => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🌅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text('Good morning', style: AppTypography.headlineSmall),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.textSecondary),
              ),
            ]),
            const SizedBox(height: 4),
            const Text('60-second morning ritual', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            _label('Mood'),
            const SizedBox(height: 8),
            _ratingRow(_mood, (v) => setState(() => _mood = v), ['😩', '😕', '😐', '🙂', '😊']),
            const SizedBox(height: 20),
            _label('Energy'),
            const SizedBox(height: 8),
            _ratingRow(_energy, (v) => setState(() => _energy = v), ['🔋', '🔋', '⚡', '⚡', '🚀']),
            const SizedBox(height: 24),
            _label("Today's 3 intentions"),
            const SizedBox(height: 2),
            const Text('These become your task list for today.', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            const SizedBox(height: 8),
            for (var i = 0; i < 3; i++) ...[
              TextField(
                controller: _intentionCtrls[i],
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Intention ${i + 1}',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              if (i < 2) const SizedBox(height: 10),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Set My Day', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      );

  Widget _label(String text) => Text(text, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14));

  Widget _ratingRow(int current, ValueChanged<int> onChanged, List<String> emojis) {
    return Row(
      children: List.generate(5, (i) {
        final v = i + 1;
        final active = current == v;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppColors.primary.withOpacity(0.2) : AppColors.background,
                border: Border.all(color: active ? AppColors.primary : AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(emojis[i], style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 2),
                Text('$v', style: TextStyle(fontSize: 11, color: active ? AppColors.primary : AppColors.textTertiary)),
              ]),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _submit() async {
    final intentions = _intentionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (intentions.isEmpty) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post('/checkin', data: {
        'mood': _mood,
        'energy': _energy,
        'intentions': intentions,
      });
      // Cache locally so the modal never appears again today
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_todayKey(), true);
      // Intentions are created as today's tasks server-side — refresh the list
      ref.invalidate(todayTasksProvider);
      setState(() {
        _xpEarned = resp.data['xp_earned'] ?? 15;
        _done = true;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }
}
