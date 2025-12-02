# Firebase Setup Guide for IntelliPlan

## Overview
This guide will help you set up Firebase for the IntelliPlan app, including Authentication, Firestore Database, and Firebase Hosting.

---

## Step 1: Create a Firebase Project

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Sign in with your Google account

2. **Create a New Project**
   - Click "Add project"
   - Enter project name: `intelliplan-app` (or your preferred name)
   - Disable Google Analytics (optional, can enable later)
   - Click "Create project"

---

## Step 2: Register Your Flutter App

### For Android:

1. **Add Android App**
   - In Firebase Console, click "Add app" → Select Android icon
   - **Android package name**: `com.intelliplan.intelliplan_app`
     - Find in: `android/app/build.gradle` → look for `applicationId`
   - **App nickname**: IntelliPlan (optional)
   - Click "Register app"

2. **Download google-services.json**
   - Download the `google-services.json` file
   - Place it in: `android/app/google-services.json`

3. **Add Firebase SDK to Android**
   
   Edit `android/build.gradle`:
   ```gradle
   buildscript {
       dependencies {
           // Add this line
           classpath 'com.google.gms:google-services:4.4.0'
       }
   }
   ```

   Edit `android/app/build.gradle`:
   ```gradle
   // Add at the bottom of the file
   apply plugin: 'com.google.gms.google-services'
   ```

### For iOS (Optional - requires Mac):

1. **Add iOS App**
   - In Firebase Console, click "Add app" → Select iOS icon
   - **iOS bundle ID**: `com.intelliplan.intelliplanApp`
     - Find in: `ios/Runner.xcodeproj` → Bundle Identifier
   - Download `GoogleService-Info.plist`
   - Add to: `ios/Runner/GoogleService-Info.plist` (use Xcode)

---

## Step 3: Configure Firebase in Flutter

### Option A: Use FlutterFire CLI (Recommended)

1. **Install FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Configure Firebase**
   ```bash
   cd "c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"
   flutterfire configure
   ```
   - Select your Firebase project
   - Choose platforms (Android, iOS, Web)
   - This will generate `lib/firebase_options.dart`

3. **Update main.dart**
   Replace the Firebase initialization in `lib/main.dart`:
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     
     runApp(const IntelliPlanApp());
   }
   ```

### Option B: Manual Configuration (Current)

If you prefer manual setup, get your Firebase config from Firebase Console:

1. **Go to Project Settings** (gear icon)
2. **Scroll to "Your apps"** → Select your app
3. **Copy the configuration values**

Update `lib/main.dart`:
```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: 'YOUR_API_KEY_HERE',
    appId: 'YOUR_APP_ID_HERE',
    messagingSenderId: 'YOUR_SENDER_ID_HERE',
    projectId: 'YOUR_PROJECT_ID_HERE',
    storageBucket: 'YOUR_BUCKET_HERE',
  ),
);
```

---

## Step 4: Enable Firebase Authentication

1. **Go to Firebase Console** → Your project
2. **Click "Authentication"** in the left sidebar
3. **Click "Get started"**
4. **Enable Email/Password Authentication**
   - Click "Sign-in method" tab
   - Click "Email/Password"
   - Enable the toggle
   - Click "Save"

---

## Step 5: Set Up Cloud Firestore

1. **Go to Firebase Console** → Your project
2. **Click "Firestore Database"** in the left sidebar
3. **Click "Create database"**
4. **Choose location**: Select closest to your users (e.g., `us-central`)
5. **Start in production mode** (we'll set rules later)

### Set Firestore Security Rules

Go to the "Rules" tab in Firestore and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User documents
    match /users/{userId} {
      // Users can read/write their own document
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Everyone can read user data for leaderboard
      allow read: if request.auth != null;
      
      // User's subcollections
      match /achievements/{achievementId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /completedLessons/{lessonId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /gamification/{doc} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Lessons - everyone can read, only admins can write
    match /lessons/{lessonId} {
      allow read: if request.auth != null;
      allow write: if false; // Set to admin only in production
    }
  }
}
```

Click "Publish" to save the rules.

---

## Step 6: Create Firestore Indexes (Optional but Recommended)

For better query performance, create indexes:

1. **Go to Firestore Console** → "Indexes" tab
2. **Click "Create Index"**

### Leaderboard Index:
- **Collection ID**: `users`
- **Fields**:
  - `experience` → Descending
  - `__name__` → Descending
- **Query scope**: Collection
- Click "Create"

---

## Step 7: Enable Firebase Storage (Optional)

For user avatars and lesson images:

1. **Go to Firebase Console** → "Storage"
2. **Click "Get started"**
3. **Accept default security rules** (will update later)
4. **Choose location**: Same as Firestore

### Storage Security Rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /lessons/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only
    }
  }
}
```

---

## Step 8: Test Firebase Connection

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Create a test account**:
   - Open the app
   - Go to "Create Account"
   - Enter: name, email, password
   - Click "Create Account"

3. **Verify in Firebase Console**:
   - Go to Authentication → Users
   - You should see the new user
   - Go to Firestore Database → users collection
   - You should see a user document

---

## Step 9: Set Up Firebase Hosting (For Web Deployment)

### Configure Firebase Hosting:

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase in your project**:
   ```bash
   cd "c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"
   firebase init hosting
   ```
   - Select your Firebase project
   - Set public directory: `build/web`
   - Configure as single-page app: Yes
   - Overwrite index.html: No

4. **Build Flutter Web**:
   ```bash
   flutter build web
   ```

5. **Deploy to Firebase Hosting**:
   ```bash
   firebase deploy --only hosting
   ```

Your app will be live at: `https://your-project-id.web.app`

---

## Firestore Database Structure

```
users/ (collection)
  ├── {userId}/ (document)
  │   ├── id: string
  │   ├── email: string
  │   ├── name: string
  │   ├── level: number
  │   ├── experience: number
  │   ├── avatarUrl: string?
  │   ├── createdAt: timestamp
  │   │
  │   ├── achievements/ (subcollection)
  │   │   └── {achievementId}/ (document)
  │   │       ├── title, description, pointsRequired
  │   │       ├── isUnlocked: boolean
  │   │       └── unlockedAt: timestamp?
  │   │
  │   ├── completedLessons/ (subcollection)
  │   │   └── {lessonId}/ (document)
  │   │       ├── progress: number
  │   │       ├── isCompleted: boolean
  │   │       └── completedAt: timestamp
  │   │
  │   └── gamification/ (subcollection)
  │       └── stats/ (document)
  │           ├── totalPoints: number
  │           ├── streak: number
  │           └── lastActivityDate: timestamp

lessons/ (collection)
  └── {lessonId}/ (document)
      ├── title, description, subject
      ├── duration: number
      ├── difficulty: string
      ├── topics: array
      └── createdAt: timestamp
```

---

## Environment Variables (Optional)

For better security, you can store Firebase config in environment variables:

1. Create `.env` file (add to `.gitignore`):
   ```
   FIREBASE_API_KEY=your_api_key
   FIREBASE_APP_ID=your_app_id
   FIREBASE_PROJECT_ID=your_project_id
   ```

2. Use `flutter_dotenv` package to load them

---

## Troubleshooting

### Issue: "No Firebase App '[DEFAULT]' has been created"
**Solution**: Ensure `Firebase.initializeApp()` is called before `runApp()`

### Issue: "Missing google-services.json"
**Solution**: Download from Firebase Console and place in `android/app/`

### Issue: "PERMISSION_DENIED" in Firestore
**Solution**: Check Firestore security rules and ensure user is authenticated

### Issue: "FirebaseAuthException: invalid-email"
**Solution**: Check email format and Firebase Auth settings

---

## Testing Firebase Locally

### Test Authentication:
```dart
// In debug mode, you can print auth state
FirebaseAuth.instance.authStateChanges().listen((user) {
  print('Auth state changed: ${user?.email}');
});
```

### Test Firestore:
```dart
// Check connection
FirebaseFirestore.instance.collection('users').limit(1).get().then((snapshot) {
  print('Firestore connected: ${snapshot.docs.length} documents');
});
```

---

## Production Checklist

Before deploying to production:

- [ ] Enable Firebase App Check (bot protection)
- [ ] Review and tighten Firestore security rules
- [ ] Set up Firebase budget alerts
- [ ] Enable Firebase Performance Monitoring
- [ ] Set up Firebase Crashlytics
- [ ] Configure backup for Firestore data
- [ ] Test on multiple devices
- [ ] Set up CI/CD pipeline

---

## Useful Firebase Console Links

- **Console**: https://console.firebase.google.com/
- **Documentation**: https://firebase.google.com/docs
- **FlutterFire**: https://firebase.flutter.dev/
- **Pricing**: https://firebase.google.com/pricing

---

## Need Help?

- Firebase Documentation: https://firebase.google.com/docs
- FlutterFire Documentation: https://firebase.flutter.dev/
- Stack Overflow: Tag `firebase` + `flutter`

---

**Last Updated**: November 2025  
**Firebase SDK Version**: 3.6.0+  
**Flutter Version**: 3.x
