# IntelliPlan - Flutter Educational Gamification App

## Overview
IntelliPlan is a comprehensive educational gamification mobile application built with Flutter. The app provides an engaging learning experience with achievement tracking, leaderboards, and progress monitoring.

## Features

### 1. **User Authentication**
- User registration with email and password
- Secure login system
- Profile management
- Session persistence

### 2. **Gamification System**
- **Experience Points (XP)**: Users earn XP by completing lessons and achieving milestones
- **Leveling System**: Progress through levels based on accumulated XP (1000 XP per level)
- **Achievements**: Unlock various achievements across different categories:
  - General achievements
  - Learning milestones
  - Consistency rewards
  - Mastery badges
  - Social achievements
- **Streak Tracking**: Maintain daily learning streaks to stay motivated

### 3. **Dashboard**
- Personalized welcome screen
- Real-time stats display (Level, XP, Streak)
- Quick action buttons for main features
- Recent achievements showcase

### 4. **Leaderboard**
- Global ranking system
- Top 3 podium display
- Full leaderboard list
- Points comparison with other learners

### 5. **Profile Management**
- View user statistics
- Edit profile information
- Manage account settings
- Privacy and security options

## Technical Architecture

### State Management
- **Provider**: Used for app-wide state management
- **AuthService**: Manages user authentication and profile
- **GamificationService**: Handles achievements, points, and streaks

### Routing
- **GoRouter**: Declarative routing with named routes
- Routes:
  - `/` - Home/Landing page
  - `/login` - Login screen
  - `/register` - Registration screen
  - `/dashboard` - Main dashboard
  - `/achievements` - Achievements screen
  - `/leaderboard` - Leaderboard screen
  - `/profile` - User profile

### Theme
- Light and dark theme support
- Custom color palette:
  - Primary: Purple (#6C63FF)
  - Secondary: Green (#4CAF50)
  - Accent: Red (#FF6B6B)
- Google Fonts integration (Poppins & Inter)
- Material Design 3

### Data Models
1. **User Model**
   - id, email, name, avatarUrl
   - level, experience, createdAt

2. **Achievement Model**
   - id, title, description, iconPath
   - pointsRequired, isUnlocked, unlockedAt
   - category

3. **Lesson Model** (Structure ready for future implementation)
   - id, title, description, subject
   - duration, difficulty, topics
   - isCompleted, progress, completedAt

## Project Structure

```
intelliplan_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── config/
│   │   ├── routes.dart              # Route definitions
│   │   └── theme.dart               # App theme configuration
│   ├── models/
│   │   ├── user.dart                # User data model
│   │   ├── achievement.dart         # Achievement data model
│   │   └── lesson.dart              # Lesson data model
│   ├── screens/
│   │   ├── home/
│   │   │   └── home_screen.dart     # Landing page
│   │   ├── auth/
│   │   │   ├── login_screen.dart    # Login page
│   │   │   └── register_screen.dart # Registration page
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart # Main dashboard
│   │   ├── gamification/
│   │   │   ├── achievements_screen.dart
│   │   │   └── leaderboard_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart  # User profile
│   ├── services/
│   │   ├── auth_service.dart        # Authentication logic
│   │   └── gamification_service.dart # Gamification logic
│   └── utils/
│       ├── constants.dart           # App constants
│       └── helpers.dart             # Helper functions
├── assets/
│   ├── icons/                       # App icons
│   ├── images/                      # Images
│   └── fonts/                       # Custom fonts
├── pubspec.yaml                     # Dependencies
└── README.md                        # Documentation
```

## Dependencies

- **flutter**: SDK
- **provider**: State management (^6.1.1)
- **go_router**: Navigation (^12.1.3)
- **google_fonts**: Typography (^6.1.0)
- **shared_preferences**: Local storage (^2.2.2)
- **sqflite**: Database (^2.3.0)
- **http**: API calls (^1.1.2)
- **intl**: Internationalization (^0.19.0)
- **uuid**: Unique identifiers (^4.2.2)
- **flutter_svg**: SVG support (^2.0.9)

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0+)
- Dart SDK
- Android Studio or VS Code
- Android/iOS emulator or physical device

### Installation

1. Navigate to the project directory:
   ```bash
   cd "c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building

#### Android APK
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## Future Enhancements

### Phase 1: Content Management
- [ ] Implement lesson modules
- [ ] Add quiz functionality
- [ ] Create study materials library
- [ ] Add video lessons support

### Phase 2: Social Features
- [ ] Friend system
- [ ] Study groups
- [ ] Chat functionality
- [ ] Challenge friends

### Phase 3: Analytics
- [ ] Learning analytics dashboard
- [ ] Progress tracking graphs
- [ ] Time spent analysis
- [ ] Performance reports

### Phase 4: Backend Integration
- [ ] REST API integration
- [ ] Real-time sync
- [ ] Cloud storage
- [ ] Push notifications

### Phase 5: Advanced Features
- [ ] AI-powered recommendations
- [ ] Personalized learning paths
- [ ] Voice lessons
- [ ] AR/VR integration

## Gamification Mechanics

### XP System
- Complete lesson: 50 XP
- Unlock achievement: 100 XP
- Daily login: 10 XP
- Perfect score: Bonus 25 XP

### Achievement Categories
1. **General**: Basic milestones (First login, First lesson, etc.)
2. **Learning**: Education-focused (Complete 10 lessons, etc.)
3. **Consistency**: Daily streak rewards
4. **Mastery**: Perfect scores and expertise
5. **Social**: Community engagement

### Level Progression
- Linear progression: 1000 XP per level
- No level cap
- Each level unlocks new features/content

## Design Philosophy

### User-Centric
- Intuitive navigation
- Clear visual hierarchy
- Accessible to all users

### Motivational
- Instant feedback
- Visual progress indicators
- Celebration animations for achievements

### Educational
- Focus on learning outcomes
- Balanced gamification (not overwhelming)
- Meaningful rewards

## Testing

Run tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
```

## Contributing

This app was developed based on the capstone thesis requirements for an educational gamification system. The architecture is designed to be extensible and maintainable.

## License

This project is developed for educational purposes as part of a capstone thesis project.

## Support

For issues or questions, please refer to the project documentation or contact the development team.

---

**Version**: 1.0.0  
**Last Updated**: November 2025  
**Status**: Active Development
