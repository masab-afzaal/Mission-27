import 'package:equatable/equatable.dart';

class ScoreBundle extends Equatable {
  final double growthScore;
  final double consistencyScore;
  final double goalProgressScore;
  final double learningScore;
  final double healthScore;
  final double socialScore;
  final double careerProgressScore;
  final double ieltsReadiness;
  final double aiReadiness;
  final double burnoutRisk;
  final double isolationRisk;
  final double futureSelfAlignment;

  const ScoreBundle({
    required this.growthScore,
    required this.consistencyScore,
    required this.goalProgressScore,
    required this.learningScore,
    required this.healthScore,
    required this.socialScore,
    required this.careerProgressScore,
    required this.ieltsReadiness,
    required this.aiReadiness,
    required this.burnoutRisk,
    required this.isolationRisk,
    required this.futureSelfAlignment,
  });

  static const zero = ScoreBundle(
    growthScore: 0,
    consistencyScore: 0,
    goalProgressScore: 0,
    learningScore: 0,
    healthScore: 0,
    socialScore: 0,
    careerProgressScore: 0,
    ieltsReadiness: 0,
    aiReadiness: 0,
    burnoutRisk: 0,
    isolationRisk: 0,
    futureSelfAlignment: 0,
  );

  @override
  List<Object?> get props => [growthScore, consistencyScore, learningScore];
}

class DashboardSummary extends Equatable {
  final ScoreBundle today;
  final List<Map<String, dynamic>> activeStreaks;
  final List<String> neglectedDomains;
  final int userLevel;
  final int userXp;

  const DashboardSummary({
    required this.today,
    required this.activeStreaks,
    required this.neglectedDomains,
    required this.userLevel,
    required this.userXp,
  });

  @override
  List<Object?> get props => [today, userLevel];
}
