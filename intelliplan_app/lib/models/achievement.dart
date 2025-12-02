class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final int pointsRequired;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final AchievementCategory category;
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.pointsRequired,
    required this.isUnlocked,
    this.unlockedAt,
    required this.category,
  });
  
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconPath: json['iconPath'],
      pointsRequired: json['pointsRequired'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt']) 
          : null,
      category: AchievementCategory.values.firstWhere(
        (e) => e.toString() == 'AchievementCategory.${json['category']}',
        orElse: () => AchievementCategory.general,
      ),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'pointsRequired': pointsRequired,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'category': category.toString().split('.').last,
    };
  }
}

enum AchievementCategory {
  general,
  subject,
  pomodoro,
  spacedRepetition,
  activeRecall,
  streak,
}
