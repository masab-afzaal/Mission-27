import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';

class NudgeBannerResponse {
  final String id;
  final String type;
  final String domain;
  final String message;
  final String? action;

  NudgeBannerResponse({
    required this.id,
    required this.type,
    required this.domain,
    required this.message,
    this.action,
  });

  factory NudgeBannerResponse.fromJson(Map<String, dynamic> j) => NudgeBannerResponse(
        id: j['id'],
        type: j['type'],
        domain: j['domain'],
        message: j['message'],
        action: j['action'],
      );
}

final nudgesProvider = FutureProvider<List<NudgeBannerResponse>>((ref) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.get('/nudges');
  return (resp.data as List).map((e) => NudgeBannerResponse.fromJson(e)).toList();
});

class NudgeBanner extends ConsumerStatefulWidget {
  const NudgeBanner({super.key});

  @override
  ConsumerState<NudgeBanner> createState() => _NudgeBannerState();
}

class _NudgeBannerState extends ConsumerState<NudgeBanner> {
  final Set<String> _dismissed = {};

  @override
  Widget build(BuildContext context) {
    final nudges = ref.watch(nudgesProvider);
    return nudges.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final visible = items.where((n) => !_dismissed.contains(n.id)).toList();
        if (visible.isEmpty) return const SizedBox.shrink();
        return Column(
          children: visible.map((n) => _NudgeChip(
            nudge: n,
            onDismiss: () => setState(() => _dismissed.add(n.id)),
          )).toList(),
        );
      },
    );
  }
}

class _NudgeChip extends StatelessWidget {
  final NudgeBannerResponse nudge;
  final VoidCallback onDismiss;

  const _NudgeChip({required this.nudge, required this.onDismiss});

  Color get _color {
    switch (nudge.type) {
      case 'warning':
        return AppColors.warning;
      case 'info':
        return AppColors.primary;
      case 'celebration':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        border: Border.all(color: _color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(_domainIcon(nudge.domain), color: _color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            nudge.message,
            style: TextStyle(color: _color, fontSize: 12, height: 1.4),
          ),
        ),
        GestureDetector(
          onTap: onDismiss,
          child: Icon(Icons.close, color: _color.withOpacity(0.6), size: 16),
        ),
      ]),
    );
  }

  IconData _domainIcon(String domain) {
    switch (domain) {
      case 'habits': return Icons.loop_rounded;
      case 'social': return Icons.people_rounded;
      case 'ielts': return Icons.school_rounded;
      case 'ritual': return Icons.wb_sunny_outlined;
      default: return Icons.info_outline;
    }
  }
}
