import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class DayEvent {
  final String id, eventType, category, description;
  final int points;
  DayEvent.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        eventType = j['event_type'],
        category = j['category'],
        description = j['description'],
        points = j['points'] as int;
}

class TodayEventsData {
  final List<DayEvent> events;
  final int positiveTotal, negativeTotal, netBalance;
  TodayEventsData.fromJson(Map<String, dynamic> j)
      : events = (j['events'] as List).map((e) => DayEvent.fromJson(e)).toList(),
        positiveTotal = j['positive_total'] as int,
        negativeTotal = j['negative_total'] as int,
        netBalance = j['net_balance'] as int;
}

// ── Provider ──────────────────────────────────────────────────────────────────

final todayEventsProvider = FutureProvider<TodayEventsData>((ref) async {
  final resp = await ref.read(dioProvider).get('/events/today');
  return TodayEventsData.fromJson(resp.data);
});

// ── Categories ────────────────────────────────────────────────────────────────

const _positiveCategories = ['study', 'health', 'social', 'prayer', 'focus', 'goal', 'habit', 'read'];
const _negativeCategories = ['distraction', 'procrastination', 'junk food', 'late sleep', 'skip workout', 'wasted time', 'phone overuse', 'stress'];

// ── Widget ────────────────────────────────────────────────────────────────────

class DayEventsWidget extends ConsumerWidget {
  const DayEventsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayEventsProvider);
    return Container(
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('Day Balance', style: AppTypography.titleMedium),
              const Spacer(),
              async.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) => _BalancePill(net: data.netBalance),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) => _EventsBody(data: data),
          ),
          _LogButtons(
            onLog: (type, category, desc, points) async {
              try {
                await ref.read(dioProvider).post('/events', data: {
                  'event_type': type,
                  'category': category,
                  'description': desc,
                  'points': points,
                });
                ref.invalidate(todayEventsProvider);
              } catch (_) {}
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final int net;
  const _BalancePill({required this.net});

  @override
  Widget build(BuildContext context) {
    final positive = net >= 0;
    final color = positive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(
        '${positive ? '+' : ''}$net pts',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EventsBody extends StatelessWidget {
  final TodayEventsData data;
  const _EventsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text('No events logged yet today.', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
      );
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _MiniStat('+${data.positiveTotal}', AppColors.success),
          const SizedBox(width: 12),
          _MiniStat('-${data.negativeTotal}', AppColors.error),
        ]),
      ),
      const SizedBox(height: 10),
      ...data.events.take(4).map((e) => _EventRow(event: e)),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniStat(this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
  ]);
}

class _EventRow extends StatelessWidget {
  final DayEvent event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final pos = event.eventType == 'positive';
    final color = pos ? AppColors.success : AppColors.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(children: [
        Icon(pos ? Icons.add_circle_outline : Icons.remove_circle_outline, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(event.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text('${pos ? '+' : ''}${event.points}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _LogButtons extends StatelessWidget {
  final Future<void> Function(String type, String category, String desc, int points) onLog;
  const _LogButtons({required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(children: [
        Expanded(child: _QuickLogBtn(
          label: '+ Positive',
          color: AppColors.success,
          icon: Icons.add_rounded,
          onTap: () => _showLogSheet(context, 'positive'),
        )),
        const SizedBox(width: 8),
        Expanded(child: _QuickLogBtn(
          label: '− Negative',
          color: AppColors.error,
          icon: Icons.remove_rounded,
          onTap: () => _showLogSheet(context, 'negative'),
        )),
      ]),
    );
  }

  void _showLogSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventLogSheet(type: type, onSubmit: onLog),
    );
  }
}

class _QuickLogBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickLogBtn({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.4))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _EventLogSheet extends StatefulWidget {
  final String type;
  final Future<void> Function(String, String, String, int) onSubmit;
  const _EventLogSheet({required this.type, required this.onSubmit});

  @override
  State<_EventLogSheet> createState() => _EventLogSheetState();
}

class _EventLogSheetState extends State<_EventLogSheet> {
  String? _selectedCategory;
  final _descCtrl = TextEditingController();
  int _points = 10;
  bool _loading = false;

  List<String> get _categories => widget.type == 'positive' ? _positiveCategories : _negativeCategories;
  Color get _color => widget.type == 'positive' ? AppColors.success : AppColors.error;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(widget.type == 'positive' ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: _color),
          const SizedBox(width: 8),
          Text('Log ${widget.type == 'positive' ? 'Positive' : 'Negative'} Event', style: AppTypography.titleMedium),
          const Spacer(),
          GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 16),
        Text('Category', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: _categories.map((c) {
          final sel = _selectedCategory == c;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _color.withOpacity(0.15) : AppColors.background,
                border: Border.all(color: sel ? _color : AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(c, style: TextStyle(color: sel ? _color : AppColors.textSecondary, fontSize: 12)),
            ),
          );
        }).toList()),
        const SizedBox(height: 14),
        TextField(
          controller: _descCtrl,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'What happened?',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Text('Impact: $_points pts', style: TextStyle(color: _color, fontWeight: FontWeight.w600)),
          Expanded(child: Slider(
            value: _points.toDouble(),
            min: 5, max: 50, divisions: 9,
            activeColor: _color,
            inactiveColor: _color.withOpacity(0.2),
            onChanged: (v) => setState(() => _points = v.toInt()),
          )),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _loading || _selectedCategory == null || _descCtrl.text.isEmpty ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _color,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Log Event', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        )),
      ]),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await widget.onSubmit(widget.type, _selectedCategory!, _descCtrl.text.trim(), _points);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
