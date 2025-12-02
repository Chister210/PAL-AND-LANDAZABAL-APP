# Quick Start Guide - Smart Scheduling System

## 🚀 Getting Started

Your IntelliPlan app now has a **fully functional Smart Scheduling System** integrated with Firebase!

## 📱 How to Use

### Access the Schedule
1. Open IntelliPlan app
2. Tap the **hamburger menu** (☰) in the top-right
3. Select **"Schedule"** from the menu
4. You'll see three tabs: **Classes**, **Assignments**, and **Tasks**

---

## 📚 Adding a Class Schedule

1. Go to **Classes** tab
2. Tap the **floating "+" button** at the bottom
3. Fill in the form:
   - **Course Code**: e.g., "CS101"
   - **Course Name**: e.g., "Intro to Programming"
   - **Instructor**: e.g., "Dr. Smith"
   - **Location**: e.g., "Room 305"
   - **Day**: Select from dropdown (Monday-Sunday)
   - **Start Time**: Tap to open time picker
   - **End Time**: Tap to open time picker
4. Tap **"Add Class"**
5. ✅ Your class appears in the weekly schedule!

**Features:**
- ⏰ Automatic conflict detection (prevents double-booking)
- 🎨 Color-coded class cards
- 📍 Shows instructor, location, and time
- 👆 Tap any class to view details or delete

---

## 📝 Adding an Assignment

1. Go to **Assignments** tab
2. Tap the **floating "+" button**
3. Fill in the form:
   - **Title**: e.g., "Research Paper on AI"
   - **Description**: Details about the assignment
   - **Course Code**: e.g., "CS101"
   - **Due Date**: Tap to select date
   - **Priority**: Choose Low/Medium/High/Urgent
   - **Estimated Hours**: How long it will take
4. Tap **"Add Assignment"**
5. ✅ Assignment appears in upcoming list!

**Features:**
- 🚨 Automatic overdue detection
- 📊 Priority-based color coding
- 📅 "Days until due" countdown
- ✓ Mark as complete when done
- 🔴 Overdue section shows missed deadlines

**Priority Colors:**
- 🟢 Low = Green
- 🔵 Medium = Blue
- 🟠 High = Orange
- 🔴 Urgent = Red

---

## ✅ Adding a Study Task

1. Go to **Tasks** tab
2. Tap the **floating "+" button**
3. Fill in the form:
   - **Task Title**: e.g., "Study for Midterm"
   - **Description**: Task details
   - **Course Code**: (Optional) e.g., "CS101"
   - **Task Type**: Select from dropdown
     - 📖 Study
     - 🔄 Review
     - ✏️ Practice
     - 👥 Collaborative
     - ➕ Other
   - **Scheduled Date**: Tap to select
   - **Scheduled Time**: Tap to select
   - **Duration**: Minutes (e.g., 30, 60, 90)
   - **Collaborative**: Toggle ON for team tasks
4. Tap **"Add Task"**
5. ✅ Task appears on scheduled date!

**Features:**
- 📆 Date selector to navigate days
- ☑️ Check off tasks as you complete them
- ⏱️ Duration tracking
- 👥 Team collaboration support
- 🎨 Type-based color coding

---

## 🏠 Home Screen Integration

Your home screen now shows:
- **Today's Tasks**: All tasks scheduled for today
- **Team Tasks**: Collaborative tasks from your teams
- **My Subjects**: Your enrolled courses

All data syncs automatically with Firebase! 🔄

---

## 💡 Pro Tips

### Avoid Time Conflicts
The system automatically prevents you from adding classes at the same time on the same day. If you try to add a conflicting class, you'll see an error message.

### Stay on Track
- Assignments turn **red** when overdue
- Today's tasks show only **pending** items
- Complete items to remove them from the list

### Organize by Priority
Use assignment priorities to focus on what matters:
1. **Urgent** - Due very soon, high impact
2. **High** - Important assignments
3. **Medium** - Regular work
4. **Low** - Can be done when you have time

### Plan Collaboratively
- Mark tasks as **Collaborative** to share with team
- Course codes link tasks to specific classes
- Estimated hours help you budget time

---

## 🔄 Real-Time Sync

All your schedule data:
- ✅ Saves to Firebase Firestore
- ✅ Syncs across all your devices
- ✅ Works offline (syncs when back online)
- ✅ Updates instantly when changed

---

## 📊 What's Stored in Firebase

Every time you add something, it's saved to:

```
users/
  {your-user-id}/
    classes/       ← Your class schedules
    assignments/   ← Your assignments
    tasks/         ← Your study tasks
```

All data is **private and secure** - only you can access your schedule!

---

## 🎯 Example Usage Scenario

**Monday Morning:**
1. Add all your classes for the week
2. Add assignments due this week
3. Create study tasks for each subject

**During the Week:**
- Check "Today's Tasks" on home screen
- Mark tasks complete as you finish
- Add new assignments as they're announced

**Before Deadlines:**
- Check "Upcoming Assignments"
- See overdue items in red
- Plan study sessions accordingly

---

## 🐛 Troubleshooting

**"Data not loading"**
- Make sure you're logged in
- Check your internet connection
- Try logging out and back in

**"Can't add class"**
- Check for time conflicts
- Make sure all fields are filled
- Verify times are valid (end > start)

**"Tasks not showing"**
- Check the selected date (use arrows)
- Make sure task has a scheduled date
- Verify task isn't marked complete

---

## 🎉 You're All Set!

Your Smart Scheduling System is **fully functional and ready to use**!

Start by adding:
1. ✅ Your class schedule for this week
2. ✅ Any upcoming assignments
3. ✅ Study tasks for today

Happy planning! 📚✨
