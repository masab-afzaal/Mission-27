import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/m27_card.dart';
import '../../domain/entities/dashboard_entity.dart';

class ScoreGrid extends StatelessWidget {
  final ScoreBundle scores;

  const ScoreGrid({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ScoreItem('Consistency', scores.consistencyScore, Icons.loop_rounded, AppColors.domainAI),
      _ScoreItem('Learning', scores.learningScore, Icons.school_outlined, AppColors.domainCS),
      _ScoreItem('Goal Progress', scores.goalProgressScore, Icons.flag_outlined, AppColors.domainIELTS),
      _ScoreItem('Health', scores.healthScore, Icons.favorite_outline_rounded, AppColors.domainHealth),
      _ScoreItem('Social', scores.socialScore, Icons.people_outline, AppColors.domainSocial),
      _ScoreItem('Career', scores.careerProgressScore, Icons.trending_up_rounded, AppColors.domainCareer),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _ScoreCard(item: items[i]),
    );
  }
}

class _ScoreItem {
  final String label;
  final double score;
  final IconData icon;
  final Color color;
  const _ScoreItem(this.label, this.score, this.icon, this.color);
}

class _ScoreCard extends StatelessWidget {
  final _ScoreItem item;
  const _ScoreCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return M27Card(
      borderColor: item.color.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(item.icon, color: item.color, size: 18),
              Text(
                '${item.score.toStringAsFixed(0)}',
                style: TextStyle(
                  color: item.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.score / 100,
                  backgroundColor: item.color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(item.color),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
