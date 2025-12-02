# IntelliPlan Admin Panel - Complete Documentation

## 📋 Overview

The IntelliPlan Admin Panel is a comprehensive web-based dashboard for managing and monitoring the IntelliPlan study app. It provides real-time analytics, user management, task monitoring, and system administration capabilities.

---

## 🎯 Features Implemented

### 1️⃣ **Admin Overview Dashboard**

**Purpose**: Provides a high-level summary of system usage and key metrics.

**Widgets Included**:
- ✅ **Total Users**: Count of all registered students
- ✅ **Active Users Today**: Users who logged in within the last 24 hours
- ✅ **Total Tasks Created**: Cumulative count of all tasks across all users
- ✅ **Tasks Completed Today**: Tasks marked complete today
- ✅ **Most Used Study Technique**: Pie chart showing distribution (Pomodoro, Spaced Repetition, Active Recall)
- ✅ **Streak Distribution**: Breakdown of users by streak ranges (0, 1-3, 4-7, 8-14, >14 days)
- ✅ **App Usage Time**: Bar chart showing average session duration by day of week

**Data Source**: 
- `users` collection
- `study_sessions` subcollections
- Real-time Firestore queries

---

### 2️⃣ **User Management**

**Purpose**: Complete oversight and management of all registered users.

**User Table Columns**:
| Column | Description |
|--------|-------------|
| User ID | Firebase UID (truncated for display) |
| Name | Full name of the student |
| Email | Email address |
| Technique | Preferred study technique |
| Completed Tasks | Count of tasks with status='completed' |
| Streak | Current streak in days |
| Level | Gamification level |
| Points | Available Study Points |
| Last Active | Last login timestamp (formatted as "2h ago", "3d ago", etc.) |

**Actions Available**:
- ✅ **View Profile**: Shows detailed user statistics including:
  - Email, Technique, Level, XP, Study Points
  - Current & Longest Streak
  - Total Tasks, Completed, In Progress
  - Total Study Sessions & Time
  - Achievement count
  - Account creation & last active dates
  
- ✅ **Adjust XP**: Add or remove XP points (with audit logging)
- ✅ **Reset Streak**: Reset user's current streak to 0 (with confirmation)
- ⚠️ **Ban User**: (Template ready - requires `isBanned` field implementation)
- ⚠️ **Delete Account**: (Template ready - requires soft delete implementation)

**Filters & Search**:
- ✅ Filter by study technique (All, Pomodoro, Spaced Repetition, Active Recall)
- ✅ Search by name or email (real-time)
- ✅ Global top search bar

---

### 3️⃣ **Task Analytics**

**Purpose**: Analyze task creation patterns, completion rates, and trends.

**Graphs & Charts**:
1. ✅ **Tasks Created (Last 30 Days)**: Line chart showing daily task creation
2. ✅ **Completion vs Overdue**: Bar chart comparing:
   - Completed tasks
   - Overdue tasks (past due date, not completed)
   - In Progress tasks
   - Pending tasks
3. ✅ **Tasks per Technique**: Doughnut chart showing task distribution by study technique

**Insights Generated**:
- Completion rate percentage
- Most active creation days
- Peak task creation times (ready for implementation)
- Subject-wise distribution (requires subject field in tasks)

**Data Source**: 
- `users/{uid}/tasks` subcollections
- Aggregated across all users

---

### 4️⃣ **Study Technique Performance**

**Purpose**: Monitor effectiveness and engagement of each study technique.

**Pomodoro Metrics**:
- ✅ Sessions per day (average over last 30 days)
- ✅ Average session length (in minutes)
- ✅ Completion ratio (% of sessions completed)

**Spaced Repetition Metrics**:
- ✅ Cards reviewed (estimated from sessions × 10)
- ✅ Accuracy (placeholder - requires flashcard data)

**Active Recall Metrics**:
- ✅ Tests taken (count of active_recall sessions)
- ✅ Correct % (placeholder - requires quiz data)

**Data Source**: 
- `users/{uid}/study_sessions` subcollections
- Filtered by `technique` field

---

### 5️⃣ **Gamification Management**

**Purpose**: Monitor and manage the gamification system.

**Features**:

**Achievement Monitor**:
- ✅ Lists all unlocked achievements across all users
- ✅ Shows unlock count per achievement
- ✅ Sorted by rarity (rarest first)
- ✅ Displays achievement category

**Points Economy**:
- ✅ Total Points Earned (aggregate)
- ✅ Total Points Spent (aggregate)
- ✅ Current Points Balance (aggregate)
- ✅ Bar chart visualization

**Rewards Store Management** (Template Ready):
- Add/Remove rewards
- Adjust prices
- Modify reward effects
- Enable/Disable boosts

**Data Source**: 
- `users/{uid}/achievements` subcollections
- `users` collection (studyPoints, totalPointsEarned, pointsSpent)

---

### 6️⃣ **Subjects & Curriculum Manager**

**Purpose**: Manage the subjects/courses available in the system.

**Subject Fields**:
- ✅ **Code**: Subject code (e.g., IT101, MATH201)
- ✅ **Name**: Full subject name
- ✅ **Category**: Major / Minor / Elective / General
- ✅ **Department**: IT, STEM, HUMSS, etc.
- ✅ **Color Tag**: Hex color for calendar display

**CRUD Operations**:
- ✅ **Add Subject**: Create new subject with all fields
- ✅ **Edit Subject**: Update name, category, department, color
- ✅ **Delete Subject**: Remove subject (with confirmation)
- ⚠️ **Archive Subject**: (Template ready)

**Approval System** (Template Ready):
- Approve user-added subjects
- Reject with reason

**Data Source**: 
- `subjects` collection (global)

---

### 7️⃣ **Feedback & Moderation**

**Purpose**: Handle user feedback and support requests.

**Feedback Table Columns**:
| Column | Description |
|--------|-------------|
| ID | Feedback document ID (truncated) |
| User | Name of user who submitted feedback |
| Type | Suggestion / Bug / Report / General |
| Message | Feedback content |
| Date | Submission timestamp |
| Status | open / resolved |
| Actions | View, Resolve buttons |

**Actions**:
- ✅ **View Feedback**: Shows full feedback details with user info
- ✅ **Mark as Resolved**: Updates status to 'resolved' (with audit log)
- ⚠️ **Reply to Feedback**: (Template ready - requires email integration)
- ⚠️ **Forward to Dev**: (Template ready - requires webhook/email)

**Data Source**: 
- `feedback` collection

---

### 8️⃣ **System Settings & Logs**

**Purpose**: Monitor system activity and manage administrative settings.

**Audit Logs**:
- ✅ Displays last 100 events in reverse chronological order
- ✅ Event types tracked:
  - ✅ LOGIN_SUCCESS / LOGIN_FAILURE
  - ✅ USER_CREATED
  - ✅ XP_ADJUSTED
  - ✅ STREAK_RESET
  - ✅ SUBJECT_CREATED / UPDATED / DELETED
  - ✅ FEEDBACK_RESOLVED
  - ✅ ADMIN_ACTION

**Log Entry Format**:
```
🔥 STREAK_RESET
   Admin reset streak for user John Doe (abc123...)
   3h ago
```

**Admin Account Management** (Template Ready):
- Add new admin
- Set roles (Owner / Moderator / Viewer)
- Enable 2FA
- Permissions editor

**General Settings** (Template Ready):
- Maintenance mode toggle
- App version notes
- Firestore storage usage
- API key viewer (read-only)

**Data Source**: 
- `audit_logs` collection

---

## 🔐 Authentication & Security

### Admin Authentication
- ✅ Firebase Authentication required
- ✅ User must have `role: 'admin'` in Firestore
- ✅ Auto-redirect to login if not authenticated
- ✅ Session persistence with localStorage
- ✅ Secure logout

### Authorization Checks
```javascript
// Check on page load
const userDoc = await db.collection('users').doc(user.uid).get();
if (!userDoc.exists || userDoc.data().role !== 'admin') {
  // Denied - redirect to login
}
```

### Audit Trail
All administrative actions are logged:
```javascript
await db.collection('audit_logs').add({
  type: 'XP_ADJUSTED',
  message: 'Admin adjusted XP for user...',
  timestamp: serverTimestamp(),
  adminId: auth.currentUser.uid,
  adminEmail: auth.currentUser.email
});
```

---

## 📊 Data Architecture

### Collections Structure

```
firestore/
├── users/
│   ├── {userId}/
│   │   ├── tasks/
│   │   │   └── {taskId} { title, status, dueDate, priority, subject, createdAt, completedAt }
│   │   ├── study_sessions/
│   │   │   └── {sessionId} { technique, status, startTime, endTime, durationMinutes, taskId }
│   │   └── achievements/
│   │       └── {achievementId} { title, category, unlockedAt, xpAwarded }
│   └── { name, email, role, level, xp, studyPoints, currentStreak, lastActive, preferredTechnique }
│
├── subjects/
│   └── {subjectId} { code, name, category, department, color, createdAt, createdBy }
│
├── feedback/
│   └── {feedbackId} { userId, type, message, status, createdAt, resolvedAt, resolvedBy }
│
└── audit_logs/
    └── {logId} { type, message, timestamp, adminId, adminEmail }
```

---

## 🎨 UI/UX Features

### Theme Support
- ✅ Dark mode (default)
- ✅ Light mode
- ✅ System preference detection
- ✅ Persistent theme storage
- ✅ Smooth transitions
- ✅ Chart.js theme adaptation

### Responsive Design
- ✅ Mobile-optimized sidebar (slide-out)
- ✅ Tablet-optimized grid layouts
- ✅ Desktop full-width tables
- ✅ Touch-friendly buttons
- ✅ Collapsible navigation

### Accessibility
- ✅ ARIA labels on interactive elements
- ✅ Keyboard navigation support
- ✅ Focus indicators
- ✅ Screen reader friendly
- ✅ High contrast mode compatible

### Performance Optimizations
- ✅ Chart.js lazy initialization
- ✅ Data caching in global variables
- ✅ Debounced search inputs
- ✅ Conditional rendering
- ✅ Efficient Firestore queries

---

## 🚀 Setup Instructions

### Prerequisites
1. Firebase project configured
2. Firestore database enabled
3. Authentication enabled (Email/Password, Google)
4. Admin user created with `role: 'admin'`

### Installation Steps

1. **Configure Firebase**
   ```javascript
   // Update js/app.js with your Firebase config
   const firebaseConfig = {
     apiKey: "YOUR_API_KEY",
     authDomain: "YOUR_PROJECT.firebaseapp.com",
     projectId: "YOUR_PROJECT_ID",
     // ... other config
   };
   ```

2. **Create Admin User**
   ```bash
   # Use create_admin_user.js or Firebase Console
   node create_admin_user.js
   ```

3. **Deploy to Firebase Hosting**
   ```bash
   firebase deploy --only hosting
   ```

4. **Access Admin Panel**
   ```
   https://your-project.web.app/
   or
   https://your-project.firebaseapp.com/
   ```

---

## 📱 Integration with Flutter App

### Data Sync
The admin panel reads the same Firestore collections as the Flutter app:
- `users` - User profiles and settings
- `users/{uid}/tasks` - User tasks
- `users/{uid}/study_sessions` - Pomodoro/study sessions
- `users/{uid}/achievements` - Unlocked achievements

### Feedback Submission (Flutter Side)
```dart
// Add to Flutter app
Future<void> submitFeedback(String type, String message) async {
  await FirebaseFirestore.instance.collection('feedback').add({
    'userId': currentUserId,
    'type': type, // 'Suggestion', 'Bug', 'Report'
    'message': message,
    'status': 'open',
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

### Subject Synchronization
Subjects created in admin panel are immediately available in Flutter app:
```dart
// Flutter app can read subjects
final subjectsSnapshot = await FirebaseFirestore.instance
    .collection('subjects')
    .get();
```

---

## 🔧 Customization Guide

### Adding New Metrics

1. **Update data loading**:
```javascript
async function loadNewMetric() {
  const snapshot = await db.collection('new_collection').get();
  globalNewData = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}
```

2. **Add to initialization**:
```javascript
await Promise.all([
  loadUsers(),
  loadTasks(),
  loadNewMetric() // Add here
]);
```

3. **Create render function**:
```javascript
function renderNewMetric() {
  // Chart or table rendering logic
}
```

### Adding New Charts

```javascript
function renderMyNewChart() {
  const ctx = document.getElementById('myNewChart');
  if (ctx && ctx.chart) ctx.chart.destroy();
  
  if (ctx) {
    ctx.chart = new Chart(ctx, {
      type: 'bar', // or 'line', 'pie', 'doughnut'
      data: {
        labels: [...],
        datasets: [{ data: [...], backgroundColor: '#6C9EF8' }]
      },
      options: { responsive: true, maintainAspectRatio: false }
    });
  }
}
```

### Adding New Admin Actions

```javascript
async function myNewAction(userId) {
  const user = globalUsers.find(u => u.id === userId);
  
  // Confirmation
  const confirmed = await openConfirm('Title', 'Message');
  if (!confirmed) return;
  
  try {
    // Firestore update
    await db.collection('users').doc(userId).update({ /* changes */ });
    
    // Audit log
    await logAuditEvent('MY_ACTION', `Admin did something to ${user.name}`);
    
    // Reload data
    await loadUsers();
    renderUserTable();
    
    alert('✅ Success!');
  } catch (error) {
    console.error('Error:', error);
    alert('❌ Failed: ' + error.message);
  }
}
```

---

## 🐛 Troubleshooting

### Issue: Charts not displaying
**Solution**: Ensure Chart.js CDN is loaded and canvas elements have correct IDs.

### Issue: No data showing
**Solution**: Check Firestore rules and ensure admin user has read access to all collections.

### Issue: Authentication loop
**Solution**: Clear localStorage and ensure user document has `role: 'admin'`.

### Issue: Slow loading
**Solution**: Add Firestore indexes for common queries:
```javascript
// Create composite indexes in Firebase Console
users/{uid}/tasks
  - status (ascending)
  - createdAt (descending)
```

---

## 📈 Future Enhancements

### Planned Features
- [ ] Real-time data updates (Firestore onSnapshot)
- [ ] Export data to CSV/Excel
- [ ] Advanced filtering and sorting
- [ ] Bulk user operations
- [ ] Email notifications to users
- [ ] Push notification management
- [ ] A/B testing dashboard
- [ ] Revenue analytics (if monetized)
- [ ] User behavior heatmaps
- [ ] Predictive analytics (ML integration)

### Advanced Analytics (Bonus)
- [ ] Weekly study heatmap
- [ ] Forecast student load
- [ ] Identify struggling students (low completion rates)
- [ ] Peak stress period prediction
- [ ] Technique effectiveness comparison
- [ ] Retention rate analysis

---

## 📞 Support

For issues or feature requests:
1. Check Firestore console for data integrity
2. Review browser console for JavaScript errors
3. Verify Firebase Authentication and Rules
4. Check audit logs for admin action history

---

## 📄 License

Part of IntelliPlan Study App - Capstone Project
