import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

/// Notification Service for push notifications, emails, and in-app notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  Future<void> initialize(String userId) async {
    // Initialize timezone data
    try {
      tz_data.initializeTimeZones();
    } catch (e) {
      debugPrint('⚠️ Timezone already initialized or error: $e');
    }
    
    // Request permission for iOS
    await _requestPermission();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Initialize task notification channels
    await initializeTaskNotificationChannels();
    
    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    
    if (_fcmToken != null) {
      // Save token to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'fcmToken': _fcmToken});
      debugPrint('✅ FCM Token saved: $_fcmToken');
    }
    
    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _firestore
          .collection('users')
          .doc(userId)
          .update({'fcmToken': newToken});
      debugPrint('✅ FCM Token refreshed');
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Check if app was opened from a terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('Notification permission status: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');
    
    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background message received: ${message.notification?.title}');
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Show Pomodoro alarm notification
  Future<void> showPomodoroAlarm({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      fullScreenIntent: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      999, // Special ID for Pomodoro alarms
      title,
      body,
      notificationDetails,
    );
  }

  /// Send notification to a specific user (stored in Firestore)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Notification stored for user: $userId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// Send notification when a team member is removed
  Future<void> sendMemberRemovedNotification({
    required String userId,
    required String teamName,
    required String reason,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Removed from Team',
      body: 'You have been removed from $teamName. Reason: $reason',
      data: {
        'type': 'team_member_removed',
        'teamName': teamName,
        'reason': reason,
      },
    );
  }

  /// Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  /// Send welcome notification upon successful registration
  /// This creates a notification document that a Cloud Function will process
  Future<void> sendWelcomeNotification(String userId, String email, String name) async {
    try {
      await _firestore.collection('mail_queue').add({
        'to': email,
        'template': {
          'name': 'welcome',
          'data': {
            'userName': name,
            'appName': 'IntelliPlan',
          },
        },
        'message': {
          'subject': 'Welcome to IntelliPlan! 🎓',
          'html': _getWelcomeEmailHtml(name),
        },
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      debugPrint('✅ Welcome email queued for $email');
    } catch (e) {
      debugPrint('❌ Error queuing welcome email: $e');
    }
  }
  
  /// Send email verification reminder
  Future<void> sendVerificationReminder(String userId, String email, String name) async {
    try {
      await _firestore.collection('mail_queue').add({
        'to': email,
        'template': {
          'name': 'verification_reminder',
          'data': {
            'userName': name,
          },
        },
        'message': {
          'subject': 'Verify Your Email - IntelliPlan',
          'html': _getVerificationReminderHtml(name),
        },
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      debugPrint('✅ Verification reminder queued for $email');
    } catch (e) {
      debugPrint('❌ Error queuing verification reminder: $e');
    }
  }
  
  /// Track in-app notification
  Future<void> createInAppNotification({
    required String userId,
    required String title,
    required String message,
    String? actionUrl,
    String type = 'info',
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'actionUrl': actionUrl,
        'type': type, // info, success, warning, error
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ In-app notification created for user $userId');
    } catch (e) {
      debugPrint('❌ Error creating in-app notification: $e');
    }
  }
  
  /// Welcome email HTML template
  String _getWelcomeEmailHtml(String name) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f7fa; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #6C63FF 0%, #5A52D5 100%); padding: 40px 20px; text-align: center; }
        .header h1 { color: #ffffff; margin: 0; font-size: 32px; font-weight: 700; }
        .content { padding: 40px 30px; }
        .welcome-text { font-size: 18px; color: #2C3E50; line-height: 1.6; margin-bottom: 20px; }
        .features { background-color: #f8f9fa; border-radius: 12px; padding: 20px; margin: 30px 0; }
        .feature-item { display: flex; align-items: start; margin-bottom: 15px; }
        .feature-icon { color: #6C63FF; font-size: 24px; margin-right: 12px; }
        .cta-button { display: inline-block; background-color: #6C63FF; color: #ffffff; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: 600; margin: 20px 0; }
        .footer { background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 14px; color: #95A5A6; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎓 Welcome to IntelliPlan!</h1>
        </div>
        <div class="content">
            <p class="welcome-text">Hi <strong>$name</strong>,</p>
            <p class="welcome-text">
                Thank you for joining IntelliPlan! We're excited to help you master your studies and achieve your academic goals.
            </p>
            
            <div class="features">
                <h3 style="color: #2C3E50; margin-top: 0;">✨ Here's what you can do:</h3>
                <div class="feature-item">
                    <span class="feature-icon">⏱️</span>
                    <div>
                        <strong>Pomodoro Technique</strong><br>
                        Stay focused with 25-minute study sessions
                    </div>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">🧠</span>
                    <div>
                        <strong>Spaced Repetition</strong><br>
                        Optimize your memory with smart flashcards
                    </div>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">📊</span>
                    <div>
                        <strong>Analytics & Insights</strong><br>
                        Track your progress and productivity patterns
                    </div>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">📅</span>
                    <div>
                        <strong>Smart Scheduling</strong><br>
                        Manage classes, assignments, and study time
                    </div>
                </div>
            </div>
            
            <p class="welcome-text">
                <strong>Next Steps:</strong><br>
                1. Verify your email address (check your inbox)<br>
                2. Complete your profile setup<br>
                3. Start your first study session!
            </p>
            
            <center>
                <a href="https://intelliplan.app" class="cta-button">Get Started →</a>
            </center>
            
            <p style="margin-top: 30px; color: #95A5A6; font-size: 14px;">
                Need help? Reply to this email or visit our support center.
            </p>
        </div>
        <div class="footer">
            <p>IntelliPlan - Your Smart Study Companion</p>
            <p style="margin: 5px 0;">© 2024 IntelliPlan. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }
  
  /// Verification reminder email HTML
  String _getVerificationReminderHtml(String name) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f7fa; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #FF6B6B 0%, #EE5555 100%); padding: 30px 20px; text-align: center; }
        .header h1 { color: #ffffff; margin: 0; font-size: 28px; }
        .content { padding: 30px; }
        .message { font-size: 16px; color: #2C3E50; line-height: 1.6; }
        .cta-button { display: inline-block; background-color: #6C63FF; color: #ffffff; text-decoration: none; padding: 12px 28px; border-radius: 8px; font-weight: 600; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⚠️ Email Verification Needed</h1>
        </div>
        <div class="content">
            <p class="message">Hi <strong>$name</strong>,</p>
            <p class="message">
                We noticed you haven't verified your email yet. Please verify your email address to unlock all IntelliPlan features.
            </p>
            <center>
                <a href="#" class="cta-button">Verify Email</a>
            </center>
            <p class="message" style="margin-top: 20px; font-size: 14px; color: #95A5A6;">
                Didn't receive the verification email? Check your spam folder or contact support.
            </p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  // ==================== TASK NOTIFICATIONS ====================
  
  /// Schedule a reminder notification for a task deadline
  /// This will show a notification even when the app is closed
  Future<void> scheduleTaskDeadlineNotification({
    required String taskId,
    required String taskTitle,
    required DateTime deadline,
    String? subject,
  }) async {
    try {
      // Calculate notification time (1 hour before deadline)
      final notificationTime = deadline.subtract(const Duration(hours: 1));
      
      // Only schedule if notification time is in the future
      if (notificationTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Task deadline is too soon, skipping notification');
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        'task_deadlines_channel',
        'Task Deadlines',
        channelDescription: 'Notifications for upcoming task deadlines',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final subjectText = subject != null ? ' ($subject)' : '';
      
      await _localNotifications.zonedSchedule(
        taskId.hashCode, // Use task ID hash as notification ID
        '⏰ Task Deadline Reminder',
        'Task "$taskTitle"$subjectText is due in 1 hour!',
        _convertToTZDateTime(notificationTime),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_deadline:$taskId',
      );
      
      debugPrint('✅ Scheduled deadline notification for task: $taskTitle at $notificationTime');
    } catch (e) {
      debugPrint('❌ Error scheduling task notification: $e');
    }
  }

  /// Schedule a reminder notification for task due today
  Future<void> scheduleTaskTodayReminder({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
    String? subject,
  }) async {
    try {
      // Schedule for 9 AM on the due date
      final notificationTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        9, // 9 AM
        0,
      );
      
      // Only schedule if notification time is in the future
      if (notificationTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Due date has passed, skipping notification');
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        'task_today_channel',
        'Tasks Due Today',
        channelDescription: 'Notifications for tasks due today',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final subjectText = subject != null ? ' ($subject)' : '';
      
      await _localNotifications.zonedSchedule(
        (taskId.hashCode + 1), // Different ID for today reminder
        '📅 Task Due Today',
        'Don\'t forget: "$taskTitle"$subjectText is due today!',
        _convertToTZDateTime(notificationTime),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_today:$taskId',
      );
      
      debugPrint('✅ Scheduled today reminder for task: $taskTitle at $notificationTime');
    } catch (e) {
      debugPrint('❌ Error scheduling today reminder: $e');
    }
  }

  /// Cancel all notifications for a specific task
  Future<void> cancelTaskNotifications(String taskId) async {
    try {
      // Cancel deadline notification
      await _localNotifications.cancel(taskId.hashCode);
      
      // Cancel today reminder
      await _localNotifications.cancel(taskId.hashCode + 1);
      
      debugPrint('✅ Cancelled notifications for task: $taskId');
    } catch (e) {
      debugPrint('❌ Error cancelling task notifications: $e');
    }
  }

  /// Helper to convert DateTime to TZDateTime for timezone-aware scheduling
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // Import timezone package at the top of the file
    // This is a simplified version - you may need to adjust based on your timezone setup
    final location = tz.getLocation('UTC');
    return tz.TZDateTime.from(dateTime, location);
  }

  /// Initialize notification channels for task notifications
  Future<void> initializeTaskNotificationChannels() async {
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Task deadlines channel
        const deadlineChannel = AndroidNotificationChannel(
          'task_deadlines_channel',
          'Task Deadlines',
          description: 'Notifications for upcoming task deadlines',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        
        // Tasks due today channel
        const todayChannel = AndroidNotificationChannel(
          'task_today_channel',
          'Tasks Due Today',
          description: 'Notifications for tasks due today',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        
        await androidImplementation.createNotificationChannel(deadlineChannel);
        await androidImplementation.createNotificationChannel(todayChannel);
        
        debugPrint('✅ Task notification channels created');
      }
    }
  }
}
