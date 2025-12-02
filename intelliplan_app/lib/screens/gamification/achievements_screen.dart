import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/gamification_service.dart';
import '../../models/achievement_definitions.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementCategory? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    try {
      // Achievements are already loaded by GamificationService
      // Just wait a moment to ensure they're ready
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Achievements'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final gamificationService = context.watch<GamificationService>();
    final achievements = gamificationService.achievements;
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Achievements'),
        actions: [
          PopupMenuButton<AchievementCategory?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Categories'),
              ),
              ...AchievementCategory.values.map((category) {
                return PopupMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Text(AchievementDefinitions.getCategoryIcon(category)),
                      const SizedBox(width: 8),
                      Text(AchievementDefinitions.getCategoryName(category)),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats Header
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events,
                      size: 64, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    '$unlockedCount / ${achievements.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Achievements Unlocked',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (_selectedCategory != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${AchievementDefinitions.getCategoryIcon(_selectedCategory!)} ${AchievementDefinitions.getCategoryName(_selectedCategory!)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Tabs
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).primaryColor,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                      tabs: const [
                        Tab(text: 'Unlocked'),
                        Tab(text: 'Locked'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Unlocked Achievements
                          _buildAchievementsList(
                            _filterAchievements(achievements.where((a) => a.unlocked).toList()),
                            isUnlocked: true,
                          ),
                          // Locked Achievements
                          _buildAchievementsList(
                            _filterAchievements(achievements.where((a) => !a.unlocked).toList()),
                            isUnlocked: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _filterAchievements(List<dynamic> achievements) {
    if (_selectedCategory == null) return achievements;
    
    return achievements.where((a) {
      // Get category directly from Achievement model
      final categoryStr = a.category as String? ?? 'general';
      final selectedCategoryStr = _selectedCategory.toString().split('.').last;
      
      return categoryStr == selectedCategoryStr;
    }).toList();
  }

  Widget _buildAchievementsList(
    List<dynamic> achievements, {
    required bool isUnlocked,
  }) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? Icons.emoji_events_outlined : Icons.lock_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isUnlocked
                  ? 'No achievements unlocked yet.\nKeep learning to earn more!'
                  : _selectedCategory != null
                      ? 'All achievements in this category unlocked!\nYou\'re amazing!'
                      : 'All achievements unlocked!\nYou\'re amazing!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group by category
    final Map<String, List<dynamic>> grouped = {};
    for (var achievement in achievements) {
      final category = achievement.category as String? ?? 'general';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(achievement);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final categoryKey = grouped.keys.elementAt(index);
        final categoryAchievements = grouped[categoryKey]!;
        
        // Get category enum
        AchievementCategory category;
        try {
          category = AchievementCategory.values.firstWhere(
            (e) => e.toString().split('.').last == categoryKey,
          );
        } catch (e) {
          category = AchievementCategory.general;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    AchievementDefinitions.getCategoryIcon(category),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AchievementDefinitions.getCategoryName(category),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${categoryAchievements.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Achievements in this category
            ...categoryAchievements.map((achievement) => _buildAchievementCard(
              achievement,
              isUnlocked: isUnlocked,
            )).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAchievementCard(dynamic achievement, {required bool isUnlocked}) {
    final data = achievement.toJson();
    final badge = data['badge'] as String?;
    final tier = data['tier'] as int? ?? 1;
    final xpReward = achievement.xpReward;
    
    Color getTierColor() {
      switch (tier) {
        case 1:
          return Colors.grey;
        case 2:
          return const Color(0xFF4CAF50);
        case 3:
          return const Color(0xFFFFB800);
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showAchievementDetail(achievement, isUnlocked: isUnlocked),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? getTierColor().withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: badge != null && isUnlocked
                      ? Border.all(color: getTierColor(), width: 2)
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getIconData(achievement.iconName),
                        size: 32,
                        color: isUnlocked ? getTierColor() : Colors.grey,
                      ),
                    ),
                    if (badge != null && isUnlocked)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: getTierColor(),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isUnlocked ? null : Colors.grey,
                            ),
                          ),
                        ),
                        if (badge != null && isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: getTierColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'BADGE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: getTierColor(),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        color: isUnlocked ? Colors.grey[700] : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: isUnlocked
                              ? const Color(0xFFFFB800)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+$xpReward XP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? null : Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        if (isUnlocked && achievement.unlockedAt != null)
                          Text(
                            _formatDate(achievement.unlockedAt!),
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementDetail(dynamic achievement, {required bool isUnlocked}) {
    final data = achievement.toJson();
    final badge = data['badge'] as String?;
    final tier = data['tier'] as int? ?? 1;
    final condition = data['condition'] as String? ?? '';
    final xpReward = achievement.xpReward;
    
    Color getTierColor() {
      switch (tier) {
        case 1:
          return Colors.grey;
        case 2:
          return const Color(0xFF4CAF50);
        case 3:
          return const Color(0xFFFFB800);
        default:
          return Colors.grey;
      }
    }

    String getTierName() {
      switch (tier) {
        case 1:
          return 'Beginner';
        case 2:
          return 'Intermediate';
        case 3:
          return 'Expert';
        default:
          return 'Unknown';
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? getTierColor().withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: badge != null && isUnlocked
                      ? Border.all(color: getTierColor(), width: 3)
                      : null,
                ),
                child: Icon(
                  _getIconData(achievement.iconName),
                  size: 50,
                  color: isUnlocked ? getTierColor() : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                achievement.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Tier Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: getTierColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getTierName().toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: getTierColor(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 16,
                  color: isUnlocked ? Colors.grey[700] : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Achievement Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Row(
                      children: [
                        const Icon(Icons.category, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Category',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AchievementDefinitions.getCategoryName(
                        _getCategoryFromString(data['category'] as String? ?? 'general')
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Reward
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFB800).withOpacity(0.2),
                      const Color(0xFFFF6B00).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFB800),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+$xpReward XP',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB800),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.verified,
                        color: Color(0xFFFFB800),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isUnlocked && achievement.unlockedAt != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocked on ${_formatDate(achievement.unlockedAt!)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // Close Button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'flag':
        return Icons.flag;
      case 'format_list_bulleted':
        return Icons.format_list_bulleted;
      case 'check_circle':
        return Icons.check_circle;
      case 'trending_up':
        return Icons.trending_up;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'schedule':
        return Icons.schedule;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'nightlight':
        return Icons.nightlight;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'timer':
        return Icons.timer;
      case 'military_tech':
        return Icons.military_tech;
      case 'school':
        return Icons.school;
      case 'library_books':
        return Icons.library_books;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'star':
        return Icons.star;
      case 'star_half':
        return Icons.star_half;
      case 'access_time':
        return Icons.access_time;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'psychology':
        return Icons.psychology;
      case 'shield':
        return Icons.shield;
      case 'style':
        return Icons.style;
      case 'event_available':
        return Icons.event_available;
      case 'psychology_alt':
        return Icons.psychology_alt;
      case 'repeat':
        return Icons.repeat;
      case 'storm':
        return Icons.storm;
      case 'quiz':
        return Icons.quiz;
      case 'fact_check':
        return Icons.fact_check;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'whatshot':
        return Icons.whatshot;
      default:
        return Icons.emoji_events;
    }
  }

  String _getHowToGet(String condition) {
    // Parse condition into human-readable format
    if (condition.contains('tasks_created >= 1')) return 'Create your first task in the planner';
    if (condition.contains('tasks_created >= 10')) return 'Create a total of 10 tasks';
    if (condition.contains('tasks_completed >= 10')) return 'Complete 10 tasks';
    if (condition.contains('tasks_completed >= 100')) return 'Complete 100 tasks total';
    if (condition.contains('tasks_completed >= 300')) return 'Complete 300 tasks total';
    if (condition.contains('tasks_completed_on_time >= 20')) return 'Complete 20 tasks before their deadline';
    if (condition.contains('streak_days >= 3')) return 'Study for 3 consecutive days';
    if (condition.contains('streak_days >= 7')) return 'Maintain a 7-day study streak';
    if (condition.contains('streak_days >= 14')) return 'Maintain a 14-day study streak';
    if (condition.contains('streak_days >= 30')) return 'Maintain a 30-day study streak';
    if (condition.contains('early_sessions >= 1')) return 'Start a study session before 8:00 AM';
    if (condition.contains('late_sessions >= 1')) return 'Complete a study session after 10:00 PM';
    if (condition.contains('pomodoro_used && spaced_repetition_used && active_recall_used')) {
      return 'Try all three study techniques: Pomodoro, Spaced Repetition, and Active Recall';
    }
    if (condition.contains('weekly_study_minutes >= 720')) return 'Study for 12 hours total in one week';
    if (condition.contains('subjects_added >= 1')) return 'Add your first subject';
    if (condition.contains('subjects_added >= 5')) return 'Add 5 different subjects';
    if (condition.contains('pomodoro_sessions >= 1')) return 'Complete 1 Pomodoro session';
    if (condition.contains('pomodoro_sessions >= 10')) return 'Complete 10 Pomodoro sessions';
    if (condition.contains('pomodoro_sessions >= 25')) return 'Complete 25 Pomodoro sessions';
    if (condition.contains('pomodoro_sessions >= 50')) return 'Complete 50 Pomodoro sessions';
    if (condition.contains('consecutive_pomodoros >= 4')) return 'Complete 4 Pomodoro sessions in a row without long breaks';
    if (condition.contains('daily_pomodoro_minutes >= 120')) return 'Study for 2+ hours using Pomodoro in a single day';
    if (condition.contains('flashcards_reviewed >= 10')) return 'Review 10 flashcards';
    if (condition.contains('flashcards_reviewed >= 200')) return 'Review 200 flashcards total';
    if (condition.contains('flashcards_reviewed >= 500')) return 'Review 500 flashcards total';
    if (condition.contains('on_time_reviews >= 1')) return 'Review a flashcard on its scheduled reminder day';
    if (condition.contains('recall_questions >= 5')) return 'Answer 5 Active Recall questions';
    if (condition.contains('recall_questions >= 100')) return 'Answer 100 Active Recall questions';
    if (condition.contains('recall_questions >= 300')) return 'Answer 300 Active Recall questions';
    if (condition.contains('recall_accuracy >= 60')) return 'Score 60% or higher accuracy in an Active Recall session';
    if (condition.contains('recall_session_accuracy >= 80')) return 'Score 80% or higher accuracy in a single session';
    if (condition.contains('high_accuracy_sessions >= 3')) return 'Score 90%+ accuracy in 3 different Active Recall sessions';
    
    return condition;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  AchievementCategory _getCategoryFromString(String categoryStr) {
    try {
      return AchievementCategory.values.firstWhere(
        (e) => e.toString().split('.').last == categoryStr,
      );
    } catch (e) {
      return AchievementCategory.general;
    }
  }
}
