import 'package:cloud_firestore/cloud_firestore.dart';

/// User Gamification Profile
class UserGamification {
  final String userId;
  final int level;
  final int xp;
  final int studyPoints;
  final String title;
  final int streakDays;
  final DateTime? lastStudyDate;
  final int totalXpEarned;
  final int totalSessionsCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserGamification({
    required this.userId,
    required this.level,
    required this.xp,
    required this.studyPoints,
    required this.title,
    required this.streakDays,
    this.lastStudyDate,
    required this.totalXpEarned,
    required this.totalSessionsCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserGamification.fromJson(Map<String, dynamic> json) {
    return UserGamification(
      userId: json['userId'] as String,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      studyPoints: json['studyPoints'] as int? ?? 0,
      title: json['title'] as String? ?? 'New Learner',
      streakDays: json['streakDays'] as int? ?? 0,
      lastStudyDate: json['lastStudyDate'] != null
          ? (json['lastStudyDate'] as Timestamp).toDate()
          : null,
      totalXpEarned: json['totalXpEarned'] as int? ?? 0,
      totalSessionsCompleted: json['totalSessionsCompleted'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'level': level,
      'xp': xp,
      'studyPoints': studyPoints,
      'title': title,
      'streakDays': streakDays,
      'lastStudyDate': lastStudyDate != null ? Timestamp.fromDate(lastStudyDate!) : null,
      'totalXpEarned': totalXpEarned,
      'totalSessionsCompleted': totalSessionsCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Calculate XP required for next level
  int get xpForNextLevel => 100 * level;

  /// Calculate XP progress percentage
  double get xpProgress => (xp / xpForNextLevel).clamp(0.0, 1.0);

  /// Check if ready to level up
  bool get canLevelUp => xp >= xpForNextLevel && level < 30;

  UserGamification copyWith({
    int? level,
    int? xp,
    int? studyPoints,
    String? title,
    int? streakDays,
    DateTime? lastStudyDate,
    int? totalXpEarned,
    int? totalSessionsCompleted,
    DateTime? updatedAt,
  }) {
    return UserGamification(
      userId: userId,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      studyPoints: studyPoints ?? this.studyPoints,
      title: title ?? this.title,
      streakDays: streakDays ?? this.streakDays,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      totalSessionsCompleted: totalSessionsCompleted ?? this.totalSessionsCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Quest types
enum QuestType { daily, weekly, techniqueSpecific, general }
enum QuestStatus { active, completed, claimed, expired }

/// Quest model
class Quest {
  final String id;
  final String userId;
  final String name;
  final String description;
  final QuestType type;
  final String? techniqueType; // 'pomodoro', 'spacedRepetition', 'activeRecall'
  final int progress;
  final int target;
  final int xpReward;
  final int studyPointsReward;
  final QuestStatus status;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? completedAt;
  final DateTime? claimedAt;

  Quest({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.type,
    this.techniqueType,
    required this.progress,
    required this.target,
    required this.xpReward,
    required this.studyPointsReward,
    required this.status,
    required this.startAt,
    required this.endAt,
    this.completedAt,
    this.claimedAt,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: QuestType.values.firstWhere(
        (e) => e.toString() == 'QuestType.${json['type']}',
        orElse: () => QuestType.general,
      ),
      techniqueType: json['techniqueType'] as String?,
      progress: json['progress'] as int? ?? 0,
      target: json['target'] as int,
      xpReward: json['xpReward'] as int,
      studyPointsReward: json['studyPointsReward'] as int? ?? 0,
      status: QuestStatus.values.firstWhere(
        (e) => e.toString() == 'QuestStatus.${json['status']}',
        orElse: () => QuestStatus.active,
      ),
      startAt: (json['startAt'] as Timestamp).toDate(),
      endAt: (json['endAt'] as Timestamp).toDate(),
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      claimedAt: json['claimedAt'] != null
          ? (json['claimedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'techniqueType': techniqueType,
      'progress': progress,
      'target': target,
      'xpReward': xpReward,
      'studyPointsReward': studyPointsReward,
      'status': status.toString().split('.').last,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
    };
  }

  double get progressPercentage => (progress / target).clamp(0.0, 1.0);
  bool get isComplete => progress >= target;
  bool get isExpired => DateTime.now().isAfter(endAt);
  bool get canClaim => isComplete && status == QuestStatus.completed;
}

/// Achievement model
class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final bool unlocked;
  final DateTime? unlockedAt;
  final int xpReward;
  final String category;
  final String? badge;
  final int tier;
  final String? condition;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.unlocked,
    this.unlockedAt,
    required this.xpReward,
    required this.category,
    this.badge,
    required this.tier,
    this.condition,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String? ?? 'badge',
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? (json['unlockedAt'] as Timestamp).toDate()
          : null,
      xpReward: json['xpReward'] as int? ?? 0,
      category: json['category'] as String? ?? 'general',
      badge: json['badge'] as String?,
      tier: json['tier'] as int? ?? 1,
      condition: json['condition'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'unlocked': unlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'xpReward': xpReward,
      'category': category,
      'badge': badge,
      'tier': tier,
      'condition': condition,
    };
  }
}

/// Boost/Reward types
enum BoostType { xpMultiplier, autoComplete, breakSkip }

/// Reward/Boost model
class Reward {
  final String id;
  final String name;
  final String description;
  final BoostType type;
  final int cost; // Study Points required
  final int duration; // in minutes or uses
  final Map<String, dynamic>? effectData;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cost,
    required this.duration,
    this.effectData,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: BoostType.values.firstWhere(
        (e) => e.toString() == 'BoostType.${json['type']}',
        orElse: () => BoostType.xpMultiplier,
      ),
      cost: json['cost'] as int,
      duration: json['duration'] as int,
      effectData: json['effectData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'cost': cost,
      'duration': duration,
      'effectData': effectData,
    };
  }
}

/// Active boost instance
class ActiveBoost {
  final String id;
  final String userId;
  final String rewardId;
  final BoostType type;
  final DateTime activatedAt;
  final DateTime expiresAt;
  final Map<String, dynamic>? effectData;

  ActiveBoost({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.type,
    required this.activatedAt,
    required this.expiresAt,
    this.effectData,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => !isExpired;

  factory ActiveBoost.fromJson(Map<String, dynamic> json) {
    return ActiveBoost(
      id: json['id'] as String,
      userId: json['userId'] as String,
      rewardId: json['rewardId'] as String,
      type: BoostType.values.firstWhere(
        (e) => e.toString() == 'BoostType.${json['type']}',
      ),
      activatedAt: (json['activatedAt'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      effectData: json['effectData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'rewardId': rewardId,
      'type': type.toString().split('.').last,
      'activatedAt': Timestamp.fromDate(activatedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'effectData': effectData,
    };
  }
}
