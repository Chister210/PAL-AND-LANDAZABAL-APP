# Firebase Quick Reference - IntelliPlan

## 🚀 Quick Setup Commands

### One-Time Setup
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (generates firebase_options.dart)
cd "c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"
flutterfire configure
```

### Install Firebase Tools (for Hosting)
```bash
npm install -g firebase-tools
firebase login
```

---

## 📦 What Changed in Your App

### New Dependencies Added:
- ✅ `firebase_core` - Firebase initialization
- ✅ `firebase_auth` - User authentication
- ✅ `cloud_firestore` - Cloud database
- ✅ `firebase_storage` - File storage

### Files Created/Modified:

**Created:**
- `lib/services/database_service.dart` - Firestore operations
- `FIREBASE_SETUP.md` - Complete setup guide

**Modified:**
- `lib/main.dart` - Firebase initialization
- `lib/services/auth_service.dart` - Real Firebase Auth
- `lib/services/gamification_service.dart` - Firestore integration
- `lib/screens/dashboard/dashboard_screen.dart` - User initialization
- `lib/screens/gamification/leaderboard_screen.dart` - Real-time leaderboard
- `pubspec.yaml` - Firebase dependencies

---

## 🔧 Before You Can Run the App

### Step 1: Create Firebase Project
1. Go to: https://console.firebase.google.com/
2. Click "Add project" → Name it "intelliplan-app"
3. Disable Google Analytics (optional)

### Step 2: Add Android App
1. Click "Add app" → Android icon
2. Package name: `com.intelliplan.intelliplan_app`
3. Download `google-services.json`
4. Place in: `android/app/google-services.json`

### Step 3: Enable Services in Firebase Console
1. **Authentication**: Enable Email/Password
2. **Firestore Database**: Create database in production mode
3. **Storage** (optional): Enable for avatars

### Step 4: Configure Firebase in App

**Option A - Automated (Recommended):**
```bash
flutterfire configure
```
This creates `lib/firebase_options.dart` automatically.

Then update `lib/main.dart`:
```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

**Option B - Manual:**
Get config from Firebase Console → Project Settings → Your app
Update the values in `lib/main.dart`

### Step 5: Update Android Build Files

`android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

`android/app/build.gradle` (add at bottom):
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## 🏃 Running the App

```bash
cd "c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"
flutter run
```

---

## 🗃️ Firestore Collections Structure

Your app now uses these Firestore collections:

```
users/
  {userId}/
    - name, email, level, experience
    
    achievements/
      {achievementId}/
        - title, description, isUnlocked
    
    completedLessons/
      {lessonId}/
        - progress, isCompleted, completedAt
    
    gamification/
      stats/
        - totalPoints, streak, lastActivityDate

lessons/
  {lessonId}/
    - title, description, subject, difficulty
```

---

## 🔐 Firestore Security Rules

Paste these rules in Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    match /lessons/{lessonId} {
      allow read: if request.auth != null;
    }
  }
}
```

---

## 🌐 Deploying to Firebase Hosting

### Build and Deploy Web App
```bash
# Build for web
flutter build web

# Initialize hosting (first time only)
firebase init hosting
# Choose: build/web as public directory

# Deploy
firebase deploy --only hosting
```

Your app will be at: `https://YOUR-PROJECT-ID.web.app`

---

## 🧪 Testing Firebase Integration

### Test User Registration:
1. Run app: `flutter run`
2. Click "Create Account"
3. Enter: name, email, password
4. Check Firebase Console → Authentication → Users

### Test Firestore:
1. Create account (saves to Firestore)
2. Check Firebase Console → Firestore Database → users
3. You should see user document with achievements subcollection

### Test Leaderboard:
1. Create multiple accounts
2. Each user gets XP automatically
3. Check leaderboard - shows real data from Firestore

---

## 📊 Firebase Console Quick Links

Once you create your project, bookmark these:

- **Authentication**: `/u/0/project/YOUR-PROJECT/authentication/users`
- **Firestore**: `/u/0/project/YOUR-PROJECT/firestore`
- **Storage**: `/u/0/project/YOUR-PROJECT/storage`
- **Hosting**: `/u/0/project/YOUR-PROJECT/hosting`
- **Settings**: `/u/0/project/YOUR-PROJECT/settings/general`

---

## 🐛 Common Issues & Fixes

### ❌ "No Firebase App has been created"
```bash
# Make sure Firebase is initialized before runApp()
# Check main.dart has Firebase.initializeApp()
```

### ❌ "Missing google-services.json"
```bash
# Download from Firebase Console
# Place in: android/app/google-services.json
```

### ❌ "PERMISSION_DENIED" in Firestore
```bash
# Check Firestore Rules
# Make sure user is authenticated
# Verify user ID matches in rules
```

### ❌ FirebaseException: invalid-email
```bash
# Check email format
# Enable Email/Password in Firebase Console → Authentication
```

---

## 📝 Key Features Now Using Firebase

| Feature | Before | Now |
|---------|--------|-----|
| **Authentication** | Mock/Fake | Firebase Auth |
| **User Data** | Local only | Firestore Cloud |
| **Achievements** | In-memory | Firestore Subcollection |
| **Leaderboard** | Mock data | Real-time Firestore |
| **Persistence** | Lost on restart | Synced to cloud |
| **Multi-device** | Not supported | Automatic sync |

---

## 🎯 Next Steps

After Firebase is configured:

1. ✅ Test user registration
2. ✅ Test login/logout
3. ✅ Create multiple accounts
4. ✅ Check leaderboard works
5. ✅ Add lesson content
6. ✅ Deploy to Firebase Hosting

---

## 💡 Pro Tips

- **Free Tier Limits**:
  - 50,000 reads/day
  - 20,000 writes/day
  - 1 GB storage
  - 10 GB hosting/month

- **Development**:
  - Use Firebase Local Emulator Suite for testing
  - Set up staging and production projects

- **Security**:
  - Never commit `google-services.json` to public repos
  - Use environment variables for sensitive data
  - Enable Firebase App Check before production

---

**Need the full guide?** See `FIREBASE_SETUP.md`

**Ready to deploy?** Follow the commands above! 🚀
