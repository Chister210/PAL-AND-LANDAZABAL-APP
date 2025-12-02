# Firebase Setup Guide for IntelliPlan

## 📋 Prerequisites
- ✅ Firebase account created
- ✅ Flutter project exists
- ✅ Firebase dependencies already in pubspec.yaml

## 🚀 Step-by-Step Setup

### Step 1: Install Firebase CLI

Open PowerShell and run:
```powershell
# Install Firebase CLI via npm (requires Node.js)
npm install -g firebase-tools

# Or download directly from:
# https://firebase.google.com/docs/cli#windows-standalone-binary
```

Verify installation:
```powershell
firebase --version
```

### Step 2: Login to Firebase

```powershell
firebase login
```
- Browser window will open
- Login with your Firebase account
- Grant permissions

### Step 3: Install FlutterFire CLI

```powershell
dart pub global activate flutterfire_cli
```

Add to PATH if needed:
```powershell
# Add this to your PowerShell profile or system PATH:
# C:\Users\chest\AppData\Local\Pub\Cache\bin
```

Verify:
```powershell
flutterfire --version
```

### Step 4: Create Firebase Project

**Option A: Via Web Console (Recommended for first-time)**
1. Go to https://console.firebase.google.com/
2. Click "Add project" or "Create a project"
3. Enter project name: `intelliplan-app` (or your choice)
4. Enable Google Analytics (optional)
5. Click "Create project"

**Option B: Via CLI**
```powershell
firebase projects:create intelliplan-app
```

### Step 5: Configure Firebase for Flutter

Navigate to your project directory:
```powershell
cd "c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"
```

Run FlutterFire configure:
```powershell
flutterfire configure
```

**This will:**
1. Show list of your Firebase projects
2. Select `intelliplan-app` (or your project name)
3. Select platforms: **Android** and **iOS** (use spacebar to select)
4. Auto-generate `firebase_options.dart` file
5. Update Android and iOS configuration files

### Step 6: Enable Firebase Services

Go to Firebase Console: https://console.firebase.google.com/

#### A. Enable Authentication
1. Click your project
2. Go to **Build** → **Authentication**
3. Click "Get started"
4. Enable sign-in methods:
   - ✅ **Email/Password** (Enable)
   - Optional: Google, Facebook, etc.
5. Click "Save"

#### B. Enable Firestore Database
1. Go to **Build** → **Firestore Database**
2. Click "Create database"
3. Choose mode:
   - **Start in test mode** (for development)
   - Click "Next"
4. Choose location: (Select closest to you, e.g., `us-central`)
5. Click "Enable"

#### C. Set Firestore Security Rules
In Firestore Database → **Rules** tab, replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow users to read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Click **Publish**

#### D. Enable Firebase Storage (Optional - for file attachments)
1. Go to **Build** → **Storage**
2. Click "Get started"
3. Start in test mode
4. Click "Next" → "Done"

### Step 7: Update Your Flutter Code

The `firebase_options.dart` file will be auto-generated. Update your `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

### Step 8: Configure Android (if targeting Android)

#### A. Update `android/app/build.gradle`:
Make sure you have:
```gradle
android {
    compileSdkVersion 34  // or higher
    
    defaultConfig {
        minSdkVersion 21  // Firebase requires min 21
        targetSdkVersion 34
        multiDexEnabled true  // Add this
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'  // Add this
}
```

#### B. Update `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath 'com.google.gms:google-services:4.4.0'  // Add this
    }
}
```

#### C. Add to `android/app/build.gradle` (at the bottom):
```gradle
apply plugin: 'com.google.gms.google-services'
```

### Step 9: Test Firebase Connection

Create a test file to verify connection:

```dart
// lib/test_firebase.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirebaseConnection() async {
  try {
    // Test Firestore write
    await FirebaseFirestore.instance
        .collection('test')
        .doc('connection_test')
        .set({
      'message': 'Firebase connected successfully!',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    print('✅ Firebase connection successful!');
  } catch (e) {
    print('❌ Firebase connection failed: $e');
  }
}
```

Call this after Firebase initialization in main.dart:
```dart
await Firebase.initializeApp(...);
await testFirebaseConnection();  // Add this
```

### Step 10: Run Your App

```powershell
flutter clean
flutter pub get
flutter run
```

Check the console for "✅ Firebase connected successfully!"

## 🔍 Verify Setup

### Check Firebase Console
1. Go to Firestore Database
2. You should see a `test` collection
3. With a `connection_test` document

### Check Authentication
1. Go to Authentication → Users
2. Register a new user in your app
3. User should appear in Firebase Console

## 📱 Platform-Specific Notes

### Android:
- Min SDK: 21
- `google-services.json` auto-generated in `android/app/`
- MultiDex enabled for large apps

### iOS (if needed):
- Min iOS version: 11.0
- `GoogleService-Info.plist` auto-generated in `ios/Runner/`
- Update `ios/Podfile`: `platform :ios, '11.0'`

## 🐛 Troubleshooting

### Issue: "Firebase not initialized"
**Solution:** Ensure `Firebase.initializeApp()` is called before using Firebase services

### Issue: "No Firebase option for this platform"
**Solution:** Run `flutterfire configure` again and select your platform

### Issue: "google-services.json not found"
**Solution:** 
1. Download from Firebase Console → Project Settings → Your apps
2. Place in `android/app/` directory

### Issue: Gradle build fails
**Solution:**
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Issue: Permission denied errors
**Solution:** Check Firestore security rules (see Step 6C)

## ✅ Quick Commands Reference

```powershell
# Navigate to project
cd "c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"

# Configure Firebase
flutterfire configure

# Clean and rebuild
flutter clean
flutter pub get

# Run app
flutter run

# Check Firebase projects
firebase projects:list

# Deploy security rules (if you have firestore.rules file)
firebase deploy --only firestore:rules
```

## 📊 Firebase Structure for IntelliPlan

Your app will create this structure:

```
Firestore Database:
└── users/
    └── {userId}/
        ├── classes/
        │   └── {classId} → ClassSchedule data
        ├── assignments/
        │   └── {assignmentId} → Assignment data
        ├── tasks/
        │   └── {taskId} → StudyTask data
        ├── study_sessions/
        │   └── {sessionId} → StudySession data (Pomodoro)
        └── flashcards/
            └── {cardId} → Flashcard data (Spaced Repetition)
```

## 🎉 You're Ready!

Once setup is complete:
1. ✅ Firebase initialized in your app
2. ✅ Authentication enabled
3. ✅ Firestore database ready
4. ✅ Security rules configured
5. ✅ Your app can save/retrieve data

## 📞 Need Help?

Common resources:
- Firebase Console: https://console.firebase.google.com/
- FlutterFire Docs: https://firebase.flutter.dev/
- Firebase CLI Docs: https://firebase.google.com/docs/cli

---

**Next Steps After Setup:**
1. Test user registration
2. Add a class/assignment/task
3. Complete a Pomodoro session
4. Verify data in Firebase Console
5. Test data persistence (close and reopen app)

Good luck! 🚀
