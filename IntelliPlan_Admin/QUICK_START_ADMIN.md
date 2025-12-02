# 🚀 IntelliPlan Admin Panel - Quick Start Guide

## First Time Setup

### 1. Create an Admin Account

You need to manually set a user as admin in Firestore:

**Option A: Using Firebase Console**
1. Go to Firebase Console → Firestore Database
2. Find the `users` collection
3. Select your user document
4. Add a field: `role` (string) = `admin`
5. Save changes

**Option B: Using create_admin_user.js**
```bash
cd IntelliPlan_Admin
node create_admin_user.js
```
Follow the prompts to enter email and password.

### 2. Access the Admin Panel

1. Open your browser
2. Navigate to: `https://your-project.web.app/` or `http://localhost:5000` (if testing locally)
3. Click "Login"
4. Enter your admin email and password
5. You'll be redirected to the dashboard

---

## Dashboard Overview

### 📊 Main Sections

1. **Overview** - System statistics and charts
2. **User Management** - View and manage all users
3. **Task Analytics** - Task creation and completion trends
4. **Study Techniques** - Performance of each study method
5. **Gamification** - Achievements and points economy
6. **Subjects** - Manage curriculum subjects
7. **Feedback** - User feedback and support requests
8. **System Logs** - Audit trail of all admin actions

---

## Common Tasks

### 👤 Managing Users

**View User Details**
1. Go to "User Management"
2. Find the user (use search bar)
3. Click "View" button
4. See complete profile and statistics

**Adjust User XP**
1. Go to "User Management"
2. Find the user
3. Click "XP" button
4. Enter amount to add (use negative to reduce)
5. Confirm

**Reset User Streak**
1. Go to "User Management"
2. Find the user
3. Click "Reset" button
4. Confirm the action
5. Streak will be set to 0

### 📘 Managing Subjects

**Add New Subject**
1. Go to "Subjects & Curriculum"
2. Click "Add Subject" button
3. Enter:
   - Subject Code (e.g., IT101)
   - Subject Name (e.g., Introduction to Computing)
   - Category (Major/Minor/Elective)
   - Department (IT/STEM/HUMSS)
   - Color (hex code like #3b82f6)
4. Subject is immediately available in the app

**Edit Subject**
1. Go to "Subjects & Curriculum"
2. Find the subject
3. Click "Edit" button
4. Update fields
5. Confirm

**Delete Subject**
1. Go to "Subjects & Curriculum"
2. Find the subject
3. Click "Delete" button
4. Confirm deletion

### 💬 Handling Feedback

**View Feedback**
1. Go to "Feedback & Moderation"
2. Browse feedback list
3. Click "View" to see full details

**Resolve Feedback**
1. Go to "Feedback & Moderation"
2. Find the feedback item
3. Click "Resolve" button
4. Status changes to "resolved"

### 📊 Analyzing Data

**Check Overall Statistics**
1. Go to "Overview"
2. View widgets:
   - Total Users
   - Active Users Today
   - Total Tasks
   - Tasks Completed Today

**View Study Technique Usage**
1. Go to "Overview"
2. Check "Most Used Study Technique" pie chart
3. See percentage breakdown

**Analyze Task Trends**
1. Go to "Task Analytics"
2. View "Tasks Created (last 30 days)" chart
3. Check "Completion vs Overdue" bar chart

**Monitor Achievements**
1. Go to "Gamification"
2. View "Top Achievements" list
3. See unlock counts and rarity

---

## Navigation Tips

### 🔍 Search & Filter

**Global Search**
- Use the top search bar to find users across all sections
- Search by name or email
- Results update in real-time

**Filter by Technique**
- In User Management, use the dropdown to filter
- Options: All, Pomodoro, Spaced Repetition, Active Recall

### 🎨 Theme Toggle

- Click the moon/sun icon (bottom right)
- Switches between dark and light mode
- Preference is saved automatically

### 📱 Mobile View

- On mobile, tap the ☰ menu icon to open sidebar
- Tap outside sidebar to close
- All features work on mobile

---

## Understanding the Data

### User Levels & XP
- Users earn XP from completing tasks and study sessions
- Each level requires more XP than the previous
- Admins can manually adjust XP if needed

### Streaks
- Current Streak: Consecutive days with activity
- Longest Streak: Record streak ever achieved
- Resets to 0 if a day is missed

### Study Points
- Earned from completing sessions and achievements
- Spent in the rewards store (in-app)
- Total economy visible in Gamification section

### Study Techniques
- **Pomodoro**: 25-minute focused sessions with breaks
- **Spaced Repetition**: Flashcard review with intervals
- **Active Recall**: Self-testing and quizzing

---

## Best Practices

### ✅ Do's

✅ **Regularly check Audit Logs** - Monitor for unusual activity
✅ **Respond to feedback quickly** - Improve user satisfaction
✅ **Review analytics weekly** - Identify trends and issues
✅ **Keep subjects updated** - Match current curriculum
✅ **Use confirmations** - Prevent accidental deletions

### ❌ Don'ts

❌ **Don't adjust XP arbitrarily** - Only for legitimate reasons
❌ **Don't delete users without backup** - Consider archiving instead
❌ **Don't ignore overdue tasks spike** - May indicate app issues
❌ **Don't share admin credentials** - Each admin should have own account

---

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Toggle Theme | Click theme button |
| Close Modal | Click outside or Cancel |
| Confirm Action | Click OK button |
| Navigate Sections | Click sidebar menu |

---

## Data Refresh

### Manual Refresh
- Refresh browser page (F5 or Cmd+R)
- Data reloads automatically on page load

### Real-time Updates
- Currently: Manual refresh required
- Future: Automatic updates with Firestore listeners

---

## Troubleshooting

### "No data showing"
**Cause**: Firestore rules or no data in database
**Solution**: 
1. Check Firestore rules allow admin read access
2. Verify data exists in Firestore console
3. Try refreshing the page

### "Charts not rendering"
**Cause**: Chart.js not loaded or canvas missing
**Solution**:
1. Check browser console for errors
2. Ensure internet connection (CDN)
3. Clear cache and reload

### "Authentication failed"
**Cause**: User doesn't have admin role
**Solution**:
1. Check Firestore user document
2. Ensure `role` field = `admin`
3. Logout and login again

### "Can't delete/edit"
**Cause**: Firestore permission error
**Solution**:
1. Verify admin has write access in Firestore rules
2. Check browser console for specific error
3. Ensure proper authentication

---

## Getting Help

### Debug Information
When reporting issues, provide:
- Browser type and version
- Error message from console (F12)
- Steps to reproduce
- Screenshot of issue

### Firestore Console
Access at: https://console.firebase.google.com/
- View/edit data directly
- Check security rules
- Monitor usage

### Browser Console
Open with F12 (Windows) or Cmd+Opt+I (Mac)
- See JavaScript errors
- View network requests
- Check authentication state

---

## Advanced Features (Coming Soon)

🔜 **Real-time Updates** - Data updates without refresh
🔜 **Email Notifications** - Send emails to users
🔜 **Bulk Operations** - Manage multiple users at once
🔜 **Data Export** - Download reports as CSV
🔜 **Custom Reports** - Create filtered reports
🔜 **User Impersonation** - View app as specific user (for support)

---

## Admin Panel URL

- Production: `https://intelliplan-949ef.web.app/`
- Development: `http://localhost:5000`

## Important Firestore Collections

- `users` - User profiles
- `users/{uid}/tasks` - User tasks
- `users/{uid}/study_sessions` - Study sessions
- `users/{uid}/achievements` - Unlocked achievements
- `subjects` - Curriculum subjects
- `feedback` - User feedback
- `audit_logs` - Admin action logs

---

**Need more help?** Check the complete documentation in `ADMIN_PANEL_DOCUMENTATION.md`
