import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/active_recall.dart';
import 'gamification_service.dart';

/// Active Recall Service - Question bank, answer validation, session tracking
class ActiveRecallService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationService _gamificationService;
  
  String? _currentUserId;
  List<RecallQuestion> _questionBank = [];
  RecallSession? _currentSession;
  
  List<RecallQuestion> get questionBank => _questionBank;
  RecallSession? get currentSession => _currentSession;
  bool get hasActiveSession => _currentSession != null;
  
  ActiveRecallService(this._gamificationService);
  
  /// Initialize for user
  Future<void> initializeForUser(String userId) async {
    _currentUserId = userId;
    await _loadQuestionBank();
  }
  
  /// Load user's question bank
  Future<void> _loadQuestionBank() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('recall_questions')
          .orderBy('createdAt', descending: true)
          .get();
      
      _questionBank = snapshot.docs
          .map((doc) => RecallQuestion.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      notifyListeners();
      debugPrint('📚 Loaded ${_questionBank.length} recall questions');
    } catch (e) {
      debugPrint('Error loading question bank: $e');
    }
  }
  
  /// Add new question to bank
  Future<bool> addQuestion({
    required String question,
    required String correctAnswer,
    List<String>? keywords,
    String? topic,
    int difficulty = 3,
  }) async {
    debugPrint('📝 addQuestion called - userId: $_currentUserId');
    if (_currentUserId == null) {
      debugPrint('❌ addQuestion failed - No user logged in');
      return false;
    }
    
    try {
      debugPrint('📝 Extracting keywords...');
      // Extract keywords from answer if not provided
      final finalKeywords = keywords ?? _extractKeywords(correctAnswer);
      debugPrint('📝 Keywords: $finalKeywords');
      
      final questionData = {
        'userId': _currentUserId,
        'question': question,
        'correctAnswer': correctAnswer,
        'keywords': finalKeywords,
        'topic': topic,
        'difficulty': difficulty,
        'timesAsked': 0,
        'averageAccuracy': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastAskedAt': null,
      };
      
      debugPrint('📝 Writing to Firestore: users/$_currentUserId/recall_questions');
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('recall_questions')
          .add(questionData);
      
      debugPrint('✅ Added new recall question successfully');
      
      // Reload question bank in background (non-blocking)
      _loadQuestionBank().catchError((e) {
        debugPrint('⚠️ Error reloading questions: $e');
      });
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding question: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Extract keywords from answer (simple word splitting)
  List<String> _extractKeywords(String answer) {
    // Remove common words and split
    final commonWords = {'the', 'a', 'an', 'is', 'are', 'was', 'were', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'but'};
    
    return answer
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(' ')
        .where((word) => word.isNotEmpty && !commonWords.contains(word))
        .toSet() // Remove duplicates
        .toList();
  }
  
  /// Start new recall session
  Future<bool> startSession({String? topic, int questionCount = 10}) async {
    if (_currentUserId == null || hasActiveSession) return false;
    
    if (_questionBank.isEmpty) {
      debugPrint('Cannot start session - no questions in bank');
      return false;
    }
    
    // Filter by topic if specified
    var availableQuestions = topic != null
        ? _questionBank.where((q) => q.topic == topic).toList()
        : _questionBank;
    
    if (availableQuestions.isEmpty) {
      availableQuestions = _questionBank; // Fallback to all questions
    }
    
    // Select questions (prioritize least recently asked)
    availableQuestions.sort((a, b) {
      if (a.lastAskedAt == null && b.lastAskedAt == null) return 0;
      if (a.lastAskedAt == null) return -1;
      if (b.lastAskedAt == null) return 1;
      return a.lastAskedAt!.compareTo(b.lastAskedAt!);
    });
    
    final selectedQuestions = availableQuestions
        .take(questionCount)
        .map((q) => q.id)
        .toList();
    
    _currentSession = RecallSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUserId!,
      questionIds: selectedQuestions,
      attempts: [],
      startedAt: DateTime.now(),
      topic: topic,
    );
    
    notifyListeners();
    debugPrint('🎯 Started recall session with ${selectedQuestions.length} questions');
    return true;
  }
  
  /// Submit answer for current question
  Future<RecallAttempt?> submitAnswer(String userAnswer) async {
    if (!hasActiveSession || _currentUserId == null) {
      debugPrint('❌ No active session or user');
      return null;
    }
    
    final session = _currentSession!;
    final currentIndex = session.attempts.length;
    
    if (currentIndex >= session.questionIds.length) {
      debugPrint('❌ Session already complete');
      return null;
    }
    
    try {
      final questionId = session.questionIds[currentIndex];
      final question = _questionBank.firstWhere((q) => q.id == questionId);
      
      // Calculate accuracy
      final accuracy = _calculateAccuracy(userAnswer, question);
      
      // Determine XP based on accuracy
      int xpEarned = 0;
      if (accuracy >= 0.9) {
        xpEarned = 50; // Correct answer
      } else if (accuracy >= 0.5) {
        xpEarned = 30; // Partial answer
      } else {
        xpEarned = 10; // Attempt credit
      }
      
      final attempt = RecallAttempt(
        questionId: questionId,
        userAnswer: userAnswer,
        accuracy: accuracy,
        xpEarned: xpEarned,
        answeredAt: DateTime.now(),
      );
      
      // Update session immediately
      _currentSession = session.copyWith(
        attempts: [...session.attempts, attempt],
      );
      notifyListeners();
      
      debugPrint('✅ Answer submitted: ${(accuracy * 100).toStringAsFixed(0)}% accurate, +$xpEarned XP');
      
      // Complete all updates before returning so UI can show feedback
      try {
        await Future.wait([
          _updateQuestionStats(questionId, accuracy),
          _gamificationService.awardXP(xpEarned, source: 'Active Recall'),
          _gamificationService.updateQuestProgress('active_recall'),
        ]);
        debugPrint('✅ Database updates completed');
      } catch (e) {
        debugPrint('⚠️ Error in background updates: $e');
        // Continue anyway - attempt was successful
      }
      
      return attempt;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in submitAnswer: $e');
      debugPrint('Stack: $stackTrace');
      return null;
    }
  }
  
  /// Calculate answer accuracy using keyword matching
  double _calculateAccuracy(String userAnswer, RecallQuestion question) {
    final userLower = userAnswer.toLowerCase().trim();
    final correctLower = question.correctAnswer.toLowerCase().trim();
    
    // Exact match
    if (userLower == correctLower) {
      return 1.0;
    }
    
    // Calculate keyword match percentage
    if (question.keywords.isEmpty) {
      // Fallback: simple contains check
      return correctLower.contains(userLower) || userLower.contains(correctLower) 
          ? 0.7 
          : 0.0;
    }
    
    int matchedKeywords = 0;
    for (var keyword in question.keywords) {
      if (userLower.contains(keyword.toLowerCase())) {
        matchedKeywords++;
      }
    }
    
    final keywordMatchRate = matchedKeywords / question.keywords.length;
    
    // Bonus for answer length similarity
    final lengthRatio = (userAnswer.length / question.correctAnswer.length).clamp(0.5, 1.5);
    final lengthScore = (lengthRatio - 0.5) / 1.0; // Normalize to 0-1
    
    // Weighted average: 80% keyword match, 20% length similarity
    final accuracy = (keywordMatchRate * 0.8) + (lengthScore * 0.2);
    
    return accuracy.clamp(0.0, 1.0);
  }
  
  /// Update question statistics
  Future<void> _updateQuestionStats(String questionId, double accuracy) async {
    if (_currentUserId == null) return;
    
    try {
      final question = _questionBank.firstWhere((q) => q.id == questionId);
      final newTimesAsked = question.timesAsked + 1;
      final newAvgAccuracy = 
          ((question.averageAccuracy * question.timesAsked) + accuracy) / newTimesAsked;
      
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('recall_questions')
          .doc(questionId)
          .update({
        'timesAsked': newTimesAsked,
        'averageAccuracy': newAvgAccuracy,
        'lastAskedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating question stats: $e');
    }
  }
  
  /// Get current question
  RecallQuestion? getCurrentQuestion() {
    if (!hasActiveSession) return null;
    
    final session = _currentSession!;
    final currentIndex = session.attempts.length;
    
    if (currentIndex >= session.questionIds.length) return null;
    
    final questionId = session.questionIds[currentIndex];
    return _questionBank.firstWhere((q) => q.id == questionId);
  }
  
  /// Get session progress (0.0 to 1.0)
  double getSessionProgress() {
    if (!hasActiveSession) return 0.0;
    return _currentSession!.attempts.length / _currentSession!.questionIds.length;
  }
  
  /// Check if session is complete
  bool isSessionComplete() {
    if (!hasActiveSession) return false;
    return _currentSession!.attempts.length >= _currentSession!.questionIds.length;
  }
  
  /// End current session and save to Firestore
  Future<bool> endSession() async {
    debugPrint('🏁 endSession called - hasActiveSession: $hasActiveSession, userId: $_currentUserId');
    
    if (!hasActiveSession || _currentUserId == null) {
      debugPrint('❌ Cannot end session - no active session or user');
      return false;
    }
    
    try {
      final session = _currentSession!.copyWith(
        completedAt: DateTime.now(),
      );
      
      debugPrint('📝 Ending session: ${session.attempts.length} attempts, accuracy: ${session.accuracy}');
      
      // Calculate total XP
      final totalXP = session.attempts.fold<int>(0, (sum, attempt) => sum + attempt.xpEarned);
      
      debugPrint('💾 Saving to recall_sessions collection...');
      // Save recall session to Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('recall_sessions')
          .doc(session.id)
          .set(session.toJson());
      
      debugPrint('✅ Saved to recall_sessions');
      
      // ALSO create a study_session for analytics tracking
      final duration = session.completedAt?.difference(session.startedAt).inMinutes ?? 0;
      final totalQuestions = session.questionIds.length;
      final correctAnswers = session.attempts.where((a) => a.accuracy >= 0.9).length;
      
      final studySessionData = {
        'id': session.id,
        'userId': _currentUserId,
        'technique': 'active_recall',
        'status': 'completed',
        'startTime': Timestamp.fromDate(session.startedAt),
        'startedAt': Timestamp.fromDate(session.startedAt),
        'endTime': session.completedAt != null ? Timestamp.fromDate(session.completedAt!) : Timestamp.now(),
        'completedAt': session.completedAt != null ? Timestamp.fromDate(session.completedAt!) : Timestamp.now(),
        'durationMinutes': duration > 0 ? duration : 1,
        'topic': session.topic ?? 'Active Recall Practice',
        'pomodoroCount': 0,
        'breakCount': 0,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'productivityScore': session.accuracy * 100,
        'completed': true,
        'createdAt': Timestamp.fromDate(session.startedAt),
      };
      
      debugPrint('💾 Saving to study_sessions for analytics with technique=active_recall...');
      debugPrint('📊 Session data: duration=${duration}min, questions=$totalQuestions, correct=$correctAnswers, accuracy=${session.accuracy * 100}%');
      
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('study_sessions')
          .doc(session.id)
          .set(studySessionData);
      
      debugPrint('✅ Created study_session for analytics: ${duration}min, $correctAnswers/$totalQuestions correct');
      debugPrint('✅ Both collections updated successfully');
      
      // Update gamification
      await _gamificationService.incrementSessionCount();
      await _gamificationService.updateStreak();
      
      debugPrint('🏁 Session ended: ${session.accuracy * 100}% accuracy, $totalXP total XP');
      
      // Clear current session
      _currentSession = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error ending session: $e');
      return false;
    }
  }
  
  /// Cancel current session (no save)
  void cancelSession() {
    if (!hasActiveSession) return;
    
    _currentSession = null;
    notifyListeners();
    
    debugPrint('❌ Session cancelled');
  }
  
  /// Get recent sessions
  Future<List<RecallSession>> getRecentSessions({int limit = 10}) async {
    if (_currentUserId == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('recall_sessions')
          .orderBy('startedAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => RecallSession.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error loading recent sessions: $e');
      return [];
    }
  }
  
  /// Delete question from bank
  Future<bool> deleteQuestion(String questionId) async {
    if (_currentUserId == null) return false;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('recall_questions')
          .doc(questionId)
          .delete();
      
      await _loadQuestionBank();
      
      debugPrint('🗑️ Deleted question');
      return true;
    } catch (e) {
      debugPrint('Error deleting question: $e');
      return false;
    }
  }
  
  /// Get statistics
  Map<String, dynamic> getStatistics() {
    if (_questionBank.isEmpty) {
      return {
        'totalQuestions': 0,
        'averageAccuracy': 0.0,
        'totalAttempts': 0,
      };
    }
    
    final totalQuestions = _questionBank.length;
    final totalAttempts = _questionBank.fold<int>(0, (sum, q) => sum + q.timesAsked);
    final avgAccuracy = _questionBank.fold<double>(0, (sum, q) => sum + q.averageAccuracy) / totalQuestions;
    
    return {
      'totalQuestions': totalQuestions,
      'averageAccuracy': avgAccuracy,
      'totalAttempts': totalAttempts,
    };
  }
}
