import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gamification.dart';
import '../models/achievement_definitions.dart';

/// Gamification Service - Handles XP, levels, quests, achievements, rewards
class GamificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _currentUserId;
  UserGamification? _userGamification;
  List<Quest> _activeQuests = [];
  List<Achievement> _achievements = [];
  List<ActiveBoost> _activeBoosts = [];
  
  // Stream subscriptions for real-time updates
  var _achievementSubscription;
  
  UserGamification? get userGamification => _userGamification;
  List<Quest> get activeQuests => _activeQuests;
  List<Achievement> get achievements => _achievements;
  List<ActiveBoost> get activeBoosts => _activeBoosts;
  
  @override
  void dispose() {
    _achievementSubscription?.cancel();
    super.dispose();
  }
  
  // Title system
  static const Map<int, String> levelTitles = {
    1: 'New Learner',
    5: 'Focused Student',
    10: 'Consistent Achiever',
    15: 'Diligent Learner',
    20: 'Knowledge Seeker',
    25: 'Academic Warrior',
    30: 'IntelliMaster',
  };
  
  /// Initialize gamification for user
  Future<void> initializeForUser(String userId) async {
    // Skip if already initialized for this user
    if (_currentUserId == userId && _achievements.isNotEmpty) {
      debugPrint('✅ Already initialized for user $userId');
      return;
    }
    
    _currentUserId = userId;
    await _loadUserGamification();
    await initializeAchievements(); // Initialize all achievement definitions
    // Wait a bit to ensure Firestore write completes
    await Future.delayed(const Duration(milliseconds: 500));
    _setupAchievementStream(); // Setup real-time stream instead of manual load
    await _loadActiveQuests();
    await _loadActiveBoosts();
    await _cleanupExpiredBoosts();
  }
  
  /// Load or create user gamification profile
  Future<void> _loadUserGamification() async {
    if (_currentUserId == null) return;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('gamification')
          .doc('profile')
          .get();
      
      if (doc.exists) {
        _userGamification = UserGamification.fromJson({
          ...doc.data()!,
          'userId': _currentUserId!,
        });
      } else {
        // Create new profile
        _userGamification = UserGamification(
          userId: _currentUserId!,
          level: 1,
          xp: 0,
          studyPoints: 0,
          title: 'New Learner',
          streakDays: 0,
          totalXpEarned: 0,
          totalSessionsCompleted: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _saveUserGamification();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading gamification profile: $e');
    }
  }
  
  /// Save user gamification profile
  Future<void> _saveUserGamification() async {
    if (_currentUserId == null || _userGamification == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('gamification')
          .doc('profile')
          .set(_userGamification!.toJson());
    } catch (e) {
      debugPrint('Error saving gamification profile: $e');
    }
  }
  
  /// Award XP to user
  Future<void> awardXP(int xpAmount, {String? source}) async {
    if (_userGamification == null) return;
    
    // Check for active XP multiplier boost
    final xpMultiplier = _getActiveXPMultiplier();
    final finalXP = (xpAmount * xpMultiplier).round();
    
    final currentLevel = _userGamification!.level;
    final newXP = _userGamification!.xp + finalXP;
    
    bool leveledUp = false;
    int newLevel = currentLevel;
    int remainingXP = newXP;
    
    // Handle level up(s)
    while (remainingXP >= (100 * newLevel) && newLevel < 30) {
      remainingXP -= (100 * newLevel);
      newLevel++;
      leveledUp = true;
    }
    
    // Get new title if leveled up
    String newTitle = _userGamification!.title;
    if (leveledUp) {
      newTitle = _getTitleForLevel(newLevel);
    }
    
    _userGamification = _userGamification!.copyWith(
      level: newLevel,
      xp: remainingXP,
      title: newTitle,
      totalXpEarned: _userGamification!.totalXpEarned + finalXP,
      updatedAt: DateTime.now(),
    );
    
    await _saveUserGamification();
    notifyListeners();
    
    debugPrint('✨ Awarded $finalXP XP from $source (${xpMultiplier}x multiplier)');
    
    if (leveledUp) {
      debugPrint('🎉 LEVEL UP! Now level $newLevel: $newTitle');
      // Could trigger level up notification here
    }
  }
  
  /// Award study points
  Future<void> awardStudyPoints(int points) async {
    if (_userGamification == null) return;
    
    _userGamification = _userGamification!.copyWith(
      studyPoints: _userGamification!.studyPoints + points,
      updatedAt: DateTime.now(),
    );
    
    await _saveUserGamification();
    notifyListeners();
    
    debugPrint('💰 Awarded $points Study Points');
  }
  
  /// Update study streak
  Future<void> updateStreak() async {
    if (_userGamification == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStudy = _userGamification!.lastStudyDate;
    
    if (lastStudy == null) {
      // First study session
      _userGamification = _userGamification!.copyWith(
        streakDays: 1,
        lastStudyDate: today,
        updatedAt: now,
      );
    } else {
      final lastStudyDay = DateTime(lastStudy.year, lastStudy.month, lastStudy.day);
      final daysDiff = today.difference(lastStudyDay).inDays;
      
      if (daysDiff == 0) {
        // Same day, no change
        return;
      } else if (daysDiff == 1) {
        // Consecutive day - increment streak
        final newStreak = _userGamification!.streakDays + 1;
        _userGamification = _userGamification!.copyWith(
          streakDays: newStreak,
          lastStudyDate: today,
          updatedAt: now,
        );
        
        // Award streak bonuses
        if (newStreak == 7) {
          await awardXP(200, source: '7-day streak bonus');
        } else if (newStreak == 14) {
          await awardXP(500, source: '14-day streak bonus');
        } else if (newStreak == 30) {
          await awardXP(1000, source: '30-day streak bonus');
        }
      } else {
        // Streak broken - reset
        _userGamification = _userGamification!.copyWith(
          streakDays: 1,
          lastStudyDate: today,
          updatedAt: now,
        );
        debugPrint('💔 Streak broken, reset to 1');
      }
    }
    
    await _saveUserGamification();
    notifyListeners();
  }
  
  /// Get title for level
  String _getTitleForLevel(int level) {
    int titleLevel = 1;
    for (var lvl in levelTitles.keys) {
      if (level >= lvl) {
        titleLevel = lvl;
      }
    }
    return levelTitles[titleLevel] ?? 'New Learner';
  }
  
  /// Get active XP multiplier from boosts
  double _getActiveXPMultiplier() {
    double multiplier = 1.0;
    for (var boost in _activeBoosts) {
      if (boost.isActive && boost.type == BoostType.xpMultiplier) {
        final boostMultiplier = boost.effectData?['multiplier'] as double? ?? 1.1;
        multiplier *= boostMultiplier;
      }
    }
    return multiplier;
  }
  
  /// Load active quests
  Future<void> _loadActiveQuests() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('quests')
          .where('status', whereIn: ['active', 'completed'])
          .orderBy('endAt')
          .get();
      
      _activeQuests = snapshot.docs
          .map((doc) => Quest.fromJson({...doc.data(), 'id': doc.id}))
          .where((q) => !q.isExpired)
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading quests: $e');
    }
  }
  
  /// Update quest progress
  Future<void> updateQuestProgress(String questType, {int increment = 1}) async {
    if (_currentUserId == null) return;
    
    final affectedQuests = _activeQuests.where((q) => 
      q.status == QuestStatus.active &&
      (q.techniqueType == questType || questType == 'general')
    ).toList();
    
    for (var quest in affectedQuests) {
      final newProgress = quest.progress + increment;
      final isComplete = newProgress >= quest.target;
      
      try {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('quests')
            .doc(quest.id)
            .update({
          'progress': newProgress,
          'status': isComplete ? 'completed' : 'active',
          'completedAt': isComplete ? FieldValue.serverTimestamp() : null,
        });
        
        if (isComplete) {
          debugPrint('🎯 Quest completed: ${quest.name}');
        }
      } catch (e) {
        debugPrint('Error updating quest progress: $e');
      }
    }
    
    await _loadActiveQuests();
  }
  
  /// Claim quest reward
  Future<bool> claimQuestReward(String questId) async {
    if (_currentUserId == null) return false;
    
    try {
      final quest = _activeQuests.firstWhere((q) => q.id == questId);
      
      if (!quest.canClaim) {
        debugPrint('Cannot claim quest - not ready');
        return false;
      }
      
      // Award XP and study points
      await awardXP(quest.xpReward, source: 'Quest: ${quest.name}');
      await awardStudyPoints(quest.studyPointsReward);
      
      // Update quest status
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('quests')
          .doc(questId)
          .update({
        'status': 'claimed',
        'claimedAt': FieldValue.serverTimestamp(),
      });
      
      await _loadActiveQuests();
      
      debugPrint('🎁 Claimed quest reward: ${quest.name}');
      return true;
    } catch (e) {
      debugPrint('Error claiming quest reward: $e');
      return false;
    }
  }
  
  /// Create daily quests
  Future<void> createDailyQuests() async {
    if (_currentUserId == null) return;
    
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    final dailyQuests = [
      {
        'name': 'Complete 3 tasks today',
        'description': 'Mark 3 tasks as complete',
        'type': 'daily',
        'techniqueType': 'general',
        'target': 3,
        'xpReward': 100,
        'studyPointsReward': 5,
      },
      {
        'name': 'Study for 1 hour',
        'description': 'Accumulate 60 minutes of study time',
        'type': 'daily',
        'techniqueType': 'general',
        'target': 60,
        'xpReward': 120,
        'studyPointsReward': 8,
      },
      {
        'name': 'Complete 4 Pomodoro sessions',
        'description': 'Finish 4 focused Pomodoro sessions',
        'type': 'daily',
        'techniqueType': 'pomodoro',
        'target': 4,
        'xpReward': 150,
        'studyPointsReward': 10,
      },
    ];
    
    for (var questData in dailyQuests) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('quests')
            .add({
          ...questData,
          'userId': _currentUserId,
          'progress': 0,
          'status': 'active',
          'startAt': Timestamp.fromDate(now),
          'endAt': Timestamp.fromDate(endOfDay),
        });
      } catch (e) {
        debugPrint('Error creating daily quest: $e');
      }
    }
    
    await _loadActiveQuests();
  }
  
  /// Setup achievement stream for real-time updates
  void _setupAchievementStream() {
    if (_currentUserId == null) {
      debugPrint('⚠️ Cannot setup achievement stream: No user ID');
      return;
    }
    
    debugPrint('📡 Setting up achievement stream for user: $_currentUserId');
    
    // Cancel existing subscription if any
    _achievementSubscription?.cancel();
    
    // Setup real-time stream
    _achievementSubscription = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('achievements')
        .snapshots()
        .listen((snapshot) {
      debugPrint('📥 Achievement stream update: ${snapshot.docs.length} documents');
      
      _achievements = snapshot.docs
          .map((doc) {
            final data = {...doc.data(), 'id': doc.id};
            return Achievement.fromJson(data);
          })
          .toList();
      
      debugPrint('✅ Achievements updated: ${_achievements.length} total, ${_achievements.where((a) => a.unlocked).length} unlocked');
      
      notifyListeners();
    }, onError: (error) {
      debugPrint('❌ Achievement stream error: $error');
    });
  }
  
  /// Load achievements (fallback for manual refresh)
  Future<void> _loadAchievements() async {
    if (_currentUserId == null) {
      debugPrint('⚠️ Cannot load achievements: No user ID');
      return;
    }
    
    try {
      debugPrint('📥 Manual loading achievements for user: $_currentUserId');
      
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('achievements')
          .get();
      
      _achievements = snapshot.docs
          .map((doc) {
            final data = {...doc.data(), 'id': doc.id};
            return Achievement.fromJson(data);
          })
          .toList();
      
      debugPrint('✅ Loaded ${_achievements.length} achievements successfully');
      
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading achievements: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  /// Unlock achievement
  Future<void> unlockAchievement(String achievementId) async {
    if (_currentUserId == null) return;
    
    try {
      final achievement = _achievements.firstWhere((a) => a.id == achievementId);
      
      if (achievement.unlocked) return;
      
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('achievements')
          .doc(achievementId)
          .update({
        'unlocked': true,
        'unlockedAt': FieldValue.serverTimestamp(),
      });
      
      await awardXP(achievement.xpReward, source: 'Achievement: ${achievement.name}');
      // No need to reload - stream will update automatically
      
      debugPrint('🏆 Achievement unlocked: ${achievement.name}');
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }
  
  /// Load active boosts
  Future<void> _loadActiveBoosts() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('active_boosts')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .get();
      
      _activeBoosts = snapshot.docs
          .map((doc) => ActiveBoost.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading active boosts: $e');
    }
  }
  
  /// Purchase and activate reward/boost
  Future<bool> purchaseReward(Reward reward) async {
    if (_currentUserId == null || _userGamification == null) return false;
    
    if (_userGamification!.studyPoints < reward.cost) {
      debugPrint('Not enough study points');
      return false;
    }
    
    try {
      // Deduct study points
      _userGamification = _userGamification!.copyWith(
        studyPoints: _userGamification!.studyPoints - reward.cost,
        updatedAt: DateTime.now(),
      );
      await _saveUserGamification();
      
      // Activate boost
      final now = DateTime.now();
      final expiresAt = now.add(Duration(minutes: reward.duration));
      
      final boost = ActiveBoost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentUserId!,
        rewardId: reward.id,
        type: reward.type,
        activatedAt: now,
        expiresAt: expiresAt,
        effectData: reward.effectData,
      );
      
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('active_boosts')
          .doc(boost.id)
          .set(boost.toJson());
      
      await _loadActiveBoosts();
      
      debugPrint('🚀 Activated boost: ${reward.name}');
      return true;
    } catch (e) {
      debugPrint('Error purchasing reward: $e');
      return false;
    }
  }
  
  /// Cleanup expired boosts
  Future<void> _cleanupExpiredBoosts() async {
    if (_currentUserId == null) return;
    
    final expiredBoosts = _activeBoosts.where((b) => b.isExpired).toList();
    
    for (var boost in expiredBoosts) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('active_boosts')
            .doc(boost.id)
            .delete();
      } catch (e) {
        debugPrint('Error deleting expired boost: $e');
      }
    }
    
    if (expiredBoosts.isNotEmpty) {
      await _loadActiveBoosts();
    }
  }
  
  /// Check if user has active boost of type
  bool hasActiveBoost(BoostType type) {
    return _activeBoosts.any((b) => b.isActive && b.type == type);
  }
  
  /// Increment session count
  Future<void> incrementSessionCount() async {
    if (_userGamification == null) return;
    
    _userGamification = _userGamification!.copyWith(
      totalSessionsCompleted: _userGamification!.totalSessionsCompleted + 1,
      updatedAt: DateTime.now(),
    );
    
    await _saveUserGamification();
    notifyListeners();
  }

  // ========================================
  // ACHIEVEMENT TRACKING SYSTEM
  // ========================================
  
  /// Initialize all achievement definitions for user
  Future<void> initializeAchievements() async {
    if (_currentUserId == null) return;
    
    final allDefs = AchievementDefinitions.getAll();
    
    // Debug: Track category distribution
    final Map<String, int> categoryCounts = {};
    
    debugPrint('🔄 Updating achievements with correct categories...');
    
    for (var def in allDefs) {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('achievements')
          .doc(def.id);
      
      final categoryStr = def.category.toString().split('.').last;
      categoryCounts[categoryStr] = (categoryCounts[categoryStr] ?? 0) + 1;
      
      // Get existing document
      final doc = await docRef.get(const GetOptions(source: Source.server));
      
      // Preserve unlocked status
      bool isUnlocked = false;
      dynamic unlockedAt;
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        isUnlocked = data['unlocked'] ?? false;
        unlockedAt = data['unlockedAt'];
      }
      
      // Force update with correct category
      await docRef.set({
        'id': def.id,
        'name': def.name,
        'description': def.description,
        'iconName': def.iconName,
        'unlocked': isUnlocked,
        'unlockedAt': unlockedAt,
        'xpReward': def.xpReward,
        'category': categoryStr,
        'condition': def.condition,
        'badge': def.badge,
        'tier': def.tier,
      });
      
      debugPrint('✅ Updated: ${def.name} [Category: $categoryStr, Unlocked: $isUnlocked]');
    }
    
    debugPrint('✅ Updated ${allDefs.length} achievements');
    debugPrint('📊 Category distribution: $categoryCounts');
    
    // CRITICAL: Wait a bit then force reload from server
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadAchievements();
    
    // Double-check: Load again to ensure fresh data
    await Future.delayed(const Duration(milliseconds: 300));
    final snapshot = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('achievements')
        .get(const GetOptions(source: Source.server));
    
    _achievements = snapshot.docs
        .map((doc) => Achievement.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
    
    notifyListeners();
    debugPrint('📋 Loaded ${_achievements.length} achievements into memory');
  }

  /// Track task creation
  Future<void> trackTaskCreated() async {
    await _incrementStat('tasks_created');
    await _checkAchievements();
  }

  /// Track task completion
  Future<void> trackTaskCompleted({bool onTime = false}) async {
    await _incrementStat('tasks_completed');
    if (onTime) {
      await _incrementStat('tasks_completed_on_time');
    }
    await _checkAchievements();
  }

  /// Track Pomodoro session
  Future<void> trackPomodoroSession() async {
    await _incrementStat('pomodoro_sessions');
    await _setStat('pomodoro_used', true);
    await _checkAchievements();
  }

  /// Track consecutive Pomodoro sessions
  Future<void> trackConsecutivePomodoros(int count) async {
    final current = await _getStat('consecutive_pomodoros') ?? 0;
    if (count > current) {
      await _setStat('consecutive_pomodoros', count);
      await _checkAchievements();
    }
  }

  /// Track daily Pomodoro minutes
  Future<void> trackDailyPomodoroMinutes(int minutes) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    final lastDateKey = await _getStat('last_pomodoro_date');
    
    if (lastDateKey == dateKey) {
      // Same day, add to total
      final current = await _getStat('daily_pomodoro_minutes') ?? 0;
      await _setStat('daily_pomodoro_minutes', current + minutes);
    } else {
      // New day, reset
      await _setStat('daily_pomodoro_minutes', minutes);
      await _setStat('last_pomodoro_date', dateKey);
    }
    await _checkAchievements();
  }

  /// Track flashcard review
  Future<void> trackFlashcardReview({bool onTime = false}) async {
    await _incrementStat('flashcards_reviewed');
    await _setStat('spaced_repetition_used', true);
    if (onTime) {
      await _incrementStat('on_time_reviews');
    }
    await _checkAchievements();
  }

  /// Track recall question
  Future<void> trackRecallQuestion({double? sessionAccuracy}) async {
    await _incrementStat('recall_questions');
    await _setStat('active_recall_used', true);
    
    if (sessionAccuracy != null) {
      if (sessionAccuracy >= 90) {
        await _incrementStat('high_accuracy_sessions');
      }
      await _setStat('recall_session_accuracy', sessionAccuracy.round());
    }
    await _checkAchievements();
  }

  /// Track early/late sessions
  Future<void> trackSessionTime({required DateTime startTime, DateTime? endTime}) async {
    final hour = startTime.hour;
    if (hour < 8) {
      await _incrementStat('early_sessions');
    }
    
    if (endTime != null && endTime.hour >= 22) {
      await _incrementStat('late_sessions');
    }
    await _checkAchievements();
  }

  /// Track subject addition
  Future<void> trackSubjectAdded() async {
    await _incrementStat('subjects_added');
    await _checkAchievements();
  }

  /// Track weekly study time
  Future<void> trackWeeklyStudyTime(int minutes) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = '${weekStart.year}-${weekStart.month}-${weekStart.day}';
    final lastWeekKey = await _getStat('current_week');
    
    if (lastWeekKey == weekKey) {
      final current = await _getStat('weekly_study_minutes') ?? 0;
      await _setStat('weekly_study_minutes', current + minutes);
    } else {
      await _setStat('weekly_study_minutes', minutes);
      await _setStat('current_week', weekKey);
    }
    await _checkAchievements();
  }

  // Helper methods for stats
  Future<void> _incrementStat(String key) async {
    if (_currentUserId == null) return;
    
    try {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('gamification')
          .doc('stats');
      
      await docRef.set({
        key: FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error incrementing stat $key: $e');
    }
  }

  Future<void> _setStat(String key, dynamic value) async {
    if (_currentUserId == null) return;
    
    try {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('gamification')
          .doc('stats');
      
      await docRef.set({
        key: value,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting stat $key: $e');
    }
  }

  Future<dynamic> _getStat(String key) async {
    if (_currentUserId == null) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('gamification')
          .doc('stats')
          .get();
      
      return doc.data()?[key];
    } catch (e) {
      debugPrint('Error getting stat $key: $e');
      return null;
    }
  }

  /// Check and unlock achievements
  Future<void> _checkAchievements() async {
    if (_currentUserId == null) return;
    
    // Get current stats
    final statsDoc = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('gamification')
        .doc('stats')
        .get();
    
    final stats = statsDoc.data() ?? {};
    final streakDays = _userGamification?.streakDays ?? 0;
    stats['streak_days'] = streakDays;
    
    // Check each locked achievement
    final lockedAchievements = _achievements.where((a) => !a.unlocked).toList();
    
    for (var achievement in lockedAchievements) {
      final condition = achievement.id; // Using ID as condition reference
      bool shouldUnlock = false;
      
      // Check condition based on achievement ID patterns
      switch (condition) {
        // General
        case 'first_step':
          shouldUnlock = (stats['tasks_created'] ?? 0) >= 1;
          break;
        case 'getting_organized':
          shouldUnlock = (stats['tasks_created'] ?? 0) >= 10;
          break;
        case 'habit_former':
          shouldUnlock = (stats['tasks_completed'] ?? 0) >= 10;
          break;
        case 'consistency_starter':
          shouldUnlock = streakDays >= 3;
          break;
        case 'task_slayer':
          shouldUnlock = (stats['tasks_completed'] ?? 0) >= 100;
          break;
        case 'deadline_defender':
          shouldUnlock = (stats['tasks_completed_on_time'] ?? 0) >= 20;
          break;
        case 'early_bird':
          shouldUnlock = (stats['early_sessions'] ?? 0) >= 1;
          break;
        case 'night_owl':
          shouldUnlock = (stats['late_sessions'] ?? 0) >= 1;
          break;
        case 'all_rounder':
          shouldUnlock = (stats['pomodoro_used'] == true) &&
              (stats['spaced_repetition_used'] == true) &&
              (stats['active_recall_used'] == true);
          break;
        case 'marathon_learner':
          shouldUnlock = (stats['weekly_study_minutes'] ?? 0) >= 720;
          break;
        case 'academic_titan':
          shouldUnlock = (stats['tasks_completed'] ?? 0) >= 300;
          break;
        
        // Subject
        case 'course_starter':
          shouldUnlock = (stats['subjects_added'] ?? 0) >= 1;
          break;
        case 'course_loader':
          shouldUnlock = (stats['subjects_added'] ?? 0) >= 5;
          break;
        
        // Pomodoro
        case 'focus_initiate':
          shouldUnlock = (stats['pomodoro_sessions'] ?? 0) >= 1;
          break;
        case 'steady_worker':
          shouldUnlock = (stats['pomodoro_sessions'] ?? 0) >= 10;
          break;
        case 'time_manager':
          shouldUnlock = (stats['pomodoro_sessions'] ?? 0) >= 25;
          break;
        case 'focus_hero':
          shouldUnlock = (stats['pomodoro_sessions'] ?? 0) >= 50;
          break;
        case 'deep_work_champion':
          shouldUnlock = (stats['consecutive_pomodoros'] ?? 0) >= 4;
          break;
        case 'iron_focus':
          shouldUnlock = (stats['daily_pomodoro_minutes'] ?? 0) >= 120;
          break;
        
        // Spaced Repetition
        case 'memory_novice':
          shouldUnlock = (stats['flashcards_reviewed'] ?? 0) >= 10;
          break;
        case 'spacing_starter':
          shouldUnlock = (stats['on_time_reviews'] ?? 0) >= 1;
          break;
        case 'memory_builder':
          shouldUnlock = (stats['flashcards_reviewed'] ?? 0) >= 200;
          break;
        case 'flashcard_typhoon':
          shouldUnlock = (stats['flashcards_reviewed'] ?? 0) >= 500;
          break;
        
        // Active Recall
        case 'recall_rookie':
          shouldUnlock = (stats['recall_questions'] ?? 0) >= 5;
          break;
        case 'first_challenge':
          shouldUnlock = (stats['recall_session_accuracy'] ?? 0) >= 60;
          break;
        case 'recall_champion':
          shouldUnlock = (stats['recall_questions'] ?? 0) >= 100;
          break;
        case 'sharp_mind':
          shouldUnlock = (stats['recall_session_accuracy'] ?? 0) >= 80;
          break;
        case 'memory_gladiator':
          shouldUnlock = (stats['high_accuracy_sessions'] ?? 0) >= 3;
          break;
        case 'recall_beast':
          shouldUnlock = (stats['recall_questions'] ?? 0) >= 300;
          break;
        
        // Streak
        case 'streak_starter':
          shouldUnlock = streakDays >= 3;
          break;
        case 'streak_builder':
          shouldUnlock = streakDays >= 7;
          break;
        case 'study_warrior':
          shouldUnlock = streakDays >= 14;
          break;
        case 'master_of_discipline':
          shouldUnlock = streakDays >= 30;
          break;
      }
      
      if (shouldUnlock) {
        await unlockAchievement(achievement.id);
      }
    }
  }
}

