# 🔥 IntelliPlan Firebase - Final Setup Steps

## ✅ What We've Done So Far:
- ✅ Logged into Firebase (barbielle_pal@sjp2cd.edu.ph)
- ✅ Connected to IntelliPlan project (intelliplan-949ef)
- ✅ Generated firebase_options.dart
- ✅ Updated main.dart to use Firebase config
- ✅ Configured Android app
- ✅ Set minSdk to 21 and enabled MultiDex

## 🎯 Next Steps: Enable Firebase Services

### Step 1: Enable Authentication

1. **Go to Firebase Console:**
   https://console.firebase.google.com/u/0/project/intelliplan-949ef

2. **Navigate to Authentication:**
   - Click on **"Build"** in the left sidebar
   - Click on **"Authentication"**

3. **Get Started:**
   - Click **"Get started"** button

4. **Enable Email/Password:**
   - Click on **"Email/Password"** in the Sign-in providers list
   - Toggle **"Enable"** switch ON
   - Click **"Save"**

### Step 2: Enable Firestore Database

1. **Navigate to Firestore:**
   - Click on **"Build"** → **"Firestore Database"**

2. **Create Database:**
   - Click **"Create database"** button

3. **Choose Mode:**
   - Select **"Start in test mode"** (for development)
   - This allows read/write access for 30 days
   - Click **"Next"**

4. **Choose Location:**
   - Select closest region (e.g., `asia-southeast1` for Philippines)
   - Click **"Enable"**
   - Wait for database creation (~1-2 minutes)

### Step 3: Update Firestore Security Rules

1. **Go to Rules Tab:**
   - In Firestore Database, click **"Rules"** tab

2. **Replace with these rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read and write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to create their user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. **Publish Rules:**
   - Click **"Publish"** button

### Step 4: Enable Firebase Storage (Optional - for attachments)

1. **Navigate to Storage:**
   - Click on **"Build"** → **"Storage"**

2. **Get Started:**
   - Click **"Get started"**
   - Start in **test mode**
   - Click **"Next"**
   - Choose same location as Firestore
   - Click **"Done"**

### Step 5: Test Your App

1. **Clean and build:**
```powershell
cd "c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"
flutter clean
flutter pub get
flutter run
```

2. **Test Firebase Connection:**
   - App should launch without errors
   - Try registering a new user
   - Check Firebase Console → Authentication → Users (should see new user)

### Step 6: Verify Firestore Works

After running the app and adding some data (like a class or assignment):

1. **Go to Firestore Database → Data tab**
2. **You should see:**
   ```
   users/
     └── {your-user-id}/
           ├── classes/
           ├── assignments/
           ├── tasks/
           ├── study_sessions/
           └── flashcards/
   ```

## 🔍 Quick Check Commands

```powershell
# Check Firebase connection
firebase projects:list

# Check if your app is registered
firebase apps:list --project=intelliplan-949ef

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## 🎉 When Complete, You'll Have:

- ✅ Firebase Authentication (Email/Password enabled)
- ✅ Firestore Database (with proper security rules)
- ✅ Firebase Storage (optional, for file uploads)
- ✅ Your Flutter app connected to Firebase
- ✅ All data automatically syncing to cloud

## 📱 Test These Features:

1. **Register a new user** (should appear in Firebase Console)
2. **Add a class** (should save to Firestore)
3. **Add an assignment** (should persist after app restart)
4. **Complete a Pomodoro session** (should record in database)
5. **Review flashcards** (SM-2 data should update)
6. **Check analytics** (should calculate from real data)

## 🐛 Troubleshooting:

**Issue: "FirebaseException: permission-denied"**
- Solution: Check Firestore security rules are published

**Issue: "No Firebase App"**
- Solution: Verify firebase_options.dart exists and main.dart imports it

**Issue: App crashes on startup**
- Solution: Run `flutter clean`, then `flutter pub get`, then `flutter run`

**Issue: User registration fails**
- Solution: Verify Email/Password authentication is enabled in Firebase Console

## 📞 Your Project Links:

- **Firebase Console:** https://console.firebase.google.com/u/0/project/intelliplan-949ef
- **Authentication:** https://console.firebase.google.com/u/0/project/intelliplan-949ef/authentication/users
- **Firestore:** https://console.firebase.google.com/u/0/project/intelliplan-949ef/firestore/data
- **Storage:** https://console.firebase.google.com/u/0/project/intelliplan-949ef/storage

---

## ✨ You're Almost Done!

Just follow Steps 1-3 in the Firebase Console, then run your app. Everything is already configured in your code! 🚀
