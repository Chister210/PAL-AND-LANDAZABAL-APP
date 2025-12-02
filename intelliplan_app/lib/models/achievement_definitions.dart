/// Achievement Definitions for IntelliPlan
/// Contains all achievement categories and requirements

enum AchievementCategory {
  general,
  subject,
  pomodoro,
  spacedRepetition,
  activeRecall,
  streak,
}

class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final AchievementCategory category;
  final String condition;
  final int xpReward;
  final String? badge;
  final String iconName;
  final int tier; // 1=Beginner, 2=Intermediate, 3=Advanced/Expert

  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.condition,
    required this.xpReward,
    this.badge,
    this.iconName = 'emoji_events',
    required this.tier,
  });
}

/// All achievement definitions
class AchievementDefinitions {
  // 🧩 GENERAL PRODUCTIVITY ACHIEVEMENTS
  static const List<AchievementDefinition> general = [
    // Beginner Milestones
    AchievementDefinition(
      id: 'first_step',
      name: 'First Step',
      description: 'Create your first task',
      category: AchievementCategory.general,
      condition: 'tasks_created >= 1',
      xpReward: 50,
      iconName: 'flag',
      tier: 1,
    ),
    AchievementDefinition(
      id: 'getting_organized',
      name: 'Getting Organized',
      description: 'Create 10 tasks',
      category: AchievementCategory.general,
      condition: 'tasks_created >= 10',
      xpReward: 100,
      iconName: 'format_list_bulleted',
      tier: 1,
    ),
    AchievementDefinition(
      id: 'habit_former',
      name: 'Habit Former',
      description: 'Complete 10 tasks',
      category: AchievementCategory.general,
      condition: 'tasks_completed >= 10',
      xpReward: 120,
      iconName: 'check_circle',
      tier: 1,
    ),
    AchievementDefinition(
      id: 'consistency_starter',
      name: 'Consistency Starter',
      description: 'Log study activity 3 days in a row',
      category: AchievementCategory.general,
      condition: 'streak_days >= 3',
      xpReward: 150,
      iconName: 'trending_up',
      tier: 1,
    ),
    
    // Intermediate Milestones
    AchievementDefinition(
      id: 'task_slayer',
      name: 'Task Slayer',
      description: 'Complete 100 tasks',
      category: AchievementCategory.general,
      condition: 'tasks_completed >= 100',
      xpReward: 500,
      badge: 'Task Slayer',
      iconName: 'workspace_premium',
      tier: 2,
    ),
    AchievementDefinition(
      id: 'deadline_defender',
      name: 'Deadline Defender',
      description: 'Complete 20 tasks before their deadline',
      category: AchievementCategory.general,
      condition: 'tasks_completed_on_time >= 20',
      xpReward: 250,
      iconName: 'schedule',
      tier: 2,
    ),
    AchievementDefinition(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Start any study session before 8AM',
      category: AchievementCategory.general,
      condition: 'early_sessions >= 1',
      xpReward: 100,
      iconName: 'wb_sunny',
      tier: 2,
    ),
    AchievementDefinition(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Finish a study session after 10PM',
      category: AchievementCategory.general,
      condition: 'late_sessions >= 1',
      xpReward: 100,
      iconName: 'nightlight',
      tier: 2,
    ),
    
    // Advanced / Hardcore
    AchievementDefinition(
      id: 'all_rounder',
      name: 'All-Rounder',
      description: 'Use all 3 study techniques at least once',
      category: AchievementCategory.general,
      condition: 'pomodoro_used && spaced_repetition_used && active_recall_used',
      xpReward: 300,
      badge: 'All-Rounder',
      iconName: 'auto_awesome',
      tier: 3,
    ),
    AchievementDefinition(
      id: 'marathon_learner',
      name: 'Marathon Learner',
      description: 'Study for a total of 12 hours in a week',
      category: AchievementCategory.general,
      condition: 'weekly_study_minutes >= 720',
      xpReward: 400,
      iconName: 'timer',
      tier: 3,
    ),
    AchievementDefinition(
      id: 'academic_titan',
      name: 'Academic Titan',
      description: 'Complete 300 tasks total',
      category: AchievementCategory.general,
      condition: 'tasks_completed >= 300',
      xpReward: 1000,
      badge: 'Academic Titan',
      iconName: 'military_tech',
      tier: 3,
    ),
  ];

  // 📚 SUBJECT-BASED ACHIEVEMENTS
  static const List<AchievementDefinition> subject = [
    AchievementDefinition(
      id: 'course_starter',
      name: 'Course Starter',
      description: 'Add your first subject',
      category: AchievementCategory.subject,
      condition: 'subjects_added >= 1',
      xpReward: 50,
      iconName: 'school',
      tier: 1,
    ),
    AchievementDefinition(
      id: 'course_loader',
      name: 'Course Loader',
      description: 'Add 5 subjects',
      category: AchievementCategory.subject,
      condition: 'subjects_added >= 5',
      xpReward: 120,
      iconName: 'library_books',
      tier: 1,
    ),
    AchievementDefinition(
      id: 'planner_master',
      name: 'Planner Master',
      description: 'Assign tasks to 5 different subjects',
      category: AchievementCategory.subject,
      condition: 'subjects_with_tasks >= 5',
      xpReward: 200,
      badge: 'Planner Master',
      iconName: 'calendar_today',
      tier: 2,
    ),
    AchievementDefinition(
      id: 'major_achiever',
      name: 'Major Achiever',
      description: 'Complete 20 tasks in a Major Subject',
      category: AchievementCategory.subject,
      condition: 'major_subject_tasks >= 20',
      xpReward: 300,
      iconName: 'star',
      tier: 2,
    ),
    AchievementDefinition(
      id: 'minor_specialist',
      name: 'Minor Specialist',
      description: 'Complete 20 tasks in a Minor Subject',
      category: AchievementCategory.subject,
      condition: 'minor_subject_tasks >= 20',
      xpReward: 300,
      iconName: 'star_half',
      tier: 2,
    ),
  ];

  // ⏱️ POMODORO ACHIEVEMENTS
  static const List<AchievementDefinition> pomodoro = [
    // Beginner
    AchievementDefinition(
      id: 'focus_initiate',
      name: 'Focus Initiate',
      description: 'Complete 1 Pomodoro session',
      category: AchievementCategory.pomodoro,
      condition: 'pomodoro_sessions >= 1',
      xpReward: 50,
      iconName: 'timer',
      tier: 1,
    ),
    AchievementDefinition(
      id: 'steady_worker',
      name: 'Steady Worker',
      description: 'Complete 10 Pomodoro sessions',
      category: AchievementCategory.pomodoro,
      condition: 'pomodoro_sessions >= 10',
      xpReward: 150,
      iconName: 'access_time',
      tier: 1,
    ),
    
    // Intermediate
    AchievementDefinition(
      id: 'time_manager',
      name: 'Time Manager',
      description: 'Complete 25 Pomodoro sessions',
      category: AchievementCategory.pomodoro,
      condition: 'pomodoro_sessions >= 25',
      xpReward: 250,
      iconName: 'schedule',
      tier: 2,
    ),
    AchievementDefinition(
      id: 'focus_hero',
      name: 'Focus Hero',
      description: 'Complete 50 Pomodoro sessions',
      category: AchievementCategory.pomodoro,
      condition: 'pomodoro_sessions >= 50',
      xpReward: 400,
      iconName: 'local_fire_department',
      tier: 2,
    ),
    
    // Pro
    AchievementDefinition(
      id: 'deep_work_champion',
      name: 'Deep Work Champion',
      description: 'Complete 4 Pomodoros in one sitting',
      category: AchievementCategory.pomodoro,
      condition: 'consecutive_pomodoros >= 4',
      xpReward: 500,
      badge: 'Deep Work Champion',
      iconName: 'psychology',
      tier: 3,
    ),
    AchievementDefinition(
      id: 'iron_focus',
      name: 'Iron Focus',
      description: 'Study 2+ hours (Pomodoro accumulated) in one day',
      category: AchievementCategory.pomodoro,
      condition: 'daily_pomodoro_minutes >= 120',
      xpReward: 600,
      iconName: 'shield',
      tier: 3,
    ),
  ];

  // 🔁 SPACED REPETITION ACHIEVEMENTS
  static const List<AchievementDefinition> spacedRepetition = [
    // Beginner
    AchievementDefinition(
      id: 'memory_novice',
      name: 'Memory Novice',
      description: 'Review 10 flashcards',
      category: AchievementCategory.spacedRepetition,
      condition: 'flashcards_reviewed >= 10',
      xpReward: 80,
      iconName: 'style',
      tier: 1,
    ),
    AchievementDefinition(
      id: 'spacing_starter',
      name: 'Spacing Starter',
      description: 'Review 1 flashcard on its reminder day',
      category: AchievementCategory.spacedRepetition,
      condition: 'on_time_reviews >= 1',
      xpReward: 50,
      iconName: 'event_available',
      tier: 1,
    ),
    
    // Intermediate
    AchievementDefinition(
      id: 'memory_builder',
      name: 'Memory Builder',
      description: 'Review 200 flashcards',
      category: AchievementCategory.spacedRepetition,
      condition: 'flashcards_reviewed >= 200',
      xpReward: 450,
      badge: 'Memory Builder',
      iconName: 'psychology_alt',
      tier: 2,
    ),
    AchievementDefinition(
      id: 'recall_loop',
      name: 'Recall Loop',
      description: 'Review the same flashcard 5 times',
      category: AchievementCategory.spacedRepetition,
      condition: 'max_card_reviews >= 5',
      xpReward: 120,
      iconName: 'repeat',
      tier: 2,
    ),
    
    // Expert
    AchievementDefinition(
      id: 'spacing_master',
      name: 'Spacing Master',
      description: 'Maintain a 7-day SR streak',
      category: AchievementCategory.spacedRepetition,
      condition: 'sr_streak_days >= 7',
      xpReward: 600,
      badge: 'Spacing Master',
      iconName: 'workspace_premium',
      tier: 3,
    ),
    AchievementDefinition(
      id: 'flashcard_typhoon',
      name: 'Flashcard Typhoon',
      description: 'Review 500 cards total',
      category: AchievementCategory.spacedRepetition,
      condition: 'flashcards_reviewed >= 500',
      xpReward: 900,
      iconName: 'storm',
      tier: 3,
    ),
  ];

  // 🎯 ACTIVE RECALL ACHIEVEMENTS
  static const List<AchievementDefinition> activeRecall = [
    // Beginner
    AchievementDefinition(
      id: 'recall_rookie',
      name: 'Recall Rookie',
      description: 'Complete 5 recall questions',
      category: AchievementCategory.activeRecall,
      condition: 'recall_questions >= 5',
      xpReward: 80,
      iconName: 'quiz',
      tier: 1,
    ),
    AchievementDefinition(
      id: 'first_challenge',
      name: 'First Challenge',
      description: 'Score above 60% accuracy',
      category: AchievementCategory.activeRecall,
      condition: 'recall_accuracy >= 60',
      xpReward: 120,
      iconName: 'fact_check',
      tier: 1,
    ),
    
    // Intermediate
    AchievementDefinition(
      id: 'recall_champion',
      name: 'Recall Champion',
      description: 'Answer 100 recall prompts',
      category: AchievementCategory.activeRecall,
      condition: 'recall_questions >= 100',
      xpReward: 450,
      badge: 'Recall Champion',
      iconName: 'emoji_events',
      tier: 2,
    ),
    AchievementDefinition(
      id: 'sharp_mind',
      name: 'Sharp Mind',
      description: 'Score 80%+ accuracy in one session',
      category: AchievementCategory.activeRecall,
      condition: 'recall_session_accuracy >= 80',
      xpReward: 300,
      iconName: 'lightbulb',
      tier: 2,
    ),
    
    // Expert
    AchievementDefinition(
      id: 'memory_gladiator',
      name: 'Memory Gladiator',
      description: 'Score 90%+ accuracy 3 times',
      category: AchievementCategory.activeRecall,
      condition: 'high_accuracy_sessions >= 3',
      xpReward: 600,
      badge: 'Memory Gladiator',
      iconName: 'military_tech',
      tier: 3,
    ),
    AchievementDefinition(
      id: 'recall_beast',
      name: 'Recall Beast',
      description: 'Answer 300 recall questions',
      category: AchievementCategory.activeRecall,
      condition: 'recall_questions >= 300',
      xpReward: 900,
      iconName: 'rocket_launch',
      tier: 3,
    ),
  ];

  // 🔥 STREAK ACHIEVEMENTS
  static const List<AchievementDefinition> streak = [
    AchievementDefinition(
      id: 'streak_starter',
      name: 'Streak Starter',
      description: '3-day streak',
      category: AchievementCategory.streak,
      condition: 'streak_days >= 3',
      xpReward: 100,
      iconName: 'local_fire_department',
      tier: 1,
    ),
    AchievementDefinition(
      id: 'streak_builder',
      name: 'Streak Builder',
      description: '7-day streak',
      category: AchievementCategory.streak,
      condition: 'streak_days >= 7',
      xpReward: 250,
      iconName: 'whatshot',
      tier: 2,
    ),
    AchievementDefinition(
      id: 'study_warrior',
      name: 'Study Warrior',
      description: '14-day streak',
      category: AchievementCategory.streak,
      condition: 'streak_days >= 14',
      xpReward: 500,
      badge: 'Study Warrior',
      iconName: 'local_fire_department',
      tier: 2,
    ),
    AchievementDefinition(
      id: 'master_of_discipline',
      name: 'Master of Discipline',
      description: '30-day streak',
      category: AchievementCategory.streak,
      condition: 'streak_days >= 30',
      xpReward: 1000,
      badge: 'Master of Discipline',
      iconName: 'workspace_premium',
      tier: 3,
    ),
  ];

  /// Get all achievements
  static List<AchievementDefinition> getAll() {
    return [
      ...general,
      ...subject,
      ...pomodoro,
      ...spacedRepetition,
      ...activeRecall,
      ...streak,
    ];
  }

  /// Get achievements by category
  static List<AchievementDefinition> getByCategory(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.general:
        return general;
      case AchievementCategory.subject:
        return subject;
      case AchievementCategory.pomodoro:
        return pomodoro;
      case AchievementCategory.spacedRepetition:
        return spacedRepetition;
      case AchievementCategory.activeRecall:
        return activeRecall;
      case AchievementCategory.streak:
        return streak;
    }
  }

  /// Get category name
  static String getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.general:
        return 'General Productivity';
      case AchievementCategory.subject:
        return 'Subject-Based';
      case AchievementCategory.pomodoro:
        return 'Pomodoro';
      case AchievementCategory.spacedRepetition:
        return 'Spaced Repetition';
      case AchievementCategory.activeRecall:
        return 'Active Recall';
      case AchievementCategory.streak:
        return 'Streak';
    }
  }

  /// Get category icon
  static String getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.general:
        return '🧩';
      case AchievementCategory.subject:
        return '📚';
      case AchievementCategory.pomodoro:
        return '⏱️';
      case AchievementCategory.spacedRepetition:
        return '🔁';
      case AchievementCategory.activeRecall:
        return '🎯';
      case AchievementCategory.streak:
        return '🔥';
    }
  }
}
