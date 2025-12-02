# IntelliPlan App

An educational gamification mobile application built with Flutter and **Firebase**.

## 🔥 Firebase-Powered Features

- **Firebase Authentication** - Secure user registration and login
- **Cloud Firestore** - Real-time cloud database
- **Firebase Storage** - User avatars and lesson media
- **Firebase Hosting** - Web deployment ready

## Features

- **User Authentication** - Real Firebase Auth with email/password
- **Cloud Database** - All data synced to Firestore
- **Gamification System** - XP, levels, achievements (cloud-synced)
- **Real-time Leaderboard** - Live rankings from Firestore
- **Progress Tracking** - Lessons and achievements in the cloud
- **Multi-device Sync** - Access your progress anywhere

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Firebase Account (free)
- Android Studio / VS Code
- Android/iOS emulator or device

### Setup Firebase (Required)

**Before running the app, you must configure Firebase:**

```bash
# 1. Install FlutterFire CLI
dart pub global activate flutterfire_cli

# 2. Configure Firebase (creates firebase_options.dart)
cd "c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"
flutterfire configure
```

**Or manually:**
- Create Firebase project at https://console.firebase.google.com/
- Add Android app and download `google-services.json`
- See `FIREBASE_SETUP.md` for detailed instructions

### Installation

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## 📖 Documentation

| File | Purpose |
|------|---------|
| **FIREBASE_SETUP.md** | Complete Firebase configuration guide |
| **FIREBASE_QUICK_START.md** | Quick commands and reference |
| **FIREBASE_INTEGRATION_COMPLETE.md** | Firebase features overview |
| **DOCUMENTATION.md** | Full technical documentation |

## Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **Backend**: Firebase (Auth, Firestore, Storage, Hosting)
- **State Management**: Provider
- **Navigation**: GoRouter
- **UI**: Material Design 3 with Google Fonts

## Firebase Services Used

- ✅ Firebase Authentication (Email/Password)
- ✅ Cloud Firestore (NoSQL Database)
- ✅ Firebase Storage (File Storage)
- ✅ Firebase Hosting (Web Deployment)

## Build

```bash
# Android
flutter build apk --release

# Web (Deploy to Firebase)
flutter build web
firebase deploy --only hosting
```

## Firebase Free Tier

This app works perfectly on Firebase's free tier:
- Authentication: Unlimited users
- Firestore: 50K reads, 20K writes per day
- Storage: 5 GB
- Hosting: 10 GB/month

Perfect for development and moderate usage! 🎉
