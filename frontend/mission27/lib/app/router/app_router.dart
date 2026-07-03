import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/ai_coach/presentation/pages/ai_coach_page.dart';
import '../../features/pomodoro/presentation/pages/pomodoro_page.dart';
import '../../features/namaz/presentation/pages/namaz_page.dart';
import '../../features/habits/presentation/pages/habits_page.dart';
import '../../features/health/presentation/pages/health_page.dart';
import '../../features/ielts/presentation/pages/ielts_page.dart';
import '../../features/ielts/presentation/pages/ielts_speaking_page.dart';
import '../../features/knowledge/presentation/pages/knowledge_page.dart';
import '../../features/mastery/presentation/pages/mastery_page.dart';
import '../../features/mastery/presentation/pages/identities_page.dart';
import '../../features/social/presentation/pages/social_page.dart';
import '../shell/main_shell.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const goals = '/goals';
  static const habits = '/habits';
  static const health = '/health';
  static const ielts = '/ielts';
  static const ieltsSpeaking = '/ielts/speaking';
  static const knowledge = '/knowledge';
  static const aiCoach = '/coach';
  static const mastery = '/mastery';
  static const identities = '/identities';
  static const social = '/social';
  static const pomodoro = '/pomodoro';
  static const namaz = '/namaz';
  static const root = '/';
}

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.root,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.value?.isAuthenticated ?? false;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;
      if (isAuthenticated && isAuthRoute) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (_, __) => AppRoutes.dashboard,
      ),
      GoRoute(path: AppRoutes.login, pageBuilder: (_, __) => _fade(const LoginPage())),
      GoRoute(path: AppRoutes.register, pageBuilder: (_, __) => _fade(const RegisterPage())),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.dashboard, pageBuilder: (_, __) => _noTransition(const DashboardPage())),
          GoRoute(path: AppRoutes.goals, pageBuilder: (_, __) => _noTransition(const GoalsPage())),
          GoRoute(path: AppRoutes.aiCoach, pageBuilder: (_, __) => _noTransition(const AICoachPage())),
          GoRoute(path: AppRoutes.pomodoro, pageBuilder: (_, __) => _noTransition(const PomodoroPage())),
          GoRoute(path: AppRoutes.namaz, pageBuilder: (_, __) => _noTransition(const NamazPage())),
          GoRoute(path: AppRoutes.habits, pageBuilder: (_, __) => _noTransition(const HabitsPage())),
          GoRoute(path: AppRoutes.health, pageBuilder: (_, __) => _noTransition(const HealthPage())),
          GoRoute(path: AppRoutes.ielts, pageBuilder: (_, __) => _noTransition(const IELTSPage())),
          GoRoute(path: AppRoutes.ieltsSpeaking, pageBuilder: (_, __) => _noTransition(const IELTSSpeakingPage())),
          GoRoute(path: AppRoutes.knowledge, pageBuilder: (_, __) => _noTransition(const KnowledgePage())),
          GoRoute(path: AppRoutes.mastery, pageBuilder: (_, __) => _noTransition(const MasteryPage())),
          GoRoute(path: AppRoutes.identities, pageBuilder: (_, __) => _noTransition(const IdentitiesPage())),
          GoRoute(path: AppRoutes.social, pageBuilder: (_, __) => _noTransition(const SocialPage())),
        ],
      ),
    ],
  );
}

CustomTransitionPage<void> _fade(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
  );
}

NoTransitionPage<void> _noTransition(Widget child) {
  return NoTransitionPage<void>(child: child);
}
