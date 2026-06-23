import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';

// ── Model & Provider ─────────────────────────────────────────────────────────

class DominoData {
  final String? task;
  final bool done;
  final int xpEarned;
  DominoData({this.task, required this.done, required this.xpEarned});
  factory DominoData.fromJson(Map<String, dynamic> j) => DominoData(
        task: j['task'],
        done: j['done'] as bool,
        xpEarned: j['xp_earned'] as int,
      );
}

final dominoProvider = FutureProvider<DominoData>((ref) async {
  final resp = await ref.read(dioProvider).get('/domino');
  return DominoData.fromJson(resp.data);
});

// ── Widget ────────────────────────────────────────────────────────────────────

class DominoTaskWidget extends ConsumerStatefulWidget {
  const DominoTaskWidget({super.key});

  @override
  ConsumerState<DominoTaskWidget> createState() => _DominoTaskWidgetState();
}

class _DominoTaskWidgetState extends ConsumerState<DominoTaskWidget> {
  bool _completing = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dominoProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFFFFB347).withOpacity(0.15),
          const Color(0xFFFF6B6B).withOpacity(0.08),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.4)),
      ),
      child: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
        error: (_, __) => const SizedBox.shrink(),
        data: (data) => _DominoBody(data: data, completing: _completing, onComplete: _complete, onSet: _showSetSheet),
      ),
    );
  }

  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      await ref.read(dioProvider).post('/domino/complete');
      ref.invalidate(dominoProvider);
    } catch (_) {} finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  void _showSetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetDominoSheet(onSet: (task) async {
        await ref.read(dioProvider).post('/domino/set', data: {'task': task});
        ref.invalidate(dominoProvider);
      }),
    );
  }
}

class _DominoBody extends StatelessWidget {
  final DominoData data;
  final bool completing;
  final VoidCallback onComplete, onSet;
  const _DominoBody({required this.data, required this.completing, required this.onComplete, required this.onSet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🎯', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text("Today's Domino", style: AppTypography.titleMedium),
          const Spacer(),
          GestureDetector(onTap: onSet, child: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18)),
        ]),
        const SizedBox(height: 4),
        const Text('One task that makes today a win.', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        const SizedBox(height: 12),
        if (data.task == null || data.task!.isEmpty)
          GestureDetector(
            onTap: onSet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.5), style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Tap to set your domino task →', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
          )
        else
          Row(children: [
            Expanded(child: Text(
              data.task!,
              style: TextStyle(
                color: data.done ? AppColors.textSecondary : AppColors.textPrimary,
                fontSize: 15, fontWeight: FontWeight.w600,
                decoration: data.done ? TextDecoration.lineThrough : null,
              ),
            )),
            const SizedBox(width: 12),
            if (!data.done)
              GestureDetector(
                onTap: completing ? null : onComplete,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB347),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: completing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Done! +25 XP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              )
            else
              const Text('✅ Complete! +25 XP', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
      ]),
    );
  }
}

class _SetDominoSheet extends StatefulWidget {
  final Future<void> Function(String) onSet;
  const _SetDominoSheet({required this.onSet});

  @override
  State<_SetDominoSheet> createState() => _SetDominoSheetState();
}

class _SetDominoSheetState extends State<_SetDominoSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🎯', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text("Set Today's Domino", style: AppTypography.titleMedium),
        const SizedBox(height: 4),
        const Text('The one thing that makes today a win, even if nothing else gets done.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. Solve 5 SQL problems',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFB347))),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _loading || _ctrl.text.isEmpty ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB347),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Set Domino', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        )),
      ]),
    );
  }

  Future<void> _submit() async {
    final task = _ctrl.text.trim();
    if (task.isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.onSet(task);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
