import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session.dart';
import '../models/assignment.dart';
import '../models/study_task.dart';
import '../models/class_schedule.dart';

enum RecommendationType { optimal, avoid, suggestion, urgent, deadline }

class OptimalTimeSlot {
  final DateTime date;
  final String timeSlot; // "09:00-10:00"
  final double productivityScore;
  final bool isFree; // No conflicts with classes/tasks
  final String reason;
  final int durationMinutes;

  OptimalTimeSlot({
    required this.date,
    required this.timeSlot,
    required this.productivityScore,
    required this.isFree,
    required this.reason,
    required this.durationMinutes,
  });
}

class DeadlinePressure {
  final Assignment assignment;
  final int daysRemaining;
  final int hoursNeeded;
  final String urgencyLevel; // low, medium, high, critical
  final double riskScore; // 0-1 probability of missing deadline
  
  DeadlinePressure({
    required this.assignment,
    required this.daysRemaining,
    required this.hoursNeeded,
    required this.urgencyLevel,
    required this.riskScore,
  });
}

class ProductivityPattern {
  final String timeOfDay; // morning, afternoon, evening, night
  final double avgProductivity;
  final int sessionCount;
  final int totalMinutes;
  
  // Add averageScore getter for compatibility
  double get averageScore => avgProductivity;

  ProductivityPattern({
    required this.timeOfDay,
    required this.avgProductivity,
    required this.sessionCount,
    required this.totalMinutes,
  });
}

class StudyRecommendation {
  final String title;
  final String description;
  final String timeSlot;
  final int durationMinutes;
  final double confidence;
  final String reason;
  final RecommendationType type;
  final DateTime? suggestedDate;
  final String? assignmentId; // Link to specific assignment
  final List<String>? specificTimeSlots; // ["09:00-10:00", "14:00-15:00"]

  StudyRecommendation({
    required this.title,
    required this.description,
    required this.timeSlot,
    required this.durationMinutes,
    required this.confidence,
    required this.reason,
    this.type = RecommendationType.suggestion,
    this.suggestedDate,
    this.assignmentId,
    this.specificTimeSlots,
  });
}

/// Prescriptive Analytics Service
/// Analyzes user study patterns and recommends optimal study times
class AnalyticsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _currentUserId;
  List<StudySession> _recentSessions = [];
  Map<String, ProductivityPattern> _productivityPatterns = {};
  List<StudyRecommendation> _recommendations = [];
  List<Assignment> _upcomingAssignments = [];
  List<StudyTask> _scheduledTasks = [];
  List<ClassSchedule> _classSchedule = [];
  List<OptimalTimeSlot> _optimalTimeSlots = [];
  List<DeadlinePressure> _deadlinePressures = [];
  
  // Stream subscriptions for real-time updates
  var _sessionSubscription;
  var _assignmentSubscription;
  var _taskSubscription;
  
  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _assignmentSubscription?.cancel();
    _taskSubscription?.cancel();
    super.dispose();
  }

  List<StudySession> get recentSessions => _recentSessions;
  Map<String, ProductivityPattern> get productivityPatterns => _productivityPatterns;
  List<StudyRecommendation> get recommendations => _recommendations;
  List<OptimalTimeSlot> get optimalTimeSlots => _optimalTimeSlots;
  List<DeadlinePressure> get deadlinePressures => _deadlinePressures;
  
  // Additional getters for UI
  int get totalSessions => _recentSessions.length;
  int get todaySessions => _recentSessions.where((s) => 
    s.startTime.year == DateTime.now().year &&
    s.startTime.month == DateTime.now().month &&
    s.startTime.day == DateTime.now().day
  ).length;
  int get totalMinutes {
    try {
      if (_recentSessions.isEmpty) return 0;
      final total = _recentSessions.fold<int>(0, (sum, s) {
        return sum + s.durationMinutes;
      });
      debugPrint('📊 Total minutes calculated: $total from ${_recentSessions.length} sessions');
      return total;
    } catch (e) {
      debugPrint('❌ Error calculating totalMinutes: $e');
      return 0;
    }
  }
  
  Map<String, int> get weeklyProductivityData {
    final now = DateTime.now();
    final data = <String, int>{};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    try {
      // Initialize all days with 0
      for (var day in days) {
        data[day] = 0;
      }
      
      // Get the last 7 days including today
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dayIndex = day.weekday - 1; // Monday = 0, Sunday = 6
        if (dayIndex < 0 || dayIndex >= days.length) continue;
        
        final dayName = days[dayIndex];
        final sessions = _recentSessions.where((s) {
          try {
            return s.startTime.year == day.year &&
                   s.startTime.month == day.month &&
                   s.startTime.day == day.day;
          } catch (e) {
            return false;
          }
        });
        
        int minutes = 0;
        for (var s in sessions) {
          try {
            // Use durationMinutes directly (already calculated in model)
            minutes += s.durationMinutes;
          } catch (e) {
            debugPrint('Error adding session duration: $e');
          }
        }
        
        data[dayName] = (data[dayName] ?? 0) + minutes;
      }
    } catch (e) {
      debugPrint('Error calculating weekly data: $e');
      // Return zeros if error
      for (var day in days) {
        data[day] = 0;
      }
    }
    
    return data;
  }

  /// Initialize for user
  Future<void> initializeForUser(String userId) async {
    debugPrint('📊 Analytics: Initializing for user: $userId');
    _currentUserId = userId;
    
    try {
      await Future.wait([
        analyzeProductivityPatterns(),
        _loadScheduleData(),
        _loadUpcomingDeadlines(),
      ]);
      await generateRecommendations();
      await generateOptimalTimeSlots();
      await analyzeDeadlinePressure();
      
      debugPrint('📊 Analytics: Initialization complete');
      debugPrint('📊 Analytics: Total sessions: $totalSessions');
      debugPrint('📊 Analytics: Recommendations: ${_recommendations.length}');
      debugPrint('📊 Analytics: Optimal slots: ${_optimalTimeSlots.length}');
    } catch (e) {
      debugPrint('❌ Analytics: Initialization error: $e');
    }
  }

  /// Load user's schedule data for conflict detection
  Future<void> _loadScheduleData() async {
    if (_currentUserId == null) return;
    
    try {
      // Load classes
      final classesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('classes')
          .get();
      
      _classSchedule = classesSnapshot.docs
          .map((doc) => ClassSchedule.fromJson(doc.data()))
          .toList();
      
      // Load scheduled tasks for next 7 days
      final today = DateTime.now();
      final nextWeek = today.add(const Duration(days: 7));
      
      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tasks')
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(nextWeek))
          .get();
      
      _scheduledTasks = tasksSnapshot.docs
          .map((doc) => StudyTask.fromJson(doc.data()))
          .toList();
      
    } catch (e) {
      debugPrint('Error loading schedule data: $e');
    }
  }

  /// Load upcoming assignments for deadline analysis
  Future<void> _loadUpcomingDeadlines() async {
    if (_currentUserId == null) return;
    
    try {
      final today = DateTime.now();
      final twoWeeksLater = today.add(const Duration(days: 14));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('assignments')
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(twoWeeksLater))
          .where('status', whereIn: ['pending', 'inProgress'])
          .orderBy('dueDate')
          .get();
      
      _upcomingAssignments = snapshot.docs
          .map((doc) => Assignment.fromJson(doc.data()))
          .toList();
      
    } catch (e) {
      debugPrint('Error loading upcoming deadlines: $e');
    }
  }

  /// Analyze productivity patterns from past study sessions
  Future<void> analyzeProductivityPatterns() async {
    if (_currentUserId == null) {
      debugPrint('⚠️ Analytics: No user ID set');
      return;
    }
    
    try {
      debugPrint('📊 Analytics: Setting up real-time analytics for user: $_currentUserId');
      
      // Cancel existing subscription if any
      await _sessionSubscription?.cancel();
      
      // Get last 30 days of sessions
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Set up real-time listener for study sessions
      debugPrint('📡 Setting up analytics listeners for user: $_currentUserId');
      _sessionSubscription = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('study_sessions')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .snapshots()
          .listen(
        (snapshot) {
          debugPrint('🔄 Study sessions update: ${snapshot.docs.length}');
          debugPrint('📊 Processing all analytics data...');
          
          // Parse sessions with error handling
          _recentSessions = [];
          for (var doc in snapshot.docs) {
            try {
              final data = {...doc.data(), 'id': doc.id}; // Add document ID to data
              
              debugPrint('📄 Raw session data: technique=${data['technique']}, topic=${data['topic']}');
              
              // Parse the session
              final session = StudySession.fromJson(data);
              
              debugPrint('🔍 Parsed session: technique=${session.technique} (${session.technique.name}), topic=${session.topic}');
              
              // Include sessions with:
              // 1. Valid duration > 0
              // 2. Has pomodoro count (even if duration is 0)
              // 3. Is active recall or spaced repetition (may not have traditional duration)
              final techniqueName = session.technique.name.toLowerCase();
              final isValidSession = session.durationMinutes > 0 || 
                                     session.pomodoroCount > 0 ||
                                     techniqueName.contains('recall') ||
                                     techniqueName.contains('repetition');
              
              debugPrint('✅ Session valid: $isValidSession (duration=${session.durationMinutes}, pomodoro=${session.pomodoroCount}, technique=$techniqueName)');
              
              if (isValidSession) {
                _recentSessions.add(session);
                if (session.technique == StudyTechnique.spacedRepetition) {
                  debugPrint('🎯 ADDED SPACED REPETITION SESSION TO ANALYTICS!');
                }
              }
            } catch (e) {
              debugPrint('  ⚠️ Error parsing session: $e');
            }
          }
          
          debugPrint('✅ Processed: ${_recentSessions.length} sessions, $totalMinutes minutes, today: $todaySessions');
          
          // Analyze by time of day
          _analyzeByTimeOfDay();
          
          // Notify listeners to update UI
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ Analytics stream error: $error');
        },
      );
      
      debugPrint('📊 Analytics: Real-time listener established');
    } catch (e, stackTrace) {
      debugPrint('❌ Analytics: Error setting up analytics: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't throw - just log the error and continue
      _recentSessions = [];
      _productivityPatterns.clear();
      notifyListeners();
    }
  }

  void _analyzeByTimeOfDay() {
    final patterns = <String, List<StudySession>>{
      'morning': [], // 6-12
      'afternoon': [], // 12-18
      'evening': [], // 18-22
      'night': [], // 22-6
    };
    
    for (var session in _recentSessions) {
      final hour = session.startTime.hour;
      String timeSlot;
      
      if (hour >= 6 && hour < 12) {
        timeSlot = 'morning';
      } else if (hour >= 12 && hour < 18) {
        timeSlot = 'afternoon';
      } else if (hour >= 18 && hour < 22) {
        timeSlot = 'evening';
      } else {
        timeSlot = 'night';
      }
      
      patterns[timeSlot]!.add(session);
    }
    
    // Calculate productivity for each time slot
    _productivityPatterns.clear();
    patterns.forEach((timeSlot, sessions) {
      if (sessions.isEmpty) return;
      
      final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
      
      // Calculate average productivity with fallback
      final sessionsWithScore = sessions.where((s) => s.productivityScore != null && s.productivityScore! > 0).toList();
      
      double avgProductivity;
      if (sessionsWithScore.isNotEmpty) {
        final totalScore = sessionsWithScore.fold<double>(0, (sum, s) => sum + s.productivityScore!);
        avgProductivity = totalScore / sessionsWithScore.length;
      } else {
        // Use default productivity based on time of day
        avgProductivity = _getDefaultProductivity(timeSlot);
      }
      
      // Ensure avgProductivity is valid
      if (avgProductivity.isNaN || avgProductivity.isInfinite) {
        avgProductivity = 70.0;
      }
      
      _productivityPatterns[timeSlot] = ProductivityPattern(
        timeOfDay: timeSlot,
        avgProductivity: avgProductivity.clamp(0.0, 100.0),
        sessionCount: sessions.length,
        totalMinutes: totalMinutes,
      );
    });
    
    debugPrint('📊 Analytics: Productivity patterns created: ${_productivityPatterns.length}');
  }
  
  double _getDefaultProductivity(String timeSlot) {
    // Research-based default productivity scores
    switch (timeSlot) {
      case 'morning':
        return 80.0; // Morning typically has higher focus
      case 'afternoon':
        return 70.0; // Afternoon dip
      case 'evening':
        return 65.0; // Evening recovery
      case 'night':
        return 50.0; // Night less productive
      default:
        return 70.0;
    }
  }

  /// Generate study time recommendations based on patterns
  Future<void> generateRecommendations() async {
    _recommendations.clear();
    
    if (_productivityPatterns.isEmpty) {
      _generateDefaultRecommendations();
      notifyListeners();
      return;
    }
    
    // Sort time slots by productivity
    final sortedSlots = _productivityPatterns.entries.toList()
      ..sort((a, b) => b.value.avgProductivity.compareTo(a.value.avgProductivity));
    
    // Recommend top 3 time slots
    for (var i = 0; i < sortedSlots.length && i < 3; i++) {
      final slot = sortedSlots[i];
      final pattern = slot.value;
      
      _recommendations.add(StudyRecommendation(
        title: 'Optimal ${_capitalize(pattern.timeOfDay)} Study',
        description: 'Based on your past ${pattern.sessionCount} sessions during this time',
        timeSlot: pattern.timeOfDay,
        durationMinutes: (pattern.totalMinutes / pattern.sessionCount).round(),
        confidence: _calculateConfidence(pattern),
        reason: 'Your productivity is ${pattern.avgProductivity.toStringAsFixed(1)}% during ${pattern.timeOfDay}',
        type: RecommendationType.optimal,
      ));
    }
    
    // Recommend study technique
    final techniqueRecommendation = await _recommendStudyTechnique();
    if (techniqueRecommendation != null) {
      _recommendations.add(techniqueRecommendation);
    }
    
    notifyListeners();
  }

  void _generateDefaultRecommendations() {
    _recommendations = [
      StudyRecommendation(
        title: 'Start with Morning Sessions',
        description: 'Research shows morning study can improve retention',
        timeSlot: 'morning',
        durationMinutes: 45,
        confidence: 0.6,
        reason: 'Based on general study best practices',
        type: RecommendationType.suggestion,
      ),
      StudyRecommendation(
        title: 'Try Pomodoro Technique',
        description: '25-minute focused sessions with 5-minute breaks',
        timeSlot: 'any',
        durationMinutes: 25,
        confidence: 0.7,
        reason: 'Proven technique for maintaining focus',
        type: RecommendationType.suggestion,
      ),
    ];
  }

  double _calculateConfidence(ProductivityPattern pattern) {
    // Confidence based on session count and productivity
    final sessionScore = (pattern.sessionCount / 20).clamp(0.0, 1.0);
    final productivityScore = pattern.avgProductivity / 100;
    return (sessionScore * 0.4 + productivityScore * 0.6).clamp(0.0, 1.0);
  }

  String _capitalize(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Recommend best study technique based on user behavior
  Future<StudyRecommendation?> _recommendStudyTechnique() async {
    if (_recentSessions.length < 3) {
      // New user - recommend Pomodoro as starting technique
      return StudyRecommendation(
        title: 'Try Pomodoro Technique',
        description: '25-minute focused sessions with 5-minute breaks',
        timeSlot: 'any',
        durationMinutes: 25,
        confidence: 0.75,
        reason: 'Perfect for building focused study habits',
        type: RecommendationType.suggestion,
      );
    }

    // Analyze behavior for each technique
    final pomodoroSessions = _recentSessions
        .where((s) => s.technique == StudyTechnique.pomodoro)
        .toList();
    
    final spacedRepetitionSessions = _recentSessions
        .where((s) => s.technique == StudyTechnique.spacedRepetition)
        .toList();
    
    final activeRecallSessions = _recentSessions
        .where((s) => s.technique == StudyTechnique.activeRecall)
        .toList();
    
    final normalSessions = _recentSessions
        .where((s) => s.technique == StudyTechnique.normal)
        .toList();

    // Calculate metrics for each technique
    final pomodoroMetrics = _analyzeTechniqueMetrics(pomodoroSessions);
    final spacedRepMetrics = _analyzeTechniqueMetrics(spacedRepetitionSessions);
    final activeRecallMetrics = _analyzeTechniqueMetrics(activeRecallSessions);
    final normalMetrics = _analyzeTechniqueMetrics(normalSessions);

    // Analyze user's study behavior patterns
    final behaviorPattern = _analyzeBehaviorPattern(_recentSessions);

    // Recommend based on behavior and performance
    
    // Check if user excels with a technique
    if (pomodoroMetrics['avgProductivity'] > 75 && pomodoroSessions.length >= 5) {
      return StudyRecommendation(
        title: 'Continue with Pomodoro',
        description: 'Your productivity is excellent with Pomodoro technique',
        timeSlot: 'any',
        durationMinutes: 25,
        confidence: 0.90,
        reason: 'Your ${pomodoroSessions.length} Pomodoro sessions average ${pomodoroMetrics['avgProductivity'].toStringAsFixed(1)}% productivity',
        type: RecommendationType.optimal,
      );
    }

    if (spacedRepMetrics['avgProductivity'] > 75 && spacedRepetitionSessions.length >= 5) {
      return StudyRecommendation(
        title: 'Continue with Spaced Repetition',
        description: 'Your memory retention is outstanding',
        timeSlot: 'any',
        durationMinutes: 20,
        confidence: 0.90,
        reason: 'Your ${spacedRepetitionSessions.length} review sessions show excellent results',
        type: RecommendationType.optimal,
      );
    }

    if (activeRecallMetrics['avgProductivity'] > 75 && activeRecallSessions.length >= 5) {
      return StudyRecommendation(
        title: 'Continue with Active Recall',
        description: 'Your active learning is highly effective',
        timeSlot: 'any',
        durationMinutes: 30,
        confidence: 0.90,
        reason: 'Your ${activeRecallSessions.length} active recall sessions are very productive',
        type: RecommendationType.optimal,
      );
    }

    // Recommend Pomodoro based on behavior patterns
    if (_shouldRecommendPomodoro(behaviorPattern, normalMetrics)) {
      return StudyRecommendation(
        title: 'Switch to Pomodoro Technique',
        description: 'Structured intervals will boost your focus and productivity',
        timeSlot: 'any',
        durationMinutes: 25,
        confidence: _calculatePomodoroConfidence(behaviorPattern),
        reason: _getPomodoroRecommendationReason(behaviorPattern),
        type: RecommendationType.optimal,
      );
    }

    // Recommend Spaced Repetition for review-heavy subjects
    if (behaviorPattern['hasReviewSessions'] && spacedRepetitionSessions.length < 3) {
      return StudyRecommendation(
        title: 'Try Spaced Repetition',
        description: 'Optimize your review sessions for better long-term retention',
        timeSlot: 'any',
        durationMinutes: 20,
        confidence: 0.80,
        reason: 'Your study pattern shows frequent reviews - spaced repetition will make them more effective',
        type: RecommendationType.suggestion,
      );
    }

    // Recommend Active Recall for concept mastery
    if (behaviorPattern['longStudySessions'] && activeRecallSessions.length < 3) {
      return StudyRecommendation(
        title: 'Try Active Recall',
        description: 'Test yourself to reinforce learning and identify weak areas',
        timeSlot: 'any',
        durationMinutes: 30,
        confidence: 0.75,
        reason: 'Your long study sessions will benefit from active recall practice',
        type: RecommendationType.suggestion,
      );
    }

    // Default recommendation based on general patterns
    if (normalSessions.length > pomodoroSessions.length && normalMetrics['avgProductivity'] < 60) {
      return StudyRecommendation(
        title: 'Try Pomodoro Technique',
        description: 'Structured study intervals can improve focus and prevent burnout',
        timeSlot: 'any',
        durationMinutes: 25,
        confidence: 0.70,
        reason: 'Your unstructured sessions show room for improvement',
        type: RecommendationType.suggestion,
      );
    }

    return null;
  }

  /// Analyze metrics for a specific technique
  Map<String, dynamic> _analyzeTechniqueMetrics(List<StudySession> sessions) {
    if (sessions.isEmpty) {
      return {
        'avgProductivity': 0.0,
        'completionRate': 0.0,
        'avgDuration': 0,
        'frequency': 0,
      };
    }

    final sessionsWithScore = sessions.where((s) => s.productivityScore != null).toList();
    final avgProductivity = sessionsWithScore.isEmpty 
        ? 0.0 
        : sessionsWithScore.fold<double>(0, (sum, s) => sum + s.productivityScore!) / sessionsWithScore.length;

    final completedSessions = sessions.where((s) => s.status == SessionStatus.completed).length;
    final completionRate = completedSessions / sessions.length;

    final avgDuration = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes) ~/ sessions.length;

    return {
      'avgProductivity': avgProductivity,
      'completionRate': completionRate,
      'avgDuration': avgDuration,
      'frequency': sessions.length,
    };
  }

  /// Analyze user's general behavior patterns
  Map<String, dynamic> _analyzeBehaviorPattern(List<StudySession> sessions) {
    if (sessions.isEmpty) return {};

    // Calculate average session duration
    final avgDuration = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes) / sessions.length;
    
    // Check for long sessions (>45 min)
    final longSessions = sessions.where((s) => s.durationMinutes > 45).length;
    final longSessionRate = longSessions / sessions.length;

    // Check for incomplete sessions (suggests lack of focus)
    final incompleteSessions = sessions.where((s) => 
      s.status == SessionStatus.cancelled || 
      (s.status == SessionStatus.completed && s.durationMinutes < 10)
    ).length;
    final incompleteRate = incompleteSessions / sessions.length;

    // Check session frequency (sessions per day)
    final daySpan = DateTime.now().difference(sessions.last.startTime).inDays + 1;
    final sessionsPerDay = sessions.length / daySpan;

    // Check for review pattern (multiple short sessions)
    final shortSessions = sessions.where((s) => s.durationMinutes <= 20).length;
    final hasReviewSessions = (shortSessions / sessions.length) > 0.4;

    // Check for consistency (studying same time of day)
    final timeDistribution = <String, int>{};
    for (var session in sessions) {
      final timeSlot = _getTimeSlot(session.startTime);
      timeDistribution[timeSlot] = (timeDistribution[timeSlot] ?? 0) + 1;
    }
    final maxTimeSlot = timeDistribution.entries.reduce((a, b) => a.value > b.value ? a : b);
    final consistencyRate = maxTimeSlot.value / sessions.length;

    return {
      'avgDuration': avgDuration,
      'longStudySessions': longSessionRate > 0.3, // 30%+ are long
      'hasIncompleteRate': incompleteRate > 0.2, // 20%+ incomplete
      'sessionsPerDay': sessionsPerDay,
      'hasReviewSessions': hasReviewSessions,
      'isConsistent': consistencyRate > 0.5, // 50%+ same time
      'preferredTimeSlot': maxTimeSlot.key,
    };
  }

  /// Helper method to get time slot from DateTime
  String _getTimeSlot(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 6 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 18) {
      return 'afternoon';
    } else if (hour >= 18 && hour < 22) {
      return 'evening';
    } else {
      return 'night';
    }
  }

  /// Determine if Pomodoro should be recommended
  bool _shouldRecommendPomodoro(Map<String, dynamic> pattern, Map<String, dynamic> normalMetrics) {
    if (pattern.isEmpty) return false;

    // Recommend Pomodoro if:
    // 1. User has long unfocused sessions
    final hasLongSessions = pattern['longStudySessions'] == true;
    final hasIncompleteRate = pattern['hasIncompleteRate'] == true;
    
    // 2. Low productivity in normal sessions
    final lowProductivity = normalMetrics['avgProductivity'] < 60;
    
    // 3. Inconsistent study habits
    final inconsistent = pattern['isConsistent'] == false;

    // Need at least 2 of these indicators
    int indicators = 0;
    if (hasLongSessions) indicators++;
    if (hasIncompleteRate) indicators++;
    if (lowProductivity) indicators++;
    if (inconsistent) indicators++;

    return indicators >= 2;
  }

  /// Calculate confidence for Pomodoro recommendation
  double _calculatePomodoroConfidence(Map<String, dynamic> pattern) {
    double confidence = 0.60; // Base confidence

    if (pattern['hasIncompleteRate'] == true) confidence += 0.10;
    if (pattern['longStudySessions'] == true) confidence += 0.10;
    if (pattern['isConsistent'] == false) confidence += 0.05;
    if (pattern['sessionsPerDay'] >= 2) confidence += 0.10;

    return confidence.clamp(0.0, 0.95);
  }

  /// Generate reason for Pomodoro recommendation
  String _getPomodoroRecommendationReason(Map<String, dynamic> pattern) {
    final reasons = <String>[];

    if (pattern['hasIncompleteRate'] == true) {
      reasons.add('you have difficulty completing long sessions');
    }
    if (pattern['longStudySessions'] == true) {
      reasons.add('your sessions are often longer than 45 minutes');
    }
    if (pattern['isConsistent'] == false) {
      reasons.add('more structure will help build consistent habits');
    }
    if (pattern['avgDuration'] > 60) {
      reasons.add('breaking long sessions into intervals improves focus');
    }

    if (reasons.isEmpty) {
      return 'Pomodoro technique is proven to improve focus and productivity';
    }

    return 'Based on your behavior: ${reasons.join(', ')}';
  }

  /// Get productivity statistics
  Future<Map<String, dynamic>> getProductivityStats() async {
    if (_currentUserId == null) return {};
    
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(today.year, today.month, 1);
    
    try {
      // Today's sessions
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final todaySessions = await _getSessionsBetween(todayStart, todayEnd);
      final weekSessions = await _getSessionsBetween(startOfWeek, today);
      final monthSessions = await _getSessionsBetween(startOfMonth, today);
      
      return {
        'todayMinutes': _getTotalMinutes(todaySessions),
        'weekMinutes': _getTotalMinutes(weekSessions),
        'monthMinutes': _getTotalMinutes(monthSessions),
        'todaySessions': todaySessions.length,
        'weekSessions': weekSessions.length,
        'monthSessions': monthSessions.length,
        'avgSessionDuration': _getAvgDuration(monthSessions),
        'mostProductiveTime': _getMostProductiveTime(),
      };
    } catch (e) {
      debugPrint('Error getting productivity stats: $e');
      return {};
    }
  }

  Future<List<StudySession>> _getSessionsBetween(DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('study_sessions')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThan: Timestamp.fromDate(end))
        .where('status', isEqualTo: 'completed')
        .get();
    
    return snapshot.docs.map((doc) => StudySession.fromJson(doc.data())).toList();
  }

  int _getTotalMinutes(List<StudySession> sessions) {
    return sessions.fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int _getAvgDuration(List<StudySession> sessions) {
    if (sessions.isEmpty) return 0;
    return _getTotalMinutes(sessions) ~/ sessions.length;
  }

  String _getMostProductiveTime() {
    if (_productivityPatterns.isEmpty) return 'Not enough data';
    
    final best = _productivityPatterns.entries
        .reduce((a, b) => a.value.avgProductivity > b.value.avgProductivity ? a : b);
    
    return _capitalize(best.key);
  }

  /// Get weekly productivity chart data
  Future<List<Map<String, dynamic>>> getWeeklyProductivityData() async {
    if (_currentUserId == null) return [];
    
    final today = DateTime.now();
    final weekData = <Map<String, dynamic>>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final sessions = await _getSessionsBetween(dayStart, dayEnd);
      final totalMinutes = _getTotalMinutes(sessions);
      
      weekData.add({
        'date': date,
        'day': _getDayName(date),
        'minutes': totalMinutes,
        'sessions': sessions.length,
      });
    }
    
    return weekData;
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  /// Track completion of recommendation
  Future<void> trackRecommendationCompleted(StudyRecommendation recommendation) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('recommendation_history')
          .add({
        'title': recommendation.title,
        'timeSlot': recommendation.timeSlot,
        'completedAt': Timestamp.now(),
        'confidence': recommendation.confidence,
      });
    } catch (e) {
      debugPrint('Error tracking recommendation: $e');
    }
  }

  // ==================== PRESCRIPTIVE ANALYTICS ====================

  /// Generate optimal time slots for studying based on productivity patterns and schedule
  Future<void> generateOptimalTimeSlots() async {
    _optimalTimeSlots.clear();
    
    if (_productivityPatterns.isEmpty) {
      notifyListeners();
      return;
    }

    final today = DateTime.now();
    
    // Generate time slots for next 7 days
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = today.add(Duration(days: dayOffset));
      final dayName = _getDayOfWeekName(targetDate);
      
      // Get classes for this day
      final classesOnDay = _classSchedule.where((c) => c.dayOfWeek == dayName).toList();
      
      // Get tasks scheduled for this day
      final tasksOnDay = _scheduledTasks.where((t) {
        if (t.scheduledDate == null) return false;
        return t.scheduledDate!.year == targetDate.year &&
               t.scheduledDate!.month == targetDate.month &&
               t.scheduledDate!.day == targetDate.day;
      }).toList();
      
      // Generate time slots throughout the day
      final slots = _generateDayTimeSlots(targetDate, classesOnDay, tasksOnDay);
      _optimalTimeSlots.addAll(slots);
    }
    
    // Sort by productivity score
    _optimalTimeSlots.sort((a, b) => b.productivityScore.compareTo(a.productivityScore));
    
    notifyListeners();
  }

  /// Generate time slots for a specific day
  List<OptimalTimeSlot> _generateDayTimeSlots(
    DateTime date,
    List<ClassSchedule> classes,
    List<StudyTask> tasks,
  ) {
    final slots = <OptimalTimeSlot>[];
    
    // Define study time slots (hourly from 6 AM to 10 PM)
    for (int hour = 6; hour < 22; hour++) {
      final slotStart = DateTime(date.year, date.month, date.day, hour, 0);
      final slotEnd = slotStart.add(const Duration(hours: 1));
      
      // Check if slot is free (no classes or tasks)
      final isFree = _isTimeSlotFree(slotStart, slotEnd, classes, tasks);
      
      if (isFree) {
        // Calculate productivity score for this time
        final timeOfDay = _getTimeSlot(slotStart);
        final timeProductivity = _productivityPatterns[timeOfDay]?.avgProductivity ?? 70.0;
        
        // Boost score for preferred times
        double scoreMultiplier = 1.0;
        if (hour >= 8 && hour < 12) scoreMultiplier = 1.2; // Morning boost
        if (hour >= 14 && hour < 17) scoreMultiplier = 1.1; // Afternoon focus
        
        final finalScore = (timeProductivity * scoreMultiplier).clamp(0.0, 100.0);
        
        slots.add(OptimalTimeSlot(
          date: slotStart,
          timeSlot: '${_formatHour(hour)}:00-${_formatHour(hour + 1)}:00',
          productivityScore: finalScore,
          isFree: true,
          reason: _getSlotReason(timeOfDay, finalScore),
          durationMinutes: 60,
        ));
      }
    }
    
    return slots;
  }

  /// Check if a time slot is free from conflicts
  bool _isTimeSlotFree(
    DateTime start,
    DateTime end,
    List<ClassSchedule> classes,
    List<StudyTask> tasks,
  ) {
    // Check class conflicts
    for (var classItem in classes) {
      final classStart = _parseTimeToDateTime(start, classItem.startTime);
      final classEnd = _parseTimeToDateTime(start, classItem.endTime);
      
      if (_timeRangesOverlap(start, end, classStart, classEnd)) {
        return false;
      }
    }
    
    // Check task conflicts
    for (var task in tasks) {
      if (task.scheduledTime != null) {
        final taskStart = _parseTimeToDateTime(start, task.scheduledTime!);
        final taskEnd = taskStart.add(Duration(minutes: task.durationMinutes));
        
        if (_timeRangesOverlap(start, end, taskStart, taskEnd)) {
          return false;
        }
      }
    }
    
    return true;
  }

  /// Check if two time ranges overlap
  bool _timeRangesOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Parse time string to DateTime
  DateTime _parseTimeToDateTime(DateTime date, String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _formatHour(int hour) {
    return hour.toString().padLeft(2, '0');
  }

  String _getSlotReason(String timeOfDay, double score) {
    if (score > 85) {
      return 'Peak productivity time - excellent for deep focus';
    } else if (score > 75) {
      return 'High productivity expected based on your patterns';
    } else if (score > 65) {
      return 'Good time for moderate difficulty tasks';
    } else {
      return 'Available slot - consider lighter review work';
    }
  }

  String _getDayOfWeekName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  /// Analyze deadline pressure and generate urgent recommendations
  Future<void> analyzeDeadlinePressure() async {
    _deadlinePressures.clear();
    
    if (_upcomingAssignments.isEmpty) {
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    
    for (var assignment in _upcomingAssignments) {
      final daysRemaining = assignment.dueDate.difference(now).inDays;
      final hoursRemaining = assignment.dueDate.difference(now).inHours;
      
      // Calculate urgency
      String urgencyLevel;
      double riskScore;
      
      if (hoursRemaining < 24) {
        urgencyLevel = 'critical';
        riskScore = 0.9;
      } else if (daysRemaining <= 2) {
        urgencyLevel = 'high';
        riskScore = 0.7;
      } else if (daysRemaining <= 5) {
        urgencyLevel = 'medium';
        riskScore = 0.5;
      } else {
        urgencyLevel = 'low';
        riskScore = 0.3;
      }
      
      // Adjust risk based on estimated hours
      final hoursNeeded = assignment.estimatedHours;
      if (hoursNeeded > hoursRemaining / 2) {
        riskScore = (riskScore + 0.2).clamp(0.0, 1.0);
      }
      
      _deadlinePressures.add(DeadlinePressure(
        assignment: assignment,
        daysRemaining: daysRemaining,
        hoursNeeded: hoursNeeded,
        urgencyLevel: urgencyLevel,
        riskScore: riskScore,
      ));
      
      // Generate urgent recommendations for high-risk assignments
      if (urgencyLevel == 'critical' || urgencyLevel == 'high') {
        _generateUrgentRecommendation(assignment, daysRemaining, hoursNeeded);
      }
    }
    
    // Sort by risk score (highest first)
    _deadlinePressures.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    
    notifyListeners();
  }

  /// Generate urgent study recommendation for approaching deadlines
  void _generateUrgentRecommendation(Assignment assignment, int daysRemaining, int hoursNeeded) {
    // Find next available optimal time slots
    final availableSlots = _optimalTimeSlots.where((slot) {
      return slot.date.isAfter(DateTime.now()) && 
             slot.isFree &&
             slot.productivityScore > 70;
    }).take(3).toList();
    
    if (availableSlots.isEmpty) return;
    
    final timeSlots = availableSlots.map((s) => s.timeSlot).toList();
    final bestSlot = availableSlots.first;
    
    String description;
    if (daysRemaining < 1) {
      description = '⚠️ DUE TODAY! Start immediately in your next free slot';
    } else if (daysRemaining == 1) {
      description = '⚠️ Due tomorrow! Schedule ${hoursNeeded}h of focused work';
    } else {
      description = 'Due in $daysRemaining days - allocate ${hoursNeeded}h over ${daysRemaining} sessions';
    }
    
    _recommendations.insert(0, StudyRecommendation(
      title: '🔥 URGENT: ${assignment.title}',
      description: description,
      timeSlot: bestSlot.timeSlot,
      durationMinutes: (hoursNeeded * 60 / (daysRemaining + 1)).round().clamp(30, 120),
      confidence: 0.95,
      reason: 'Deadline approaching - ${assignment.courseCode} assignment due ${_formatDueDate(assignment.dueDate)}',
      type: RecommendationType.urgent,
      suggestedDate: bestSlot.date,
      assignmentId: assignment.id,
      specificTimeSlots: timeSlots,
    ));
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    
    if (diff.inHours < 24) {
      return 'in ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'tomorrow';
    } else {
      return 'in ${diff.inDays} days';
    }
  }

  /// Get personalized study schedule for next week
  Future<Map<String, List<StudyRecommendation>>> getWeeklyStudyPlan() async {
    final plan = <String, List<StudyRecommendation>>{};
    final today = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final date = today.add(Duration(days: i));
      final dayKey = '${_getDayOfWeekName(date)} ${date.month}/${date.day}';
      
      // Get optimal slots for this day
      final daySlots = _optimalTimeSlots.where((slot) {
        return slot.date.year == date.year &&
               slot.date.month == date.month &&
               slot.date.day == date.day &&
               slot.productivityScore > 70;
      }).take(3).toList();
      
      final dayRecommendations = <StudyRecommendation>[];
      
      for (var slot in daySlots) {
        // Check if there's an urgent assignment
        final urgentAssignment = _findUrgentAssignmentForSlot(date);
        
        if (urgentAssignment != null) {
          dayRecommendations.add(StudyRecommendation(
            title: 'Work on: ${urgentAssignment.title}',
            description: urgentAssignment.description,
            timeSlot: slot.timeSlot,
            durationMinutes: slot.durationMinutes,
            confidence: 0.90,
            reason: 'Due ${_formatDueDate(urgentAssignment.dueDate)}',
            type: RecommendationType.deadline,
            suggestedDate: slot.date,
            assignmentId: urgentAssignment.id,
          ));
        } else {
          // General study recommendation
          final timeOfDay = _getTimeSlot(slot.date);
          dayRecommendations.add(StudyRecommendation(
            title: 'Study Session',
            description: slot.reason,
            timeSlot: slot.timeSlot,
            durationMinutes: slot.durationMinutes,
            confidence: slot.productivityScore / 100,
            reason: 'Your ${timeOfDay} productivity is typically high',
            type: RecommendationType.optimal,
            suggestedDate: slot.date,
          ));
        }
      }
      
      plan[dayKey] = dayRecommendations;
    }
    
    return plan;
  }

  Assignment? _findUrgentAssignmentForSlot(DateTime date) {
    for (var pressure in _deadlinePressures) {
      if (pressure.urgencyLevel == 'high' || pressure.urgencyLevel == 'critical') {
        // This assignment needs work before its due date
        if (date.isBefore(pressure.assignment.dueDate)) {
          return pressure.assignment;
        }
      }
    }
    return null;
  }

  /// Get smart study suggestions based on current context
  List<String> getSmartStudyTips() {
    final tips = <String>[];
    
    // Based on productivity patterns
    if (_productivityPatterns.isNotEmpty) {
      final bestTime = _productivityPatterns.entries
          .reduce((a, b) => a.value.avgProductivity > b.value.avgProductivity ? a : b);
      
      tips.add('📊 Your peak productivity is during ${bestTime.key} (${bestTime.value.avgProductivity.toStringAsFixed(1)}% avg)');
    }
    
    // Based on deadlines
    if (_deadlinePressures.isNotEmpty) {
      final urgent = _deadlinePressures.where((d) => d.urgencyLevel == 'critical' || d.urgencyLevel == 'high').length;
      if (urgent > 0) {
        tips.add('⚠️ You have $urgent urgent deadline${urgent > 1 ? 's' : ''} - prioritize today!');
      }
    }
    
    // Based on session patterns
    if (_recentSessions.length >= 7) {
      final avgDuration = _recentSessions.fold(0, (sum, s) => sum + s.durationMinutes) / _recentSessions.length;
      if (avgDuration > 60) {
        tips.add('💡 Consider shorter sessions with breaks - your average ${avgDuration.round()}min sessions might benefit from Pomodoro');
      }
    }
    
    // Based on free time
    if (_optimalTimeSlots.isNotEmpty) {
      final topSlot = _optimalTimeSlots.first;
      if (topSlot.date.isAfter(DateTime.now())) {
        final timeUntil = topSlot.date.difference(DateTime.now());
        if (timeUntil.inHours < 3) {
          tips.add('🎯 Your next optimal study time is in ${timeUntil.inHours}h at ${topSlot.timeSlot}');
        }
      }
    }
    
    return tips;
  }
}
