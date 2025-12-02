# 🚀 Quick Start Guide - Gamification System

## For Developers: How to Use the New Features

### 1. Initialize Services (Already Done in main.dart)

Services are auto-initialized with proper dependencies:
```dart
// GamificationService is independent
ChangeNotifierProvider(create: (_) => GamificationService())

// These depend on GamificationService
ChangeNotifierProxyProvider<GamificationService, PomodoroService>(...)
ChangeNotifierProxyProvider<GamificationService, ActiveRecallService>(...)
```

---

### 2. Award XP from Anywhere

```dart
// Get service from context
final gamification = context.read<GamificationService>();

// Award XP
await gamification.awardXP(100, source: 'Task Completed');

// Award Study Points
await gamification.awardStudyPoints(5);

// Update streak (call once per study session)
await gamification.updateStreak();
```

---

### 3. Track Quest Progress

```dart
final gamification = context.read<GamificationService>();

// Update quest progress
await gamification.updateQuestProgress('pomodoro', increment: 1);
await gamification.updateQuestProgress('spaced_repetition', increment: 1);
await gamification.updateQuestProgress('active_recall', increment: 1);
await gamification.updateQuestProgress('general', increment: 1);
```

---

### 4. Display User Progress

```dart
Consumer<GamificationService>(
  builder: (context, gamification, _) {
    final profile = gamification.userGamification;
    
    return Column(
      children: [
        Text('Level ${profile.level}'),
        Text(profile.title),
        LinearProgressIndicator(value: profile.xpProgress),
        Text('${profile.xp} / ${profile.xpForNextLevel} XP'),
        Text('Streak: ${profile.streakDays} days'),
        Text('Study Points: ${profile.studyPoints}'),
      ],
    );
  },
)
```

---

### 5. Navigate to Gamification Screens

```dart
// Open Quests & Rewards
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const QuestsRewardsScreen()),
);

// Open Active Recall
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ActiveRecallScreen()),
);
```

---

### 6. Check Active Boosts

```dart
final gamification = context.read<GamificationService>();

// Check if user has specific boost
if (gamification.hasActiveBoost(BoostType.xpMultiplier)) {
  // XP boost is active
}

// Get all active boosts
final boosts = gamification.activeBoosts;
for (var boost in boosts) {
  if (boost.isActive) {
    // Boost is still valid
  }
}
```

---

### 7. Active Recall Session Flow

```dart
final activeRecall = context.read<ActiveRecallService>();

// Start session
await activeRecall.startSession(questionCount: 10);

// During session
final question = activeRecall.getCurrentQuestion();
final attempt = await activeRecall.submitAnswer(userAnswer);

// Check progress
final progress = activeRecall.getSessionProgress();
final isComplete = activeRecall.isSessionComplete();

// End session
await activeRecall.endSession();
```

---

### 8. Add Questions to Active Recall

```dart
final activeRecall = context.read<ActiveRecallService>();

await activeRecall.addQuestion(
  question: 'What is the capital of France?',
  correctAnswer: 'Paris',
  topic: 'Geography',
  difficulty: 3,
);
```

---

### 9. Generate Daily Quests

```dart
final gamification = context.read<GamificationService>();

// Generate new daily quests
await gamification.createDailyQuests();
```

---

### 10. Claim Quest Rewards

```dart
final gamification = context.read<GamificationService>();

// Claim a quest
final success = await gamification.claimQuestReward(questId);

if (success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('🎁 Rewards claimed!')),
  );
}
```

---

## 📊 Data Access Patterns

### Read User Progress
```dart
final profile = gamification.userGamification;
print('Level: ${profile?.level}');
print('XP: ${profile?.xp}');
print('Title: ${profile?.title}');
```

### Get Active Quests
```dart
final quests = gamification.activeQuests;
for (var quest in quests) {
  print('${quest.name}: ${quest.progress}/${quest.target}');
}
```

### Get Achievements
```dart
final achievements = gamification.achievements;
final unlocked = achievements.where((a) => a.unlocked).length;
print('Unlocked: $unlocked / ${achievements.length}');
```

---

## 🎨 UI Widgets Ready to Use

### Gamification Card (Dashboard)
Already implemented in `dashboard_screen.dart`

### Quests & Rewards Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const QuestsRewardsScreen()),
);
```

### Active Recall Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ActiveRecallScreen()),
);
```

---

## 🔄 Service Lifecycle

### On App Start
```dart
final userId = authService.currentUser!.id;
await gamificationService.initializeForUser(userId);
await activeRecallService.initializeForUser(userId);
```

### On Study Session Complete
```dart
await gamificationService.awardXP(100, source: 'Study Session');
await gamificationService.updateStreak();
await gamificationService.incrementSessionCount();
await gamificationService.updateQuestProgress('general');
```

### On Pomodoro Complete
```dart
// Automatically handled by PomodoroService
// Awards 100 XP + consecutive bonus
// Updates quest progress
// Awards Study Points
```

### On Flashcard Review
```dart
// Automatically handled by SpacedRepetitionService
// Awards 10-20 XP based on difficulty
// Updates quest progress
```

---

## 🐛 Common Issues & Solutions

### Issue: Services not initialized
**Solution**: Call `initializeForUser(userId)` after login

### Issue: XP not awarding
**Solution**: Check that GamificationService is passed to other services

### Issue: Quests not appearing
**Solution**: Call `createDailyQuests()` on first use

### Issue: Progress bar not updating
**Solution**: Wrap widget in `Consumer<GamificationService>`

---

## 📱 Testing Checklist

```dart
// Test XP Award
await gamification.awardXP(100, source: 'Test');
assert(profile.xp == 100);

// Test Level Up
await gamification.awardXP(200, source: 'Test'); // Should level up at 100
assert(profile.level == 2);

// Test Quest Progress
await gamification.createDailyQuests();
await gamification.updateQuestProgress('general', increment: 1);
// Check quest progress

// Test Active Recall
await activeRecall.addQuestion(
  question: 'Test?',
  correctAnswer: 'Answer',
);
await activeRecall.startSession();
await activeRecall.submitAnswer('Answer');
// Check XP awarded
```

---

## 🎯 Best Practices

1. **Always check for null**: `profile != null` before accessing properties
2. **Use Consumer**: Wrap UI in `Consumer<GamificationService>` for auto-updates
3. **Await async calls**: Don't forget `await` on service methods
4. **Error handling**: Wrap service calls in try-catch
5. **Initialize on login**: Call `initializeForUser()` after authentication
6. **Update quests**: Call `updateQuestProgress()` after relevant actions
7. **Show feedback**: Use SnackBars to confirm XP awards and level ups

---

## 📚 Key Files Reference

| Component | File Path |
|-----------|-----------|
| Models | `lib/models/gamification.dart` |
| Models | `lib/models/active_recall.dart` |
| Service | `lib/services/gamification_service.dart` |
| Service | `lib/services/active_recall_service.dart` |
| UI | `lib/screens/quests_rewards_screen.dart` |
| UI | `lib/screens/active_recall_screen.dart` |
| Enhanced | `lib/services/pomodoro_service.dart` |
| Enhanced | `lib/services/spaced_repetition_service.dart` |
| Dashboard | `lib/screens/dashboard/dashboard_screen.dart` |

---

## 🚀 Quick Commands

```dart
// Award XP
gamification.awardXP(100, source: 'Action');

// Level up check (automatic)
// Level ups happen automatically in awardXP()

// Update streak
gamification.updateStreak();

// Generate quests
gamification.createDailyQuests();

// Claim quest
gamification.claimQuestReward(questId);

// Purchase reward
gamification.purchaseReward(reward);

// Start Active Recall
activeRecall.startSession();

// Submit answer
activeRecall.submitAnswer(answer);
```

---

*Quick Reference for IntelliPlan Gamification System*  
*Version 1.0 - December 2024*
