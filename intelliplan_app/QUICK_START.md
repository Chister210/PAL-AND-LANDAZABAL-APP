# IntelliPlan - Quick Start Guide

## ⚡ Fast Setup (Already Done!)

Your Flutter app is **ready to run**! All dependencies are installed.

## 🚀 Run the App Now

### Step 1: Open Terminal
In VS Code, press `` Ctrl + ` `` (backtick) to open terminal.

### Step 2: Navigate to Project
```bash
cd "c:\Users\chest\Desktop\PAL AND LANDAZABAL APP\intelliplan_app"
```

### Step 3: Start an Emulator
**Option A: Android Studio**
- Open Android Studio
- Click "AVD Manager"
- Start an Android emulator

**Option B: VS Code**
- Press `Ctrl+Shift+P`
- Type "Flutter: Launch Emulator"
- Select your emulator

### Step 4: Run the App
```bash
flutter run
```

That's it! The app will launch in ~30-60 seconds.

## 📱 Test the App

### 1. Home Screen
- Beautiful landing page with app logo
- "Get Started" → Goes to login
- "Create Account" → Goes to registration

### 2. Create Account (or Login)
**Test credentials (any will work):**
- Email: `test@student.com`
- Password: `123456`
- Name: `Test Student`

### 3. Explore Features
After logging in, you'll see:
- **Dashboard**: Your level, XP, and streak
- **Achievements**: Locked/unlocked achievements (tap icons)
- **Leaderboard**: See top learners
- **Profile**: Your stats and settings

### 4. Test Gamification
- Check your Level and XP on dashboard
- View achievements (some are locked, waiting to be earned)
- See your position on leaderboard

## 🎮 App Features

| Feature | Screen | What It Does |
|---------|--------|-------------|
| 🏠 Home | Landing | Welcome screen with login/register |
| 🔐 Auth | Login/Register | User authentication |
| 📊 Dashboard | Main | Stats overview, quick actions |
| 🏆 Achievements | Gamification | View locked/unlocked achievements |
| 📈 Leaderboard | Gamification | Global rankings |
| 👤 Profile | Settings | User info and logout |

## 🎯 Quick Tips

### Hot Reload
After making code changes:
- Press `r` in terminal for hot reload
- Press `R` for full restart

### View Logs
All logs appear in the terminal where you ran `flutter run`

### Stop the App
Press `q` in the terminal

### Check Devices
```bash
flutter devices
```

### Clear Cache (if issues)
```bash
flutter clean
flutter pub get
```

## 📂 Important Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point |
| `lib/config/theme.dart` | Colors and styling |
| `lib/config/routes.dart` | Navigation setup |
| `lib/services/auth_service.dart` | Login/register logic |
| `lib/services/gamification_service.dart` | XP, achievements |

## 🛠️ Customize the App

### Change Colors
Edit `lib/config/theme.dart`:
```dart
static const Color primaryColor = Color(0xFF6C63FF); // Your color here
```

### Add More Achievements
Edit `lib/services/gamification_service.dart` in `_initializeAchievements()` method.

### Modify Screens
All screens are in `lib/screens/` folder.

## 📱 Build for Production

### Android APK
```bash
flutter build apk --release
```
Find APK in: `build/app/outputs/flutter-apk/app-release.apk`

### Install on Phone
1. Enable "Developer Options" on Android phone
2. Enable "USB Debugging"
3. Connect phone via USB
4. Run: `flutter install`

## ❓ Troubleshooting

**Q: App won't start?**
```bash
flutter doctor
flutter pub get
flutter run
```

**Q: Emulator not showing?**
- Ensure Android Studio AVD is running
- Or use: `flutter emulators --launch <emulator_name>`

**Q: Hot reload not working?**
- Press `R` for full restart in terminal

**Q: Build errors?**
```bash
flutter clean
flutter pub get
flutter run
```

## 🎓 Learn More

- [Flutter Documentation](https://docs.flutter.dev)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Widget Catalog](https://docs.flutter.dev/ui/widgets)

## 📞 Next Steps

1. ✅ Run the app and test all features
2. ✅ Customize colors and branding
3. ✅ Add lesson content (currently empty)
4. ✅ Integrate with backend API
5. ✅ Add more achievements and rewards
6. ✅ Deploy to Google Play Store

---

**Need Help?** Check the full documentation in `DOCUMENTATION.md`

**Ready to code?** All files are in the `lib/` folder!

🎉 **Happy Coding!** Your IntelliPlan app is ready to go!
