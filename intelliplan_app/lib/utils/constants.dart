// App Constants
class AppConstants {
  static const String appName = 'IntelliPlan';
  static const String appVersion = '1.0.0';
  
  // XP and Level Constants
  static const int xpPerLevel = 1000;
  static const int lessonCompleteXP = 50;
  static const int achievementXP = 100;
  
  // Achievement Categories
  static const List<String> achievementCategories = [
    'General',
    'Learning',
    'Consistency',
    'Mastery',
    'Social',
  ];
}

// API Endpoints (for future backend integration)
class ApiConstants {
  static const String baseUrl = 'https://api.intelliplan.com';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String lessonsEndpoint = '/lessons';
  static const String achievementsEndpoint = '/achievements';
  static const String leaderboardEndpoint = '/leaderboard';
}
