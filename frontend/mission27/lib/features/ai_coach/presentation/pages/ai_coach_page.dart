import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/m27_card.dart';

part 'ai_coach_page.g.dart';

class CoachInsight {
  final String category;
  final String title;
  final String message;
  final String priority;
  final String? actionLabel;

  const CoachInsight({
    required this.category,
    required this.title,
    required this.message,
    required this.priority,
    this.actionLabel,
  });

  factory CoachInsight.fromJson(Map<String, dynamic> json) => CoachInsight(
        category: json['category'] as String? ?? 'general',
        title: json['title'] as String,
        message: json['message'] as String,
        priority: json['priority'] as String? ?? 'medium',
        actionLabel: json['action_label'] as String?,
      );
}

class CoachReport {
  final List<CoachInsight> insights;
  final List<String> strengths;
  final List<String> growthAreas;
  final List<String> recommendations;
  final double overallAlignment;

  const CoachReport({
    required this.insights,
    required this.strengths,
    required this.growthAreas,
    required this.recommendations,
    required this.overallAlignment,
  });

  factory CoachReport.fromJson(Map<String, dynamic> json) => CoachReport(
        insights: (json['insights'] as List<dynamic>?)?.map((e) => CoachInsight.fromJson(e as Map<String, dynamic>)).toList() ?? [],
        strengths: (json['strengths'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        growthAreas: (json['growth_areas'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        recommendations: (json['recommendations'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        overallAlignment: (json['overall_alignment'] as num?)?.toDouble() ?? 0.0,
      );
}

@riverpod
Future<CoachReport> coachReport(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/coach/report');
  return CoachReport.fromJson(response.data as Map<String, dynamic>);
}

// ── Chat State & Notifiers ──────────────────────────────────────────────────

class Message {
  final String role;
  final String content;
  const Message(this.role, this.content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatState {
  final List<Message> messages;
  final bool loading;
  const ChatState({required this.messages, this.loading = false});

  ChatState copyWith({List<Message>? messages, bool? loading}) {
    return ChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState(messages: []);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = Message('user', text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      loading: true,
    );

    try {
      final dio = ref.read(dioProvider);
      final payload = {
        'message': text,
        'history': state.messages.sublist(0, state.messages.length - 1).map((m) => m.toJson()).toList(),
      };

      final response = await dio.post('/coach/chat', data: payload);
      final reply = response.data['reply'] as String;

      state = state.copyWith(
        messages: [...state.messages, Message('assistant', reply)],
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [...state.messages, Message('assistant', 'Sorry, I failed to process that request. Details: $e')],
        loading: false,
      );
    }
  }
}

class CoachTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() => ChatNotifier());
final coachTabProvider = NotifierProvider<CoachTabNotifier, int>(() => CoachTabNotifier());

// ── AICoachPage ─────────────────────────────────────────────────────────────

class AICoachPage extends ConsumerWidget {
  const AICoachPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(coachReportProvider);
    final selectedTab = ref.watch(coachTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Coach', style: AppTypography.titleLarge),
            Text(selectedTab == 0 ? 'Your personal mentor' : 'Conversational growth coaching', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.insights_rounded, color: selectedTab == 0 ? AppColors.primary : AppColors.textTertiary),
            onPressed: () => ref.read(coachTabProvider.notifier).setTab(0),
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline_rounded, color: selectedTab == 1 ? AppColors.primary : AppColors.textTertiary),
            onPressed: () => ref.read(coachTabProvider.notifier).setTab(1),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: selectedTab == 0
          ? reportAsync.when(
              loading: () => const _LoadingCoach(),
              error: (_, __) => const _CoachUnavailable(),
              data: (report) => _CoachContent(report: report),
            )
          : const _ChatWidget(),
    );
  }
}

// ── Insights Tab Content ─────────────────────────────────────────────────────

class _CoachContent extends StatelessWidget {
  final CoachReport report;
  const _CoachContent({required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AlignmentCard(alignment: report.overallAlignment).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 20),
          if (report.insights.isNotEmpty) ...[
            Text('Insights', style: AppTypography.titleSmall),
            const SizedBox(height: 10),
            ...report.insights.map((i) => _InsightCard(insight: i).animate().fadeIn(delay: 100.ms)),
            const SizedBox(height: 20),
          ],
          if (report.strengths.isNotEmpty) ...[
            _SectionList('Strengths 💪', report.strengths, AppColors.success).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
          ],
          if (report.growthAreas.isNotEmpty) ...[
            _SectionList('Growth Areas 🎯', report.growthAreas, AppColors.warning).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
          ],
          if (report.recommendations.isNotEmpty) ...[
            _SectionList('Recommendations 🚀', report.recommendations, AppColors.primary).animate().fadeIn(delay: 400.ms),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AlignmentCard extends StatelessWidget {
  final double alignment;
  const _AlignmentCard({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.3), AppColors.secondary.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Future Self Alignment', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                Text('${alignment.toStringAsFixed(0)}%', style: AppTypography.headlineMedium.copyWith(color: AppColors.primary)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: alignment / 100,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Reviewed daily, weekly & monthly', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final CoachInsight insight;
  const _InsightCard({required this.insight});

  Color get _priorityColor {
    switch (insight.priority) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return M27Card(
      borderColor: _priorityColor.withOpacity(0.3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _priorityColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(insight.category.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: _priorityColor, fontSize: 9)),
              ),
              const Spacer(),
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: _priorityColor, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(insight.title, style: AppTypography.titleSmall),
          const SizedBox(height: 4),
          Text(insight.message, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;

  const _SectionList(this.title, this.items, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleSmall),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 6, height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
            ],
          ),
        )),
      ],
    );
  }
}

class _LoadingCoach extends StatelessWidget {
  const _LoadingCoach();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 64)).animate().then().shake(duration: 2000.ms, hz: 0.5),
          const SizedBox(height: 16),
          Text('Analyzing your progress...', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          const CircularProgressIndicator(color: AppColors.primary),
        ],
      ),
    );
  }
}

class _CoachUnavailable extends StatelessWidget {
  const _CoachUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Coach is warming up', style: AppTypography.titleSmall),
          const SizedBox(height: 6),
          Text('Log some activities first to get insights', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Interactive Chat Tab Content ─────────────────────────────────────────────

class _ChatWidget extends ConsumerStatefulWidget {
  const _ChatWidget();

  @override
  ConsumerState<_ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends ConsumerState<_ChatWidget> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    
    ref.read(chatProvider.notifier).sendMessage(text).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Column(
      children: [
        Expanded(
          child: chatState.messages.isEmpty
              ? const _EmptyChat()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatState.messages.length + (chatState.loading ? 1 : 0),
                  itemBuilder: (context, idx) {
                    if (idx == chatState.messages.length) {
                      return const _LoadingBubble();
                    }
                    final msg = chatState.messages[idx];
                    final isUser = msg.role == 'user';
                    return _MessageBubble(message: msg, isUser: isUser);
                  },
                ),
        ),
        _InputBar(controller: _controller, onSend: _send, loading: chatState.loading),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Coach Chat Room', style: AppTypography.titleSmall),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your AI Coach is sync\'d with your daily habits, goals, and obstacle logs. Ask for personalized advice or planning assistance.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isUser;
  const _MessageBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary.withOpacity(0.12) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: Border.all(color: isUser ? AppColors.primary.withOpacity(0.3) : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'YOU' : 'AI COACH',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isUser ? AppColors.primaryLight : AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.4),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: SizedBox(
          width: 24, height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              return Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: AppColors.textTertiary, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat()).scale(
                duration: 600.ms,
                delay: (i * 150).ms,
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.2, 1.2),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool loading;

  const _InputBar({required this.controller, required this.onSend, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: loading ? null : onSend,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: loading ? AppColors.surfaceVariant : AppColors.primary,
              child: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

