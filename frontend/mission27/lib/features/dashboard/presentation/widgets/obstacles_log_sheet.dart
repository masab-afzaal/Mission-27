import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/m27_button.dart';

class ObstaclesLogSheet extends ConsumerStatefulWidget {
  final String? defaultDomain;
  final VoidCallback? onLogged;

  const ObstaclesLogSheet({super.key, this.defaultDomain, this.onLogged});

  static void show(BuildContext context, {String? defaultDomain, VoidCallback? onLogged}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ObstaclesLogSheet(defaultDomain: defaultDomain, onLogged: onLogged),
    );
  }

  @override
  ConsumerState<ObstaclesLogSheet> createState() => _ObstaclesLogSheetState();
}

class _ObstaclesLogSheetState extends ConsumerState<ObstaclesLogSheet> {
  String _blockerType = 'Procrastination';
  late String? _affectedDomain;
  int _severity = 3;
  final _descCtrl = TextEditingController();
  bool _saving = false;

  static const _blockers = [
    'Procrastination',
    'Energy Slump',
    'Distraction',
    'Lack of Time',
    'Technical Blocker',
    'Physical fatigue',
    'Other'
  ];

  static const _domains = [
    'habits',
    'goals',
    'ielts',
    'mastery',
    'health',
    'social',
    'namaz',
    'general'
  ];

  @override
  void initState() {
    super.initState();
    _affectedDomain = widget.defaultDomain ?? 'general';
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/obstacles', data: {
        'blocker_type': _blockerType,
        'affected_domain': _affectedDomain,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'severity': _severity,
      });

      if (widget.onLogged != null) {
        widget.onLogged!();
      }
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Roadblock logged. AI Coach will analyze this trend.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log roadblock.')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            Text('Log Obstacle / Roadblock', style: AppTypography.titleMedium),
            const SizedBox(height: 20),

            // Blocker Type
            Text('Blocker Type', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _blockerType,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _blockers.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _blockerType = v); },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Affected Domain
            Text('Affected Dimension', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _affectedDomain,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _domains.map((d) => DropdownMenuItem(value: d, child: Text(d[0].toUpperCase() + d.substring(1)))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _affectedDomain = v); },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Severity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Severity Blockage: $_severity', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
                Text(
                  _severity >= 4 ? '🔥 Critical' : _severity >= 2 ? '⚠️ Mild' : '🟢 Negligible',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _severity >= 4 ? AppColors.error : _severity >= 2 ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
            Slider(
              value: _severity.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
              onChanged: (v) => setState(() => _severity = v.round()),
            ),
            const SizedBox(height: 12),

            // Description
            Text('Roadblock Description', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'What specifically caused this roadblock, and how can we mitigate it next time?',
                  hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            M27Button(label: 'Log Roadblock', onPressed: _submit, isLoading: _saving, isFullWidth: true),
          ],
        ),
      ),
    );
  }
}
