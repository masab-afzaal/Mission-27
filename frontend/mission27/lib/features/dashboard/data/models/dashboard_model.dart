import '../../domain/entities/dashboard_entity.dart';

class ScoreBundleModel extends ScoreBundle {
  const ScoreBundleModel({
    required super.growthScore,
    required super.consistencyScore,
    required super.goalProgressScore,
    required super.learningScore,
    required super.healthScore,
    required super.socialScore,
    required super.careerProgressScore,
    required super.ieltsReadiness,
    required super.aiReadiness,
    required super.burnoutRisk,
    required super.isolationRisk,
    required super.futureSelfAlignment,
  });

  factory ScoreBundleModel.fromJson(Map<String, dynamic> json) {
    double _d(String k) => (json[k] as num?)?.toDouble() ?? 0.0;
    return ScoreBundleModel(
      growthScore: _d('growth_score'),
      consistencyScore: _d('consistency_score'),
      goalProgressScore: _d('goal_progress_score'),
      learningScore: _d('learning_score'),
      healthScore: _d('health_score'),
      socialScore: _d('social_score'),
      careerProgressScore: _d('career_progress_score'),
      ieltsReadiness: _d('ielts_readiness'),
      aiReadiness: _d('ai_readiness'),
      burnoutRisk: _d('burnout_risk'),
      isolationRisk: _d('isolation_risk'),
      futureSelfAlignment: _d('future_self_alignment'),
    );
  }
}

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.today,
    required super.activeStreaks,
    required super.neglectedDomains,
    required super.userLevel,
    required super.userXp,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      today: ScoreBundleModel.fromJson(json['today'] as Map<String, dynamic>),
      activeStreaks: (json['active_streaks'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      neglectedDomains: (json['neglected_domains'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      userLevel: json['user_level'] as int? ?? 1,
      userXp: json['user_xp'] as int? ?? 0,
    );
  }
}
