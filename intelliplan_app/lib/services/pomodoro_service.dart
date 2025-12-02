import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_session.dart';
import 'gamification_service.dart';
import 'notification_service.dart';

enum PomodoroState { idle, working, shortBreak, longBreak, paused }

class PomodoroService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationService? _gamificationService;
  final NotificationService _notificationService = NotificationService();
  
  String? _currentUserId;
  PomodoroState _state = PomodoroState.idle;
  Timer? _timer;
  
  // Pomodoro settings
  int workDuration = 25; // minutes
  int shortBreakDuration = 5; // minutes
  int longBreakDuration = 15; // minutes
  int pomodorosBeforeLongBreak = 4;
  
  // Current session
  int _currentPomodoros = 0;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  StudySession? _currentSession;
  String? _currentTopic;
  String? _currentCourseCode;

  PomodoroState get state => _state;
  int get currentPomodoros => _currentPomodoros;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  StudySession? get currentSession => _currentSession;
  
  double get progress {
    if (_totalSeconds == 0) return 0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }
  
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  bool get isActive => _state != PomodoroState.idle;

  PomodoroService(this._gamificationService);

  /// Initialize for user
  void initializeForUser(String userId) {
    _currentUserId = userId;
  }

  /// Start a work session
  void startWork({String? topic, String? courseCode}) {
    if (_state != PomodoroState.idle && _state != PomodoroState.paused) {
      _stopTimer();
    }
    
    _currentTopic = topic;
    _currentCourseCode = courseCode;
    _state = PomodoroState.working;
    _remainingSeconds = workDuration * 60;
    _totalSeconds = workDuration * 60;
    
    // Create new session
    _createSession();
    
    _startTimer();
    notifyListeners();
  }

  /// Start short break
  void startShortBreak() {
    _state = PomodoroState.shortBreak;
    _remainingSeconds = shortBreakDuration * 60;
    _totalSeconds = shortBreakDuration * 60;
    _startTimer();
    notifyListeners();
  }

  /// Start long break
  void startLongBreak() {
    _state = PomodoroState.longBreak;
    _remainingSeconds = longBreakDuration * 60;
    _totalSeconds = longBreakDuration * 60;
    _startTimer();
    notifyListeners();
  }

  /// Pause timer
  void pause() {
    if (_state == PomodoroState.idle) return;
    _timer?.cancel();
    _state = PomodoroState.paused;
    notifyListeners();
  }

  /// Resume timer
  void resume() {
    if (_state != PomodoroState.paused) return;
    _state = _currentPomodoros % pomodorosBeforeLongBreak == 0 && _currentPomodoros > 0
        ? PomodoroState.longBreak
        : (_remainingSeconds <= shortBreakDuration * 60 ? PomodoroState.shortBreak : PomodoroState.working);
    _startTimer();
    notifyListeners();
  }

  /// Stop/Reset timer
  void stop() {
    _stopTimer();
    _state = PomodoroState.idle;
    _remainingSeconds = 0;
    _totalSeconds = 0;
    
    // Complete session
    if (_currentSession != null) {
      _completeSession();
    }
    
    notifyListeners();
  }

  /// Skip current phase
  Future<void> skip() async {
    _timer?.cancel();
    
    // If we're skipping a work session, still count it and save analytics
    if (_state == PomodoroState.working) {
      _currentPomodoros++;
      
      // Update session with current pomodoros
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          pomodoroCount: _currentPomodoros,
        );
        await _saveSession();
      }
      
      // Award reduced XP for skipped session
      if (_gamificationService != null) {
        await _gamificationService!.awardXP(
          25, // Reduced XP for skipped session
          source: 'Pomodoro ${_currentPomodoros} (Skipped)',
        );
      }
      
      // Track as completed for analytics
      _gamificationService?.trackPomodoroSession();
      _gamificationService?.trackConsecutivePomodoros(_currentPomodoros);
      _gamificationService?.trackDailyPomodoroMinutes(workDuration);
      
      debugPrint('⏭️ Pomodoro session skipped, analytics updated');
    }
    
    await _onTimerComplete();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    
    if (_state == PomodoroState.working) {
      // Work session completed
      _currentPomodoros++;
      
      // Check if Pomodoro alarms are enabled
      final prefs = await SharedPreferences.getInstance();
      final pomodoroAlarmEnabled = prefs.getBool('pomodoro_alarm') ?? true;
      
      // Show notification only if enabled
      if (pomodoroAlarmEnabled) {
        _notificationService.showPomodoroAlarm(
          title: 'Pomodoro Complete! 🎉',
          body: 'Great work! Time for a ${_currentPomodoros % pomodorosBeforeLongBreak == 0 ? 'long' : 'short'} break.',
        );
      }
      
      // Award XP for completed pomodoro
      _awardPomodoroXP();
      
      // Update quest progress
      _gamificationService?.updateQuestProgress('pomodoro');
      
      // Track Pomodoro achievement
      _gamificationService?.trackPomodoroSession();
      _gamificationService?.trackConsecutivePomodoros(_currentPomodoros);
      _gamificationService?.trackDailyPomodoroMinutes(workDuration);
      
      // Update session
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          pomodoroCount: _currentPomodoros,
        );
        _saveSession();
      }
      
      // Decide next phase
      if (_currentPomodoros % pomodorosBeforeLongBreak == 0) {
        startLongBreak();
      } else {
        startShortBreak();
      }
    } else {
      // Break completed, back to idle
      _state = PomodoroState.idle;
      _remainingSeconds = 0;
      
      // Check if Pomodoro alarms are enabled
      final prefs = await SharedPreferences.getInstance();
      final pomodoroAlarmEnabled = prefs.getBool('pomodoro_alarm') ?? true;
      
      // Show notification only if enabled
      if (pomodoroAlarmEnabled) {
        _notificationService.showPomodoroAlarm(
          title: 'Break Complete! ⏰',
          body: 'Ready to start your next Pomodoro session?',
        );
      }
      
      notifyListeners();
    }
  }

  /// Award XP for completed pomodoro
  Future<void> _awardPomodoroXP() async {
    if (_gamificationService == null) return;
    
    // Base XP: 100 per completed pomodoro
    int xpAmount = 100;
    
    // Bonus XP for consecutive pomodoros
    if (_currentPomodoros > 1) {
      xpAmount += (_currentPomodoros - 1) * 10; // +10 XP per consecutive session
    }
    
    await _gamificationService!.awardXP(
      xpAmount,
      source: 'Pomodoro ${_currentPomodoros}${_currentTopic != null ? " ($_currentTopic)" : ""}',
    );
    
    debugPrint('🍅 Pomodoro completed! Awarded $xpAmount XP');
  }

  /// Create new study session
  void _createSession() {
    if (_currentUserId == null) return;
    
    _currentSession = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUserId!,
      technique: StudyTechnique.pomodoro,
      status: SessionStatus.active,
      startTime: DateTime.now(),
      durationMinutes: 0,
      courseCode: _currentCourseCode,
      topic: _currentTopic,
      pomodoroCount: 0,
      breakCount: 0,
      createdAt: DateTime.now(),
    );
  }

  /// Save session to Firestore
  Future<void> _saveSession() async {
    if (_currentUserId == null || _currentSession == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('study_sessions')
          .doc(_currentSession!.id)
          .set(_currentSession!.toJson());
    } catch (e) {
      debugPrint('Error saving pomodoro session: $e');
    }
  }

  /// Complete current session
  Future<void> _completeSession() async {
    if (_currentSession == null) return;
    
    final completedSession = _currentSession!.copyWith(
      status: SessionStatus.completed,
      endTime: DateTime.now(),
      durationMinutes: _currentPomodoros * workDuration,
      pomodoroCount: _currentPomodoros,
    );
    
    try {
      final sessionData = completedSession.toJson();
      debugPrint('💾 Saving completed pomodoro session: $sessionData');
      
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('study_sessions')
          .doc(completedSession.id)
          .set(sessionData, SetOptions(merge: true));
      
      debugPrint('✅ Pomodoro session saved successfully with ${_currentPomodoros} pomodoros');
      
      // Update gamification streak and session count
      if (_gamificationService != null && _currentPomodoros > 0) {
        await _gamificationService!.updateStreak();
        await _gamificationService!.incrementSessionCount();
        
        // Award study points based on pomodoros completed
        final studyPoints = _currentPomodoros * 2; // 2 SP per pomodoro
        await _gamificationService!.awardStudyPoints(studyPoints);
      }
      
      _currentSession = null;
      _currentPomodoros = 0;
      _currentTopic = null;
      _currentCourseCode = null;
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error completing pomodoro session: $e');
    }
  }

  /// Get session history
  Future<List<StudySession>> getSessionHistory({int limit = 20}) async {
    if (_currentUserId == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('study_sessions')
          .where('technique', isEqualTo: 'pomodoro')
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => StudySession.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading session history: $e');
      return [];
    }
  }

  /// Get today's pomodoro count
  Future<int> getTodayPomodoroCount() async {
    if (_currentUserId == null) return 0;
    
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('study_sessions')
          .where('technique', isEqualTo: 'pomodoro')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
      
      int totalPomodoros = 0;
      for (var doc in snapshot.docs) {
        final session = StudySession.fromJson(doc.data());
        totalPomodoros += session.pomodoroCount;
      }
      
      return totalPomodoros;
    } catch (e) {
      debugPrint('Error getting today pomodoro count: $e');
      return 0;
    }
  }

  /// Update settings
  void updateSettings({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? pomodorosBeforeLongBreak,
  }) {
    if (workDuration != null) this.workDuration = workDuration;
    if (shortBreakDuration != null) this.shortBreakDuration = shortBreakDuration;
    if (longBreakDuration != null) this.longBreakDuration = longBreakDuration;
    if (pomodorosBeforeLongBreak != null) {
      this.pomodorosBeforeLongBreak = pomodorosBeforeLongBreak;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
