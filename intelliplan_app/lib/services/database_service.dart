import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../models/lesson.dart';
import '../models/user.dart' as app_models;

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================
  
  /// Create a new user document
  Future<void> createUser(app_models.User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(
        user.toJson()..remove('id'),
      );
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<app_models.User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return app_models.User.fromJson({
          ...doc.data()!,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update user data
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  /// Stream user data (for real-time updates)
  Stream<app_models.User?> streamUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return app_models.User.fromJson({
          ...doc.data()!,
          'id': doc.id,
        });
      }
      return null;
    });
  }

  // ==================== ACHIEVEMENT OPERATIONS ====================
  
  /// Initialize default achievements for a user
  Future<void> initializeAchievements(String userId) async {
    try {
      final achievements = _getDefaultAchievements();
      
      final batch = _firestore.batch();
      for (var achievement in achievements) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(achievement.id);
        batch.set(docRef, achievement.toJson()..remove('id'));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error initializing achievements: $e');
      rethrow;
    }
  }

  /// Get all achievements for a user
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();
      
      return snapshot.docs
          .map((doc) => Achievement.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return [];
    }
  }

  /// Stream achievements (for real-time updates)
  Stream<List<Achievement>> streamUserAchievements(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Achievement.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  /// Unlock an achievement
  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .update({
        'isUnlocked': true,
        'unlockedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
      rethrow;
    }
  }

  // ==================== LESSON OPERATIONS ====================
  
  /// Create a new lesson
  Future<String> createLesson(Lesson lesson) async {
    try {
      final docRef = await _firestore.collection('lessons').add(
        lesson.toJson()..remove('id'),
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating lesson: $e');
      rethrow;
    }
  }

  /// Get all lessons
  Future<List<Lesson>> getAllLessons() async {
    try {
      final snapshot = await _firestore
          .collection('lessons')
          .orderBy('subject')
          .get();
      
      return snapshot.docs
          .map((doc) => Lesson.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error getting lessons: $e');
      return [];
    }
  }

  /// Get lessons by subject
  Future<List<Lesson>> getLessonsBySubject(String subject) async {
    try {
      final snapshot = await _firestore
          .collection('lessons')
          .where('subject', isEqualTo: subject)
          .get();
      
      return snapshot.docs
          .map((doc) => Lesson.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error getting lessons by subject: $e');
      return [];
    }
  }

  /// Stream lessons (for real-time updates)
  Stream<List<Lesson>> streamLessons() {
    return _firestore
        .collection('lessons')
        .orderBy('subject')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Lesson.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  /// Mark lesson as completed for a user
  Future<void> completeLessonForUser(
    String userId,
    String lessonId,
    double progress,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedLessons')
          .doc(lessonId)
          .set({
        'lessonId': lessonId,
        'progress': progress,
        'isCompleted': progress >= 1.0,
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error completing lesson: $e');
      rethrow;
    }
  }

  /// Get user's completed lessons
  Future<List<String>> getCompletedLessonIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedLessons')
          .where('isCompleted', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()['lessonId'] as String).toList();
    } catch (e) {
      debugPrint('Error getting completed lessons: $e');
      return [];
    }
  }

  // ==================== LEADERBOARD OPERATIONS ====================
  
  /// Get top users by experience
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('experience', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.asMap().entries.map((entry) {
        final data = entry.value.data();
        return {
          'rank': entry.key + 1,
          'userId': entry.value.id,
          'name': data['name'],
          'level': data['level'],
          'experience': data['experience'],
          'avatarUrl': data['avatarUrl'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get user's rank
  Future<int> getUserRank(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return 0;
      
      final snapshot = await _firestore
          .collection('users')
          .where('experience', isGreaterThan: user.experience)
          .get();
      
      return snapshot.docs.length + 1;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return 0;
    }
  }

  // ==================== HELPER METHODS ====================
  
  /// Get default achievements
  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(
        id: 'achievement_1',
        title: 'First Steps',
        description: 'Complete your first lesson',
        iconPath: 'assets/icons/achievement_1.png',
        pointsRequired: 10,
        isUnlocked: false,
        category: AchievementCategory.general,
      ),
      Achievement(
        id: 'achievement_2',
        title: 'Knowledge Seeker',
        description: 'Complete 10 lessons',
        iconPath: 'assets/icons/achievement_2.png',
        pointsRequired: 100,
        isUnlocked: false,
        category: AchievementCategory.subject,
      ),
      Achievement(
        id: 'achievement_3',
        title: 'Consistent Learner',
        description: 'Maintain a 7-day streak',
        iconPath: 'assets/icons/achievement_3.png',
        pointsRequired: 70,
        isUnlocked: false,
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: 'achievement_4',
        title: 'Master Mind',
        description: 'Score 100% on 5 lessons',
        iconPath: 'assets/icons/achievement_4.png',
        pointsRequired: 200,
        isUnlocked: false,
        category: AchievementCategory.general,
      ),
      Achievement(
        id: 'achievement_5',
        title: 'Rising Star',
        description: 'Reach level 10',
        iconPath: 'assets/icons/achievement_5.png',
        pointsRequired: 500,
        isUnlocked: false,
        category: AchievementCategory.general,
      ),
    ];
  }
}
