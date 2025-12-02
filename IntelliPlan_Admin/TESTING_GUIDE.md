# 🧪 IntelliPlan Admin Panel - Testing Guide

## Pre-Testing Setup

### 1. Create Test Admin Account

**Option A: Firebase Console**
```
1. Go to https://console.firebase.google.com/
2. Select your project: intelliplan-949ef
3. Navigate to Firestore Database
4. Find 'users' collection
5. Click on your user document
6. Add field:
   - Field: role
   - Type: string
   - Value: admin
7. Save
```

**Option B: Using create_admin_user.js**
```bash
cd IntelliPlan_Admin
node create_admin_user.js
# Enter email and password when prompted
```

### 2. Start Local Server

```bash
cd IntelliPlan_Admin
firebase serve
# Or use live-server, http-server, etc.
```

Open: `http://localhost:5000`

---

## 🔐 Authentication Testing

### Test 1: Admin Login ✅
**Steps**:
1. Navigate to login page
2. Enter admin email and password
3. Click "Login"

**Expected Result**:
- ✅ Redirected to dashboard (index.html)
- ✅ See "Overview" section with data
- ✅ Sidebar shows admin name

**Common Issues**:
- ❌ "Permission denied" → User doesn't have role='admin'
- ❌ "Invalid credentials" → Check email/password
- ❌ Infinite loop → Clear localStorage and cookies

---

### Test 2: Non-Admin Login ❌
**Steps**:
1. Create a regular user (role != 'admin')
2. Try to login

**Expected Result**:
- ✅ Login fails
- ✅ Redirected back to login page
- ✅ User signed out automatically

---

### Test 3: Session Persistence ✅
**Steps**:
1. Login as admin
2. Refresh page (F5)

**Expected Result**:
- ✅ Still logged in
- ✅ Dashboard loads immediately
- ✅ No redirect to login

---

### Test 4: Logout ✅
**Steps**:
1. Click "Log out" button in sidebar
2. Confirm

**Expected Result**:
- ✅ Redirected to login page
- ✅ localStorage cleared
- ✅ Cannot access dashboard without re-login

---

## 📊 Overview Dashboard Testing

### Test 5: Widget Data ✅
**Steps**:
1. Login and view Overview section
2. Check all widgets

**Expected Results**:
- ✅ "Total Users" shows number > 0
- ✅ "Active Users Today" shows 0 or more
- ✅ "Total Tasks" shows number >= 0
- ✅ "Tasks Completed Today" shows number >= 0

**Verify**:
- Open Firestore Console
- Count users manually
- Compare with dashboard numbers

---

### Test 6: Charts Rendering ✅
**Steps**:
1. View Overview section
2. Check all 3 charts

**Expected Results**:
- ✅ "Most Used Study Technique" pie chart shows colors
- ✅ "Streak Distribution" pie chart has 5 segments
- ✅ "App Usage Time" bar chart shows 7 bars (days)

**Visual Check**:
- Charts are not blank
- Labels are visible
- Colors match theme

---

### Test 7: Theme Toggle ✅
**Steps**:
1. Click theme button (bottom right)
2. Switch from dark to light
3. Switch back to dark

**Expected Results**:
- ✅ Background changes color
- ✅ Text colors adapt
- ✅ Charts update colors
- ✅ Preference saved (survives refresh)

---

## 👥 User Management Testing

### Test 8: User Table Load ✅
**Steps**:
1. Click "User Management" in sidebar
2. Wait for table to load

**Expected Results**:
- ✅ Table shows users (or "No users found")
- ✅ Columns: ID, Name, Email, Technique, Tasks, Streak, Level, Points, Last Active
- ✅ Each row has action buttons

---

### Test 9: Search Functionality ✅
**Steps**:
1. Go to User Management
2. Type a user's name in search box
3. Type a user's email

**Expected Results**:
- ✅ Table filters in real-time
- ✅ Only matching users show
- ✅ Clear search shows all users again

---

### Test 10: Filter by Technique ✅
**Steps**:
1. Go to User Management
2. Select "Pomodoro" from dropdown
3. Select "All techniques"

**Expected Results**:
- ✅ Only users with preferredTechnique='pomodoro' show
- ✅ "All" shows everyone again

---

### Test 11: View User Profile ✅
**Steps**:
1. Go to User Management
2. Click "View" on any user

**Expected Results**:
- ✅ Modal/alert shows user details
- ✅ Shows: Email, Technique, Level, XP, Points
- ✅ Shows: Streaks, Tasks, Sessions, Time, Achievements
- ✅ Shows: Created At, Last Active

---

### Test 12: Adjust User XP ✅
**Steps**:
1. Click "XP" button on a user
2. Enter "+100"
3. Confirm

**Expected Results**:
- ✅ Success message
- ✅ User's XP increased by 100 in Firestore
- ✅ Audit log created
- ✅ Table refreshes with new XP

**Verify in Firestore**:
```
users/{uid}
  xp: (previous value + 100)
```

---

### Test 13: Reset User Streak ✅
**Steps**:
1. Click "Reset" button on a user with streak > 0
2. Confirm in modal

**Expected Results**:
- ✅ Confirmation modal appears
- ✅ After confirm, streak = 0
- ✅ Firestore updated
- ✅ Audit log created

**Verify in Firestore**:
```
users/{uid}
  currentStreak: 0
```

---

## 📝 Task Analytics Testing

### Test 14: Timeline Chart ✅
**Steps**:
1. Click "Task Analytics" in sidebar
2. View "Tasks Created (last 30 days)"

**Expected Results**:
- ✅ Line chart with 30 data points
- ✅ X-axis shows days (1-30)
- ✅ Y-axis shows task count
- ✅ Line connects points

---

### Test 15: Completion Chart ✅
**Steps**:
1. View "Completion vs Overdue" chart

**Expected Results**:
- ✅ Bar chart with 4 bars
- ✅ Labels: Completed, Overdue, In Progress, Pending
- ✅ Colors: Green, Red, Orange, Blue
- ✅ Heights match task counts

---

### Test 16: Technique Distribution ✅
**Steps**:
1. View "Tasks per Technique" chart

**Expected Results**:
- ✅ Doughnut chart (circle with hole)
- ✅ Shows technique breakdown
- ✅ Legend shows technique names

---

## 🎯 Study Technique Testing

### Test 17: Pomodoro Stats ✅
**Steps**:
1. Click "Study Techniques" in sidebar
2. View Pomodoro card

**Expected Results**:
- ✅ "Sessions / day" shows number
- ✅ "Avg session length" shows minutes
- ✅ "Completion ratio" shows percentage

---

### Test 18: SR and AR Stats ✅
**Steps**:
1. View Spaced Repetition card
2. View Active Recall card

**Expected Results**:
- ✅ Cards show data or placeholders
- ✅ No errors in console

---

## 🏆 Gamification Testing

### Test 19: Achievements List ✅
**Steps**:
1. Click "Gamification" in sidebar
2. View "Top Achievements" list

**Expected Results**:
- ✅ Lists achievements or "No achievements yet"
- ✅ Shows unlock count per achievement
- ✅ Sorted by rarity (fewest unlocks first)

---

### Test 20: Points Economy Chart ✅
**Steps**:
1. View "Points Economy" chart

**Expected Results**:
- ✅ Bar chart with 3 bars
- ✅ Labels: Total Earned, Total Spent, Current Balance
- ✅ Heights represent point totals

---

## 📘 Subject Management Testing

### Test 21: Add Subject ✅
**Steps**:
1. Click "Subjects" in sidebar
2. Click "Add Subject" button
3. Enter:
   - Code: TEST101
   - Name: Test Subject
   - Category: Major
   - Department: IT
   - Color: #ff6b6b
4. Confirm

**Expected Results**:
- ✅ Success message
- ✅ Subject appears in table
- ✅ Audit log created

**Verify in Firestore**:
```
subjects/
  {auto-id}
    code: "TEST101"
    name: "Test Subject"
    category: "Major"
    department: "IT"
    color: "#ff6b6b"
    createdAt: (timestamp)
    createdBy: (admin uid)
```

---

### Test 22: Edit Subject ✅
**Steps**:
1. Click "Edit" on TEST101
2. Change name to "Test Subject Updated"
3. Confirm

**Expected Results**:
- ✅ Success message
- ✅ Table updates with new name
- ✅ Firestore updated
- ✅ Audit log created

---

### Test 23: Delete Subject ✅
**Steps**:
1. Click "Delete" on TEST101
2. Confirm in modal

**Expected Results**:
- ✅ Confirmation modal appears
- ✅ After confirm, subject removed from table
- ✅ Document deleted in Firestore
- ✅ Audit log created

---

## 💬 Feedback Testing

### Test 24: Submit Feedback (Flutter App) ✅
**Prerequisite**: Add feedback submission to Flutter app
```dart
await FirebaseFirestore.instance.collection('feedback').add({
  'userId': currentUserId,
  'type': 'Suggestion',
  'message': 'Test feedback from app',
  'status': 'open',
  'createdAt': FieldValue.serverTimestamp(),
});
```

---

### Test 25: View Feedback ✅
**Steps**:
1. Click "Feedback" in sidebar
2. View feedback table
3. Click "View" on a feedback item

**Expected Results**:
- ✅ Table shows feedback entries
- ✅ Modal shows full details
- ✅ User name resolved from userId

---

### Test 26: Resolve Feedback ✅
**Steps**:
1. Click "Resolve" on an open feedback
2. Confirm

**Expected Results**:
- ✅ Status changes to "resolved"
- ✅ Firestore updated
- ✅ Audit log created
- ✅ Green badge appears

---

## 🔍 System Logs Testing

### Test 27: Audit Logs Display ✅
**Steps**:
1. Click "System Logs" in sidebar
2. View audit logs section

**Expected Results**:
- ✅ Shows recent events (up to 100)
- ✅ Newest events first
- ✅ Each entry shows: Icon, Type, Message, Time
- ✅ Timestamps formatted ("2h ago")

---

### Test 28: Audit Log Creation ✅
**Steps**:
1. Perform an action (adjust XP, reset streak, etc.)
2. Go to System Logs
3. Find the new entry

**Expected Results**:
- ✅ New log entry appears at top
- ✅ Correct event type
- ✅ Descriptive message
- ✅ Admin email/ID recorded

**Verify in Firestore**:
```
audit_logs/
  {auto-id}
    type: "XP_ADJUSTED"
    message: "Admin adjusted XP..."
    timestamp: (recent)
    adminId: (your uid)
    adminEmail: (your email)
```

---

## 📱 Responsive Design Testing

### Test 29: Desktop View (1920px) ✅
**Steps**:
1. Open admin panel on desktop
2. Check layout

**Expected Results**:
- ✅ Sidebar always visible
- ✅ Charts use full width
- ✅ Tables readable
- ✅ 4-column grid for cards

---

### Test 30: Tablet View (768px) ✅
**Steps**:
1. Resize browser to 768px
2. Check layout

**Expected Results**:
- ✅ Sidebar still visible
- ✅ 2-column grid for cards
- ✅ Charts resize properly

---

### Test 31: Mobile View (375px) ✅
**Steps**:
1. Resize browser to mobile size
2. Click hamburger menu (☰)

**Expected Results**:
- ✅ Sidebar hidden by default
- ✅ Hamburger menu appears
- ✅ Clicking menu shows sidebar (slide-out)
- ✅ Clicking outside closes sidebar
- ✅ Single column layout
- ✅ Touch-friendly buttons

---

## 🎨 Theme Testing

### Test 32: Dark Mode ✅
**Steps**:
1. Ensure theme is dark
2. Check all sections

**Expected Results**:
- ✅ Dark background (#071017)
- ✅ White/light text
- ✅ Chart colors visible
- ✅ Cards have subtle shadows

---

### Test 33: Light Mode ✅
**Steps**:
1. Toggle to light mode
2. Check all sections

**Expected Results**:
- ✅ Light background (#ffffff)
- ✅ Dark text
- ✅ Charts adapt colors
- ✅ Good contrast

---

## ⚡ Performance Testing

### Test 34: Load Time ✅
**Steps**:
1. Clear cache
2. Open admin panel
3. Time until dashboard shows data

**Expected Results**:
- ✅ Dashboard loads in < 3 seconds (with data)
- ✅ Charts render smoothly
- ✅ No JavaScript errors in console

---

### Test 35: Large Dataset ✅
**Steps**:
1. Test with 100+ users
2. Test with 1000+ tasks
3. Check responsiveness

**Expected Results**:
- ✅ Tables still render quickly
- ✅ Search/filter works without lag
- ✅ Charts don't freeze browser

---

## 🐛 Error Handling Testing

### Test 36: Network Error ✅
**Steps**:
1. Disconnect internet
2. Try to load dashboard

**Expected Results**:
- ✅ Error message appears
- ✅ No infinite loading
- ✅ Graceful degradation

---

### Test 37: Firestore Permission Error ✅
**Steps**:
1. Temporarily change Firestore rules to deny admin read
2. Try to load data

**Expected Results**:
- ✅ Error caught
- ✅ Console shows specific error
- ✅ User notified

---

### Test 38: Invalid Input ✅
**Steps**:
1. Try to adjust XP with text input
2. Try to add subject with empty fields

**Expected Results**:
- ✅ Validation error shown
- ✅ Operation blocked
- ✅ User prompted to fix input

---

## ✅ Browser Compatibility Testing

### Test 39: Chrome ✅
- [ ] All features work
- [ ] Charts render
- [ ] No console errors

### Test 40: Firefox ✅
- [ ] All features work
- [ ] Charts render
- [ ] No console errors

### Test 41: Safari ✅
- [ ] All features work
- [ ] Charts render
- [ ] No console errors

### Test 42: Edge ✅
- [ ] All features work
- [ ] Charts render
- [ ] No console errors

---

## 📋 Final Checklist

Before presenting/deploying:

**Data Verification**:
- [ ] At least 1 admin user created
- [ ] At least 3 regular users exist
- [ ] Some tasks exist
- [ ] Some study sessions exist
- [ ] At least 1 achievement unlocked
- [ ] At least 1 subject created
- [ ] Feedback collection exists (optional)

**Functionality**:
- [ ] Can login as admin
- [ ] All 8 sections load
- [ ] All charts render
- [ ] Search works
- [ ] Filters work
- [ ] CRUD operations work
- [ ] Audit logs record actions

**UI/UX**:
- [ ] Theme toggle works
- [ ] Mobile responsive
- [ ] No layout breaks
- [ ] Professional appearance

**Security**:
- [ ] Non-admin cannot access
- [ ] Logout works
- [ ] Confirmations on destructive actions

**Documentation**:
- [ ] README exists
- [ ] Quick start guide exists
- [ ] Feature checklist exists
- [ ] Implementation summary exists

---

## 🎯 Testing Report Template

```markdown
# Admin Panel Testing Report
Date: __________
Tester: __________

## Authentication
- Login: ✅ / ❌
- Logout: ✅ / ❌
- Session: ✅ / ❌

## Features
- Overview Dashboard: ✅ / ❌
- User Management: ✅ / ❌
- Task Analytics: ✅ / ❌
- Study Techniques: ✅ / ❌
- Gamification: ✅ / ❌
- Subjects: ✅ / ❌
- Feedback: ✅ / ❌
- System Logs: ✅ / ❌

## Issues Found
1. (Description)
2. (Description)

## Overall Status
✅ PASS / ❌ FAIL

## Notes
(Additional comments)
```

---

## 🚀 Ready to Test!

Follow this guide step-by-step to ensure your admin panel is working perfectly before your capstone presentation.

**Good luck!** 🎉
