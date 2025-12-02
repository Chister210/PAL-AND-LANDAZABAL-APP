    # IntelliPlan App - Complete Testing Guide

## 📱 Application Overview
IntelliPlan is a comprehensive productivity app for students that combines smart scheduling, prescriptive analytics, and proven study techniques to maximize academic performance.

## 🎯 Core Features Implementation

### 1. **Dashboard** (`/`)
**Functionality:**
- Dynamic time-based greeting (Good Morning/Afternoon/Evening)
- Current date display
- Quick action buttons to launch Pomodoro or Flashcards
- Today's schedule overview (classes and tasks)
- AI-powered study recommendations
- Upcoming assignments with color-coded urgency
- Smooth fade-in animation on load

**Testing:**
- [ ] Verify greeting changes based on time of day
- [ ] Click "Pomodoro" button → navigates to Pomodoro timer
- [ ] Click "Flashcards" button → navigates to Spaced Repetition
- [ ] Check "View All" buttons navigate to Schedule and Analytics
- [ ] Verify empty states show when no data exists

---

### 2. **Pomodoro Timer** (`/pomodoro`)
**Functionality:**
- 25-minute work sessions with 5-minute breaks
- Large circular timer with animated progress ring
- Color-coded states: Purple (work), Green (short break), Orange (long break)
- Session counter tracking (4 work sessions = 1 long break)
- Start/Pause/Resume/Stop/Skip controls
- Settings dialog to customize durations
- Topic/course tagging for sessions
- Automatic session recording to Firebase
- Pomodoro technique tips display

**Testing:**
- [ ] Start timer → verify 25:00 countdown begins
- [ ] Pause → resume → verify time continues correctly
- [ ] Complete work session → auto-switches to break
- [ ] Complete 4 work sessions → triggers long break
- [ ] Skip button → advances to next phase
- [ ] Settings → modify durations → verify changes apply
- [ ] Stop → verify session saves to database
- [ ] Check productivity score calculation

**Animations:**
- [ ] Circular progress ring animates smoothly
- [ ] Color transitions between states
- [ ] Button state changes (play/pause icon)

---

### 3. **Spaced Repetition Flashcards** (`/spaced-repetition`)
**Functionality:**
- **Deck Management:**
  - Create custom decks
  - Add cards with question/answer/course
  - View deck statistics (new/learning/mastered cards)
  - Due cards counter with red badge
  
- **Card Review System:**
  - 3D flip animation (600ms)
  - Question side (purple gradient) / Answer side (green gradient)
  - Difficulty rating: Easy (green), Medium (orange), Hard (red)
  - SM-2 algorithm scheduling next review dates
  - Progress bar during review session
  - Completion screen with statistics
  
- **Empty States:**
  - No decks: Shows create deck prompt
  - No due cards: Shows completion message

**Testing:**
- [ ] Create new deck with name
- [ ] Add flashcards (front/back/course)
- [ ] Start review → verify cards appear
- [ ] Click card → 3D flip animation plays
- [ ] Rate difficulty → verify next review scheduled
- [ ] Complete all cards → see completion screen
- [ ] Check deck statistics update correctly
- [ ] Verify SM-2 algorithm (easy cards = longer intervals)

**Animations:**
- [ ] 3D card flip with rotateY transform
- [ ] Gradient color transitions
- [ ] Progress bar updates smoothly
- [ ] Badge animations on deck cards

---

### 4. **Schedule/Calendar** (`/schedule`)
**Functionality:**
- **Three Tabs:**
  1. **Classes Tab:**
     - Weekly class schedule organized by day
     - Class cards showing course code, name, instructor, location, time
     - Color-coded left border for each class
     - Time display with duration
     - Conflict detection (red warnings)
     
  2. **Assignments Tab:**
     - Overdue section (red highlight)
     - Upcoming assignments (color-coded by urgency)
     - Priority indicators (urgent/high/medium/low)
     - Days until due countdown
     - Status chips (pending/in progress/completed)
     
  3. **Tasks Tab:**
     - Date selector with navigation
     - Today's tasks with checkboxes
     - Color-coded by task type
     - Duration and time display
     - Collaborative task support

- **Add Dialogs:**
  - Add Class: Course info, day, start/end time
  - Add Assignment: Title, description, due date, priority, estimated hours
  - Add Task: Title, description, type, date, duration

- **Detail Views:**
  - Bottom sheets with full information
  - Edit/Delete options
  - Mark as complete functionality

**Testing:**
- [ ] Switch between tabs (Classes/Assignments/Tasks)
- [ ] Add new class → verify appears on correct day
- [ ] Add assignment → check priority color coding
- [ ] Add task → verify checkbox functionality
- [ ] Click event → view details modal
- [ ] Mark assignment complete → status updates
- [ ] Delete class → confirm removal
- [ ] Test conflict detection (overlapping classes)
- [ ] Navigate dates → verify correct tasks show

---

### 5. **Analytics Dashboard** (`/analytics`)
**Functionality:**
- **Overview Cards:**
  - Total study sessions count
  - Today's sessions
  - Total study time (hours + minutes)
  - Gradient backgrounds with icons
  
- **Weekly Productivity Chart:**
  - 7-day bar chart
  - Minutes studied per day
  - Gradient bars (blue to purple)
  - Hover tooltips showing exact values
  - Animated rendering
  
- **AI Recommendations:**
  - Personalized study suggestions based on patterns
  - Confidence percentage badges
  - Three types: Optimal (green), Avoid (red), Suggestion (blue)
  - Recommendations update as you study more
  
- **Productivity Patterns:**
  - Morning/Afternoon/Evening/Night breakdown
  - Session count per time slot
  - Average productivity score (out of 10)
  - Progress bars with color coding
  - Icon indicators for each time period
  
- **Study Techniques Breakdown:**
  - Pomodoro usage count
  - Spaced Repetition usage
  - Active Recall sessions
  - Visual icons and counts

**Testing:**
- [ ] Verify overview cards show correct totals
- [ ] Complete study session → stats update
- [ ] Check bar chart renders correctly
- [ ] Hover over bars → see tooltips
- [ ] Verify recommendations appear after 5+ sessions
- [ ] Check confidence percentages are accurate
- [ ] Productivity patterns group by time correctly
- [ ] Refresh button → re-analyzes data
- [ ] Empty state shows when no data exists

**Animations:**
- [ ] Fade-in animation on screen load
- [ ] Chart bars animate upward
- [ ] Progress bars fill smoothly
- [ ] Card hover effects

---

## 🔥 Firebase Backend Integration

### Collections Structure:
```
users/
  {userId}/
    classes/          → ClassSchedule objects
    assignments/      → Assignment objects
    tasks/           → StudyTask objects
    study_sessions/  → StudySession objects (from Pomodoro)
    flashcards/      → Flashcard objects with SM-2 data
```

### Real-time Features:
- All data syncs to Firestore automatically
- Changes reflect across sessions
- Conflict detection uses real-time data
- Analytics calculated from live data

**Testing:**
- [ ] Add data → check Firebase console for new documents
- [ ] Delete data → verify removal in Firebase
- [ ] Complete session → verify study_session document created
- [ ] Review flashcard → verify SM-2 fields update

---

## 🎨 Design Features

### Color System:
- **Pomodoro:** Red/Purple gradient
- **Flashcards:** Green/Teal gradient
- **Schedule:** Blue theme
- **Analytics:** Orange/Yellow gradient
- **Assignments:** Priority-based (Red/Orange/Blue/Green)

### Animations:
- Fade-in transitions (600-800ms)
- 3D card flips (600ms)
- Circular progress rings
- Smooth color transitions
- Button hover states
- Modal slide-ups

### Modern UI Elements:
- Card-based layouts with elevation
- Gradient backgrounds
- Rounded corners (12px)
- Icon badges with counts
- Color-coded borders
- Progress indicators
- Empty state illustrations

---

## 🧪 Testing Workflows

### Workflow 1: First-Time User
1. Register account
2. Dashboard shows empty states
3. Add first class via Schedule
4. Add first assignment
5. Create flashcard deck
6. Start first Pomodoro session
7. Complete session → analytics generate
8. View recommendations

### Workflow 2: Daily Usage
1. Login → see today's schedule
2. Click Pomodoro → study for 25 min
3. Take 5 min break
4. Review flashcards during break
5. Mark assignment as completed
6. Check analytics → see progress
7. Follow AI recommendations

### Workflow 3: Heavy Usage (Data Testing)
1. Add 10+ classes
2. Add 20+ assignments with various priorities
3. Complete 15+ Pomodoro sessions at different times
4. Review 50+ flashcards
5. Verify analytics calculate correctly
6. Check recommendations accuracy
7. Test schedule conflict detection

---

## 📊 Key Metrics to Verify

### Schedule Service:
- [ ] Classes appear on correct days
- [ ] Assignment due dates calculate correctly
- [ ] Tasks show on selected dates
- [ ] Conflict detection works
- [ ] Overdue assignments flagged

### Pomodoro Service:
- [ ] Timer counts down accurately
- [ ] Breaks trigger automatically
- [ ] Long break after 4 sessions
- [ ] Pause/resume maintains time
- [ ] Sessions save with productivity score

### Spaced Repetition Service:
- [ ] SM-2 algorithm schedules correctly
- [ ] Easy cards → longer intervals
- [ ] Hard cards → shorter intervals
- [ ] Due cards counted accurately
- [ ] Mastered cards stop appearing

### Analytics Service:
- [ ] Total stats calculate correctly
- [ ] Weekly chart data accurate
- [ ] Productivity patterns grouped properly
- [ ] Recommendations appear after threshold
- [ ] Confidence scores make sense

---

## 🐛 Known Limitations

1. **Auth:** Currently uses mock auth service (Firebase Auth ready but not configured)
2. **Offline:** No offline mode implemented yet
3. **Notifications:** No push notifications for assignments/breaks
4. **Collaboration:** Collaborative task features UI-only (backend needs group logic)
5. **Export:** No data export functionality yet

---

## 🚀 Performance Targets

- Dashboard load: < 1 second
- Screen transitions: < 300ms
- Chart rendering: < 500ms
- Firebase queries: < 2 seconds
- Animation frame rate: 60 FPS
- Card flip animation: Smooth 600ms

---

## 📱 Navigation Structure

```
/ (Dashboard)
├── /pomodoro → Pomodoro Timer
├── /spaced-repetition → Flashcards
├── /schedule → Schedule/Calendar
├── /analytics → Analytics Dashboard
├── /profile → User Profile
├── /login → Login Screen
└── /register → Registration Screen
```

---

## ✅ Feature Completion Status

| Feature | Backend | UI | Tested |
|---------|---------|----|----|
| Dashboard | ✅ | ✅ | ⏳ |
| Pomodoro | ✅ | ✅ | ⏳ |
| Spaced Repetition | ✅ | ✅ | ⏳ |
| Schedule/Calendar | ✅ | ✅ | ⏳ |
| Analytics | ✅ | ✅ | ⏳ |
| Classes Management | ✅ | ✅ | ⏳ |
| Assignment Tracking | ✅ | ✅ | ⏳ |
| Task Management | ✅ | ✅ | ⏳ |
| SM-2 Algorithm | ✅ | ✅ | ⏳ |
| Firebase Integration | ✅ | ✅ | ⏳ |

---

## 🎓 Academic Objectives Met

### 1. Smart Scheduling System ✅
- Implemented class schedule management
- Assignment tracking with priorities
- Collaborative task support
- Conflict detection
- Calendar view with day/week navigation

### 2. Prescriptive Analytics ✅
- Productivity pattern analysis (time of day)
- AI-powered study recommendations
- Confidence scoring based on data
- Optimal study time suggestions
- Weekly productivity tracking

### 3. Study Techniques ✅
- **Pomodoro:** Full timer with session tracking
- **Spaced Repetition:** SM-2 algorithm implementation
- **Active Recall:** Flashcard system with difficulty ratings
- All techniques track productivity for analytics

---

## 🏁 Ready for Testing!

**To Run:**
1. `flutter pub get` (already done)
2. `flutter run`
3. Test on Android/iOS device or emulator

**Test Priority:**
1. ⭐ Dashboard navigation
2. ⭐ Pomodoro timer accuracy
3. ⭐ Flashcard flip animation
4. ⭐ Schedule CRUD operations
5. ⭐ Analytics calculations
6. Firebase data persistence
7. All animations smooth
8. Empty states display
9. Error handling
10. UI responsiveness

Enjoy testing IntelliPlan! 🎉
