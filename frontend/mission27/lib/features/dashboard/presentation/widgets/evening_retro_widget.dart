import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EveningRetroWidget extends ConsumerStatefulWidget {
  const EveningRetroWidget({super.key});

  @override
  ConsumerState<EveningRetroWidget> createState() => _EveningRetroWidgetState();
}

class _EveningRetroWidgetState extends ConsumerState<EveningRetroWidget> {
  bool _loading = true;
  bool _submitting = false;
  bool _isEditing = false;
  
  Map<String, dynamic>? _existingRetro;
  
  final _targetCtrl = TextEditingController();
  final _achievedCtrl = TextEditingController();
  final _positivesCtrl = TextEditingController();
  final _negativesCtrl = TextEditingController();
  final _tomorrowCtrl = TextEditingController();

  bool _showXpAnimation = false;
  int _xpEarned = 0;

  @override
  void initState() {
    super.initState();
    _fetchRetro();
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _achievedCtrl.dispose();
    _positivesCtrl.dispose();
    _negativesCtrl.dispose();
    _tomorrowCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRetro() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/checkin/retro');
      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _existingRetro = data;
          _targetCtrl.text = data['day_target'] ?? '';
          _achievedCtrl.text = data['achieved_summary'] ?? '';
          _positivesCtrl.text = data['positives'] ?? '';
          _negativesCtrl.text = data['negatives'] ?? '';
          _tomorrowCtrl.text = data['tomorrow_plan'] ?? '';
          _isEditing = false;
        });
      }
    } catch (_) {
      // If error or 404, we assume no retro has been submitted yet
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitRetro() async {
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      final payload = {
        'day_target': _targetCtrl.text.trim(),
        'achieved_summary': _achievedCtrl.text.trim(),
        'positives': _positivesCtrl.text.trim(),
        'negatives': _negativesCtrl.text.trim(),
        'tomorrow_plan': _tomorrowCtrl.text.trim(),
      };
      final response = await dio.post('/checkin/retro', data: payload);
      final data = response.data as Map<String, dynamic>;
      
      final xp = data['xp_earned'] as int? ?? 0;
      if (xp > 0) {
        setState(() {
          _xpEarned = xp;
          _showXpAnimation = true;
        });
        ref.invalidate(authStateProvider);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) setState(() => _showXpAnimation = false);
      }

      setState(() {
        _existingRetro = data;
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save reflection: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final hasRetro = _existingRetro != null && 
        (_existingRetro!['achieved_summary'] != null && _existingRetro!['achieved_summary'].toString().isNotEmpty);

    if (hasRetro && !_isEditing) {
      return _buildSummaryCard();
    }

    return _buildFormCard();
  }

  Widget _buildSummaryCard() {
    final retro = _existingRetro!;
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text("Today's Reflection Logged", style: AppTypography.titleMedium.copyWith(color: AppColors.success)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                      onPressed: () => setState(() => _isEditing = true),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (retro['day_target']?.toString().isNotEmpty ?? false) ...[
                      _summaryRow('Primary Target', retro['day_target']),
                      const SizedBox(height: 12),
                    ],
                    _summaryRow('What was achieved', retro['achieved_summary']),
                    const SizedBox(height: 12),
                    if (retro['positives']?.toString().isNotEmpty ?? false) ...[
                      _summaryRow('Positives / Wins', retro['positives']),
                      const SizedBox(height: 12),
                    ],
                    if (retro['negatives']?.toString().isNotEmpty ?? false) ...[
                      _summaryRow('Blockers / Obstacles', retro['negatives']),
                      const SizedBox(height: 12),
                    ],
                    if (retro['tomorrow_plan']?.toString().isNotEmpty ?? false) ...[
                      _summaryRow('Plan for Tomorrow', retro['tomorrow_plan']),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          content ?? 'None',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text("Evening Reflection & Retro", style: AppTypography.titleMedium),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _inputField('What was your target for today?', _targetCtrl, 'e.g. Code auth flow, study IELTS task 2'),
                    const SizedBox(height: 12),
                    _inputField('What did you actually achieve?', _achievedCtrl, 'e.g. Completed backend auth, read 2 articles'),
                    const SizedBox(height: 12),
                    _inputField('What went positive / wins?', _positivesCtrl, 'e.g. Stayed focused for 2 pomodoro cycles'),
                    const SizedBox(height: 12),
                    _inputField('Any roadblocks / negatives?', _negativesCtrl, 'e.g. Distracted in afternoon, got stuck on bug'),
                    const SizedBox(height: 12),
                    _inputField('Plan for tomorrow?', _tomorrowCtrl, 'e.g. Resolve Docker issue, write task UI'),
                    const SizedBox(height: 18),
                    M27Button(
                      label: 'Save Reflection  +15 XP',
                      onPressed: _submitting ? null : _submitRetro,
                      isLoading: _submitting,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showXpAnimation)
          Positioned(
            child: Material(
              color: Colors.transparent,
              child: Text(
                '+$_xpEarned XP',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 500.ms, curve: Curves.elasticOut)
                  .fadeOut(delay: 800.ms, duration: 400.ms),
            ),
          ),
      ],
    );
  }

  Widget _inputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
