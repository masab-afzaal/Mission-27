abstract final class AppConstants {
  static const appName = 'Mission 27';
  static const appVersion = '1.0.0';

  // ── API ──────────────────────────────────────────────────────────────────
  static const baseUrl = 'http://localhost:8000/api/v1'; // ADB reverse tcp:8000 tcp:8000
  static const connectTimeoutMs = 15000;
  static const receiveTimeoutMs = 30000;

  // ── Storage Keys ─────────────────────────────────────────────────────────
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const userKey = 'user_data';

  // ── Gamification ─────────────────────────────────────────────────────────
  static const xpPerHabitComplete = 10;
  static const xpPerGoalMilestone = 50;
  static const xpPerGoalComplete = 200;
  static const xpPerStudySession = 15;
  static const xpPerWorkout = 20;

  // ── Pagination ───────────────────────────────────────────────────────────
  static const defaultPageSize = 20;

  // ── Domains ──────────────────────────────────────────────────────────────
  static const domains = [
    'AI Engineering',
    'Computer Science',
    'IELTS',
    'Health & Fitness',
    'Sports',
    'Research',
    'Social Life',
    'Career',
    'Knowledge',
    'Personal Development',
  ];
}
