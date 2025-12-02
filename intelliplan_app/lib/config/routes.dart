import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../screens/splash/splash_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/registration/registration_flow_screen.dart';
import '../screens/auth/login_screen_new.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/new_home_screen.dart';
import '../screens/gamification/achievements_screen.dart';
import '../screens/gamification/leaderboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/study_techniques/pomodoro_screen.dart';
import '../screens/study_techniques/spaced_repetition_screen.dart';
import '../screens/active_recall_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/planner/task_board_screen.dart';
import '../screens/team/team_dashboard_screen.dart';
import '../screens/feedback_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    // REMOVED refreshListenable to prevent automatic redirects on auth state changes
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      
      final path = state.uri.path;
      
      print('DEBUG ROUTER: Redirect check - path: $path, isLoggedIn: $isLoggedIn, user: ${user?.email}');
      
      // Public routes that anyone can access
      final publicRoutes = [
        '/splash',
        '/welcome',
        '/login',
        '/register',
        '/registration',
        '/onboarding',
      ];
      
      // Check if current path is public
      final isPublicRoute = publicRoutes.contains(path);
      
      print('DEBUG ROUTER: isPublicRoute: $isPublicRoute');
      
      // ONLY redirect if not logged in AND trying to access protected route
      // DO NOT redirect if already on a public route
      if (!isLoggedIn && !isPublicRoute) {
        print('DEBUG ROUTER: Redirecting to /welcome (not logged in, trying to access protected route)');
        return '/welcome';
      }
      
      print('DEBUG ROUTER: No redirect needed');
      // Allow all other navigation
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/registration',
        name: 'registration',
        builder: (context, state) => const RegistrationFlowScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const NewHomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/planner',
        name: 'planner',
        builder: (context, state) => const TaskBoardScreen(),
      ),
      GoRoute(
        path: '/pomodoro',
        name: 'pomodoro',
        builder: (context, state) => const PomodoroScreen(),
      ),
      GoRoute(
        path: '/spaced-repetition',
        name: 'spacedRepetition',
        builder: (context, state) => const SpacedRepetitionScreen(),
      ),
      GoRoute(
        path: '/active-recall',
        name: 'activeRecall',
        builder: (context, state) => const ActiveRecallScreen(),
      ),
      GoRoute(
        path: '/schedule',
        name: 'schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/team',
        name: 'team',
        builder: (context, state) => const TeamDashboardScreen(),
      ),
      GoRoute(
        path: '/feedback',
        name: 'feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
