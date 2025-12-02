import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/gamification_service.dart';
import 'services/schedule_service.dart';
import 'services/pomodoro_service.dart';
import 'services/spaced_repetition_service.dart';
import 'services/active_recall_service.dart';
import 'services/analytics_service.dart';
import 'services/team_service.dart';
import 'services/notification_service.dart';
import 'services/subject_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with auto-generated config
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Session persistence is enabled by default in Firebase Auth
  // User will stay logged in until they explicitly log out
  
  runApp(const IntelliPlanApp());
}

class IntelliPlanApp extends StatelessWidget {
  const IntelliPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => GamificationService()),
        ChangeNotifierProvider(create: (_) => ScheduleService()),
        ChangeNotifierProvider(create: (_) => TeamService()),
        ChangeNotifierProvider(create: (_) => SubjectService()),
        ChangeNotifierProxyProvider<GamificationService, PomodoroService>(
          create: (context) => PomodoroService(context.read<GamificationService>()),
          update: (context, gamification, previous) => 
            previous ?? PomodoroService(gamification),
        ),
        ChangeNotifierProxyProvider<GamificationService, SpacedRepetitionService>(
          create: (context) => SpacedRepetitionService(context.read<GamificationService>()),
          update: (context, gamification, previous) => 
            previous ?? SpacedRepetitionService(gamification),
        ),
        ChangeNotifierProxyProvider<GamificationService, ActiveRecallService>(
          create: (context) => ActiveRecallService(context.read<GamificationService>()),
          update: (context, gamification, previous) => 
            previous ?? ActiveRecallService(gamification),
        ),
        ChangeNotifierProvider(create: (_) => AnalyticsService()),
      ],
      child: MaterialApp.router(
        title: 'IntelliPlan',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
