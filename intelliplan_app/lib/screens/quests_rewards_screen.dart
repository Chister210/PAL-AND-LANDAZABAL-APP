import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gamification.dart';
import '../services/gamification_service.dart';

/// Quests & Rewards Screen - Player stats, quests, achievements, rewards store
class QuestsRewardsScreen extends StatefulWidget {
  const QuestsRewardsScreen({Key? key}) : super(key: key);

  @override
  State<QuestsRewardsScreen> createState() => _QuestsRewardsScreenState();
}

class _QuestsRewardsScreenState extends State<QuestsRewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quests & Rewards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.flag), text: 'Quests'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
            Tab(icon: Icon(Icons.shop), text: 'Rewards'),
          ],
        ),
      ),
      body: Column(
        children: [
          const _PlayerSummaryCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _QuestsTab(),
                _AchievementsTab(),
                _RewardsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Player summary card - Level, XP, Title, Streak
class _PlayerSummaryCard extends StatelessWidget {
  const _PlayerSummaryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationService>(
      builder: (context, gamification, _) {
        final profile = gamification.userGamification;
        
        if (profile == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Level and Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${profile.level}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                  // Streak
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.streakDays} days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // XP Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'XP: ${profile.xp} / ${profile.xpForNextLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${(profile.xpProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: profile.xpProgress,
                      minHeight: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Study Points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${profile.studyPoints} Study Points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${profile.totalSessionsCompleted} sessions',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Quests Tab
class _QuestsTab extends StatelessWidget {
  const _QuestsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationService>(
      builder: (context, gamification, _) {
        final quests = gamification.activeQuests;
        
        if (quests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flag,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active quests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('New quests will appear daily'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    gamification.createDailyQuests();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate Quests'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quests.length,
          itemBuilder: (context, index) => _QuestCard(quest: quests[index]),
        );
      },
    );
  }
}

/// Quest Card
class _QuestCard extends StatelessWidget {
  final Quest quest;

  const _QuestCard({Key? key, required this.quest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = quest.progress / quest.target;
    final isComplete = quest.status == QuestStatus.completed;
    final isClaimed = quest.status == QuestStatus.claimed;
    final isExpired = quest.isExpired;

    Color getQuestColor() {
      if (isClaimed) return Colors.grey;
      if (isExpired) return Colors.red;
      if (isComplete) return Colors.green;
      return Theme.of(context).colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getQuestIcon(),
                  color: getQuestColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: isClaimed ? TextDecoration.lineThrough : null,
                            ),
                      ),
                      Text(
                        quest.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${quest.progress} / ${quest.target}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (isExpired)
                      const Text(
                        'EXPIRED',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    else if (isClaimed)
                      const Text(
                        'CLAIMED',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(getQuestColor()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Rewards and Claim Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '+${quest.xpReward} XP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '+${quest.studyPointsReward} SP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (quest.canClaim)
                  ElevatedButton(
                    onPressed: () {
                      context.read<GamificationService>().claimQuestReward(quest.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🎁 Claimed +${quest.xpReward} XP, +${quest.studyPointsReward} SP!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Claim'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getQuestIcon() {
    switch (quest.type) {
      case QuestType.general:
        return Icons.check_circle;
      case QuestType.daily:
        return Icons.calendar_today;
      case QuestType.weekly:
        return Icons.calendar_view_week;
      case QuestType.techniqueSpecific:
        return Icons.school;
    }
  }
}

/// Achievements Tab
class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationService>(
      builder: (context, gamification, _) {
        final achievements = gamification.achievements;
        
        if (achievements.isEmpty) {
          return const Center(
            child: Text('No achievements yet'),
          );
        }

        final unlocked = achievements.where((a) => a.unlocked).toList();
        final locked = achievements.where((a) => !a.unlocked).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (unlocked.isNotEmpty) ...[
              Text(
                'Unlocked (${unlocked.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: unlocked.length,
                itemBuilder: (context, index) => _AchievementCard(achievement: unlocked[index]),
              ),
            ],
            if (locked.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Locked (${locked.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: locked.length,
                itemBuilder: (context, index) => _AchievementCard(achievement: locked[index]),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Achievement Card
class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({Key? key, required this.achievement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(achievement.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.description),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('+${achievement.xpReward} XP'),
                  ],
                ),
                if (achievement.unlocked && achievement.unlockedAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Unlocked: ${achievement.unlockedAt!.toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Card(
        color: achievement.unlocked ? null : Colors.grey[300],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 40,
                color: achievement.unlocked ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                achievement.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: achievement.unlocked ? null : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rewards Tab (Shop)
class _RewardsTab extends StatelessWidget {
  const _RewardsTab({Key? key}) : super(key: key);

  // Sample rewards data
  static final List<Reward> _sampleRewards = [
    Reward(
      id: 'xp_boost_10',
      name: '+10% XP Boost',
      description: 'Earn 10% more XP for the next 24 hours',
      type: BoostType.xpMultiplier,
      cost: 50,
      duration: 1440, // 24 hours
      effectData: {'multiplier': 1.1},
    ),
    Reward(
      id: 'xp_boost_25',
      name: '+25% XP Boost',
      description: 'Earn 25% more XP for the next 12 hours',
      type: BoostType.xpMultiplier,
      cost: 100,
      duration: 720, // 12 hours
      effectData: {'multiplier': 1.25},
    ),
    Reward(
      id: 'break_skip',
      name: 'Break Skip Token',
      description: 'Skip one break in Pomodoro session',
      type: BoostType.breakSkip,
      cost: 30,
      duration: 0,
      effectData: {'uses': 1},
    ),
    Reward(
      id: 'auto_complete',
      name: 'Auto-Complete Token',
      description: 'Auto-complete one low-priority task',
      type: BoostType.autoComplete,
      cost: 40,
      duration: 0,
      effectData: {'uses': 1},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationService>(
      builder: (context, gamification, _) {
        final studyPoints = gamification.userGamification?.studyPoints ?? 0;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active Boosts
            if (gamification.activeBoosts.isNotEmpty) ...[
              Text(
                'Active Boosts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...gamification.activeBoosts.map((boost) => _ActiveBoostCard(boost: boost)),
              const SizedBox(height: 24),
            ],
            
            // Shop
            Text(
              'Rewards Shop',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._sampleRewards.map((reward) => _RewardCard(
              reward: reward,
              studyPoints: studyPoints,
            )),
          ],
        );
      },
    );
  }
}

/// Active Boost Card
class _ActiveBoostCard extends StatelessWidget {
  final ActiveBoost boost;

  const _ActiveBoostCard({Key? key, required this.boost}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remaining = boost.expiresAt.difference(DateTime.now());
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    return Card(
      color: Colors.green.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.flash_on, color: Colors.green),
        title: Text(_getBoostName(boost.type)),
        subtitle: Text('Expires in ${hours}h ${minutes}m'),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  String _getBoostName(BoostType type) {
    switch (type) {
      case BoostType.xpMultiplier:
        final multiplier = boost.effectData?['multiplier'] as double? ?? 1.0;
        return '${((multiplier - 1) * 100).toInt()}% XP Boost';
      case BoostType.breakSkip:
        return 'Break Skip';
      case BoostType.autoComplete:
        return 'Auto-Complete';
    }
  }
}

/// Reward Card
class _RewardCard extends StatelessWidget {
  final Reward reward;
  final int studyPoints;

  const _RewardCard({Key? key, required this.reward, required this.studyPoints}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canAfford = studyPoints >= reward.cost;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getRewardIcon(),
          color: canAfford ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        title: Text(reward.name),
        subtitle: Text(reward.description),
        trailing: ElevatedButton(
          onPressed: canAfford
              ? () async {
                  final success = await context.read<GamificationService>().purchaseReward(reward);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🚀 Purchased ${reward.name}!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              : null,
          child: Text('${reward.cost} SP'),
        ),
      ),
    );
  }

  IconData _getRewardIcon() {
    switch (reward.type) {
      case BoostType.xpMultiplier:
        return Icons.trending_up;
      case BoostType.breakSkip:
        return Icons.fast_forward;
      case BoostType.autoComplete:
        return Icons.check_circle_outline;
    }
  }
}
