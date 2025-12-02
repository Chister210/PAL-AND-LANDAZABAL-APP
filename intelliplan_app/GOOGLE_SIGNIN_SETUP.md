# Google Sign-In Configuration Guide

## Overview
This guide will help you enable Google Sign-In and Email/Password authentication in Firebase Console.

## Prerequisites
- Firebase project: **intelliplan-949ef**
- Firebase account: **barbielle_pal@sjp2cd.edu.ph**

---

## Step 1: Enable Email/Password Authentication

1. **Go to Firebase Console Authentication:**
   - URL: https://console.firebase.google.com/project/intelliplan-949ef/authentication/providers

2. **Enable Email/Password Provider:**
   - Click on "Email/Password" in the list of providers
   - Toggle **"Enable"** to ON
   - Click **"Save"**

3. **Email Verification Settings (Already Configured):**
   - ✅ The app automatically sends verification emails on registration
   - ✅ Users must verify their email before they can login
   - ✅ Google Sign-In users bypass email verification (already verified by Google)

---

## Step 2: Enable Google Sign-In

### 2A: Enable Google Provider

1. **Go to Firebase Authentication Providers:**
   - URL: https://console.firebase.google.com/project/intelliplan-949ef/authentication/providers

2. **Enable Google Provider:**
   - Click on "Google" in the list of sign-in providers
   - Toggle **"Enable"** to ON
   - Set **Public-facing name**: "IntelliPlan"
   - Set **Support email**: barbielle_pal@sjp2cd.edu.ph
   - Click **"Save"**

### 2B: Configure OAuth Consent Screen (Required for Google Sign-In)

1. **Go to Google Cloud Console:**
   - URL: https://console.cloud.google.com/apis/credentials/consent?project=intelliplan-949ef

2. **Configure OAuth Consent Screen:**
   - **User Type:** Select "External" (unless you have Google Workspace)
   - Click **"Create"**

3. **Fill OAuth Consent Form:**
   - **App name:** IntelliPlan
   - **User support email:** barbielle_pal@sjp2cd.edu.ph
   - **App logo:** (Optional - upload your app logo)
   - **Application home page:** (Optional)
   - **Authorized domains:** (Leave empty for testing)
   - **Developer contact email:** barbielle_pal@sjp2cd.edu.ph
   - Click **"Save and Continue"**

4. **Scopes (Step 2):**
   - Click **"Save and Continue"** (no need to add scopes)

5. **Test Users (Step 3):**
   - Add test email: **barbielle_pal@sjp2cd.edu.ph**
   - Click **"Add"**
   - Click **"Save and Continue"**

6. **Summary (Step 4):**
   - Review settings
   - Click **"Back to Dashboard"**

### 2C: Get SHA-1 Certificate Fingerprint (Android)

1. **Generate Debug SHA-1:**
   Open PowerShell and run:
   ```powershell
   cd "C:\Program Files\Android\Android Studio\jbr\bin"
   .\keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

2. **Copy the SHA-1 fingerprint** from the output (looks like: `A1:B2:C3:D4:...`)

3. **Add SHA-1 to Firebase:**
   - Go to: https://console.firebase.google.com/project/intelliplan-949ef/settings/general
   - Scroll to "Your apps" section
   - Click on your Android app (com.example.intelliplan_app)
   - Click **"Add fingerprint"**
   - Paste your SHA-1 fingerprint
   - Click **"Save"**

### 2D: Download Updated google-services.json

1. **Download Config File:**
   - Still in Project Settings → Your Apps
   - Click on your Android app
   - Click **"google-services.json"** download button

2. **Replace Old File:**
   - Save the downloaded file to:
     ```
     c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app\android\app\google-services.json
     ```
   - Replace the existing file

---

## Step 3: Test Authentication

### Test Email/Password Registration:

1. **Run the app:**
   ```powershell
   flutter run
   ```

2. **Click "Sign Up"**

3. **Fill registration form:**
   - Name: Test User
   - Email: test@example.com
   - Password: Test@1234 (should show "Strong" indicator)
   - Confirm Password: Test@1234

4. **Click "Create Account"**

5. **Expected Result:**
   - ✅ Dialog appears: "Verify Your Email"
   - ✅ Verification email sent to inbox
   - ✅ User is NOT logged in yet

6. **Check Email:**
   - Open test@example.com inbox
   - Click verification link in email
   - Email should now be verified

7. **Login:**
   - Go back to Login screen
   - Enter email and password
   - Click "Login"
   - ✅ Should successfully login to dashboard

### Test Google Sign-In:

1. **Click "Continue with Google" button**

2. **Expected Result:**
   - Google Sign-In popup appears
   - Select Google account
   - ✅ Instantly logs in (no email verification needed)
   - ✅ Redirects to dashboard
   - ✅ User profile created automatically

---

## Step 4: Security Rules (Already Configured)

Firebase security rules are already set to allow:
- ✅ Users can only read/write their own data
- ✅ Authentication required for all operations
- ✅ Email verification checked on login

---

## Password Requirements

The app enforces strong passwords with real-time validation:

### Password Strength Levels:
- **Very Weak** (Red): 0-1 requirements met
- **Weak** (Orange): 2 requirements met
- **Medium** (Yellow): 3 requirements met ✅ Minimum to register
- **Strong** (Light Green): 4 requirements met
- **Very Strong** (Green): All 5 requirements met

### Requirements Checklist:
1. ✅ At least 8 characters
2. ✅ At least one lowercase letter (a-z)
3. ✅ At least one uppercase letter (A-Z)
4. ✅ At least one number (0-9)
5. ✅ At least one special character (!@#$%^&*...)

### Password Examples:
- ❌ `password` - Very Weak (no uppercase, numbers, special chars)
- ❌ `Password1` - Weak (no special character)
- ✅ `Pass@123` - Medium (all requirements, 8 chars)
- ✅ `MyPass@123` - Strong (10 chars)
- ✅ `MySecure@Pass123` - Very Strong (16 chars)

---

## Features Summary

### ✅ Email/Password Authentication:
- User registration with email
- **Email verification required** before login
- Strong password validation (real-time indicator)
- Password strength progress bar
- User-friendly error messages
- "Verify Your Email" dialog after registration

### ✅ Google Sign-In:
- One-tap Google authentication
- **No email verification needed** (Google already verifies)
- Automatic profile creation
- Avatar from Google account
- Name from Google account

### ✅ Security Features:
- Email must be verified to login (Email/Password only)
- Strong password enforcement
- Firebase security rules
- User data isolation
- Error handling and user feedback

---

## Troubleshooting

### Issue: "Email verification required" error
**Solution:** Check email inbox (including spam folder) and click verification link

### Issue: Google Sign-In not working
**Solution:** 
1. Ensure SHA-1 fingerprint is added to Firebase
2. Download latest google-services.json
3. Rebuild the app: `flutter clean && flutter run`

### Issue: "Password is too weak"
**Solution:** Follow password requirements (at least Medium strength)

### Issue: "Email already in use"
**Solution:** Use Login screen instead, or use different email

---

## Quick Links

- **Firebase Console:** https://console.firebase.google.com/project/intelliplan-949ef
- **Authentication:** https://console.firebase.google.com/project/intelliplan-949ef/authentication
- **Project Settings:** https://console.firebase.google.com/project/intelliplan-949ef/settings/general
- **Google Cloud Console:** https://console.cloud.google.com/apis/credentials?project=intelliplan-949ef

---

## Next Steps

1. ✅ Enable Email/Password in Firebase Console
2. ✅ Enable Google Sign-In in Firebase Console
3. ✅ Configure OAuth Consent Screen
4. ✅ Add SHA-1 fingerprint
5. ✅ Download updated google-services.json
6. ✅ Test email registration with verification
7. ✅ Test Google Sign-In
8. ✅ Test password strength indicator
9. ✅ Verify data saves to Firestore

---

**Ready to test! 🚀**
