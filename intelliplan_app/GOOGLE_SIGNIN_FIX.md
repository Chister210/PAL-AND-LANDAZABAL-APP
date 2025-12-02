# Google Sign-In Configuration Guide - STEP BY STEP

## ⚠️ Current Status
Google Sign-In is **NOT WORKING** because it needs Firebase configuration. The error you're seeing (`ApiException: 10`) means "Developer Error" - not an internet issue!

## 🔧 How to Fix It

### Step 1: Get SHA-1 Fingerprint

Open PowerShell and run:

```powershell
cd "C:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app\android"
.\gradlew signingReport
```

Look for the **SHA-1** under "Task :app:signingReport" → "Variant: debug":
```
SHA-1: A1:B2:C3:D4:E5:F6:...
```

**Copy this SHA-1 fingerprint!**

### Step 2: Add SHA-1 to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **intelliplan** project
3. Click the **gear icon** (⚙️) → **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app (com.example.intelliplan_app)
6. Click **Add fingerprint**
7. **Paste the SHA-1** you copied
8. Click **Save**

### Step 3: Enable Google Sign-In in Firebase

1. Still in Firebase Console, go to **Authentication** (left sidebar)
2. Click **Sign-in method** tab
3. Find **Google** in the list
4. Click on it
5. Toggle **Enable**
6. Set **Project support email** (your email)
7. Click **Save**

### Step 4: Download New google-services.json

1. Go back to **Project settings** (gear icon)
2. Scroll down to your Android app
3. Click **google-services.json** download button
4. **Replace** the old file at:
   ```
   C:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app\android\app\google-services.json
   ```

### Step 5: Configure OAuth Consent Screen

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (same as Firebase)
3. Go to **APIs & Services** → **OAuth consent screen**
4. If not configured:
   - Choose **External**
   - Fill in:
     - App name: **IntelliPlan**
     - User support email: **your email**
     - Developer contact: **your email**
   - Click **Save and Continue**
   - Skip scopes (click **Save and Continue**)
   - Add test users (add your email)
   - Click **Save and Continue**

### Step 6: Rebuild the App

```powershell
cd "C:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"
flutter clean
flutter pub get
flutter run -d emulator-5554
```

## 🎯 After Configuration

Once you complete these steps:
- ✅ Google Sign-In will work properly
- ✅ Users can sign in with their Google account
- ✅ No more "Developer Error" (ApiException: 10)

## 🔄 Alternative: Use Email/Password Instead

**Don't want to configure Google Sign-In?** No problem!

Users can still:
- ✅ Register with email/password
- ✅ Login with email/password
- ✅ All features work the same

Just skip the Google Sign-In button and use the email/password form!

## 📱 Quick Test After Setup

1. Clear app data (or uninstall/reinstall)
2. Open app
3. Tap **"Sign in with Google"** or **"Sign up with Google"**
4. Select your Google account
5. ✅ Should sign in successfully!

## ❓ Still Not Working?

Check these:
- [ ] SHA-1 fingerprint added correctly
- [ ] Google Sign-In enabled in Firebase
- [ ] google-services.json updated
- [ ] OAuth consent screen configured
- [ ] App rebuilt after changes

## 🎓 Why This Error Happens

The error message "Failed to sign in with Google. Please check your internet connection" is **misleading**. 

The real issue:
- Google Sign-In requires Firebase configuration
- Firebase needs your app's SHA-1 fingerprint
- OAuth consent screen must be set up
- Without these, Google blocks the sign-in

This is a **security feature**, not a bug! Once configured properly, it works perfectly.

## ⚡ Quick Summary

```
1. Get SHA-1: gradlew signingReport
2. Add to Firebase: Project Settings → Add fingerprint
3. Enable Google: Authentication → Sign-in method → Google
4. Download new google-services.json
5. Configure OAuth consent screen
6. Rebuild app: flutter clean && flutter run
```

That's it! After these steps, Google Sign-In will work! 🎉
