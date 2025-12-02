# ✅ Testing Checklist - IntelliPlan Subject Management

## 🎯 Quick Visual Verification Guide

### Test 1: Task History Fix
**Location:** Planner → Task Board → History Tab

**Expected Behavior:**
1. ✅ If no completed tasks → Shows "No history data yet" message
2. ✅ Shows "Add tasks to see your history here" subtitle
3. ✅ Displays "Add Task" button
4. ✅ Clicking button switches to board view
5. ✅ No "Error loading history" message appears

---

### Test 2: Add Subject Dialog (Image 1 Match)
**Location:** Home Screen → My Subjects → "+ Add Subject"

**Visual Checklist:**
- ✅ Dialog title: "Add Subject" with book icon
- ✅ Subject name TextField (required)
- ✅ Schedule section with 7 weekday chips (Sun-Sat)
  - Can select multiple days
  - Selected chips are highlighted
- ✅ Start Time picker (shows TimeOfDay picker on tap)
- ✅ End Time picker (shows TimeOfDay picker on tap)
- ✅ Field of Study radio buttons:
  - Minor Subject
  - Major Subject
- ✅ Attach Files area:
  - Dashed border
  - Shows file count when files attached
  - Clicking opens file attach dialog
- ✅ Additional Notes TextField (multiline, 4 lines)
- ✅ Footer buttons:
  - CANCEL (left, dismisses dialog)
  - SAVE (right, blue/accent color)

**Test Validation:**
1. Leave name empty → Click SAVE → Should show error
2. Select no days → Click SAVE → Should show error
3. Don't select time → Click SAVE → Should show error
4. Fill all required fields → Click SAVE → Should create subject

---

### Test 3: Subject Cards Display (Image 2 Match)
**Location:** Home Screen → My Subjects Section

**Visual Checklist:**
- ✅ Horizontal scrollable list of subject cards
- ✅ Each card shows:
  - Subject name (bold, 16px)
  - Schedule days (e.g., "Mon, Wed, Fri")
  - Time range (e.g., "9:00 AM - 10:30 AM" in accent color)
- ✅ Three action buttons below (horizontally aligned):
  1. **Edit** (pencil icon)
  2. **Delete** (trash icon, red)
  3. **Attach** (paperclip icon)
- ✅ Last card is "+ Add Subject" with dashed border
- ✅ All cards have rounded corners and subtle border

**Test Actions:**
1. Create 2-3 subjects → Should scroll horizontally
2. Click Edit → Opens dialog with subject data pre-filled
3. Click Delete → Shows confirmation dialog
4. Click Attach → Opens attach files dialog

---

### Test 4: Delete Confirmation (Image 3 Match)
**Location:** Home Screen → Subject Card → Delete Button

**Visual Checklist:**
- ✅ Dialog title: "Confirm Delete Subject?"
- ✅ Message: "Are you sure that you are going to delete this subject \"[Subject Name]\"?"
- ✅ Two buttons:
  - CANCEL (left, gray text)
  - CONFIRM (right, red background, white text)
- ✅ Rounded corners on dialog

**Test Actions:**
1. Click CANCEL → Dialog dismisses, subject remains
2. Click CONFIRM → Subject card disappears
3. After confirm → Success snackbar appears
4. Deleted subject no longer in Firestore

---

### Test 5: Attach Files Dialog (Image 4 Match)
**Location:** Subject Card → Attach Button OR Add Subject Dialog → Attach Files Area

**Visual Checklist:**
- ✅ Dialog title: "Attach Files"
- ✅ Subtitle: Shows subject name
- ✅ Attach area:
  - Dashed border
  - Note/file icon
  - Text: "+ Attach Files Here"
- ✅ File list (if files attached):
  - File icon + filename
  - File size in MB (e.g., "2.5 MB")
  - Remove button (X icon, red)
- ✅ Footer buttons:
  - CANCEL (left)
  - SAVE (right, accent color)

**Test Actions:**
1. Click attach area → Opens file picker (currently simulated)
2. Select file → Appears in list with size
3. Click X on file → File removed from list
4. Click SAVE → Files attached to subject
5. Click CANCEL → Changes discarded

---

### Test 6: Task Auto-Move to In Progress
**Location:** Planner → Task Board

**Expected Behavior:**
1. ✅ Click "+" to add new task
2. ✅ Fill in task details (title, subject, date, etc.)
3. ✅ Click CREATE
4. ✅ Task appears in "In Progress" column (NOT "To Do")
5. ✅ Task has status 'in_progress' in Firestore

**Verification:**
- Check Firebase Console → tasks collection
- New task should have `status: "in_progress"`
- NOT `status: "pending"`

---

### Test 7: Analytics Help Button
**Location:** Analytics Screen → AppBar → "?" Icon

**Visual Checklist:**
- ✅ Help icon (?) visible in top right of AppBar
- ✅ Clicking opens dialog titled "Analytics Help"
- ✅ Dialog contains explanations for:
  - Smart Insights
  - Overview Cards
  - Weekly Productivity
  - AI Recommendations
  - Productivity Patterns
  - Study Techniques
  - Deadline Pressure
  - Optimal Study Times
- ✅ Each item has icon + title + description
- ✅ Scrollable content
- ✅ "GOT IT" button at bottom

---

### Test 8: Analytics Overflow Fixes
**Location:** Analytics Screen → All Sections

**Visual Checklist:**
- ✅ No red overflow indicators anywhere
- ✅ Productivity Patterns section displays correctly
- ✅ Time Slot cards don't overflow
- ✅ All text wraps properly
- ✅ Works on different screen sizes/orientations

---

## 🔍 Edge Cases to Test

### Subject Management
- [ ] Create subject with very long name (30+ characters)
- [ ] Create subject with all 7 days selected
- [ ] Create subject with only 1 day selected
- [ ] Edit subject and change all fields
- [ ] Delete subject with attached files
- [ ] Create 10+ subjects (test horizontal scrolling)

### Task Management
- [ ] Create task without selecting date (should default to tomorrow)
- [ ] Create task with all priority levels (Low, Medium, High)
- [ ] Complete task and verify it appears in history
- [ ] Create multiple tasks and verify all go to In Progress

### UI/UX
- [ ] Rotate device → UI adapts correctly
- [ ] Navigate away and back → data persists
- [ ] Logout and login → subjects/tasks reload correctly
- [ ] Slow internet → loading states display properly

---

## 📊 Performance Tests

### Loading Speed
- [ ] Home screen loads in < 2 seconds
- [ ] Subject list loads in < 1 second
- [ ] Task board loads in < 2 seconds
- [ ] Analytics loads in < 3 seconds

### Memory Usage
- [ ] No memory leaks when opening/closing dialogs
- [ ] Subject images/files don't cause memory spikes
- [ ] Smooth scrolling with 20+ subjects

---

## 🐛 Known Issues / Limitations

### Current Implementation
1. **File Picker:** Using simulated files (adds dummy data)
   - **Fix Needed:** Integrate real `file_picker` package
   - **Priority:** Medium
   - **Effort:** 1 hour

2. **File Upload:** Files not actually uploaded to Firebase Storage
   - **Fix Needed:** Implement Storage upload in SubjectService
   - **Priority:** Medium
   - **Effort:** 2 hours

3. **Background Notifications:** Not implemented yet
   - **Fix Needed:** See IMPLEMENTATION_COMPLETE_SUMMARY.md
   - **Priority:** High (user requested)
   - **Effort:** 3 hours

4. **Firestore Indexes:** Need to be created manually
   - **Fix Needed:** Create in Firebase Console
   - **Priority:** High (prevents query errors)
   - **Effort:** 10 minutes

---

## ✅ Sign-Off Checklist

Before considering this feature complete:

### Functionality
- [x] All 4 images matched (Add, Display, Delete, Attach)
- [x] Task history shows helpful empty state
- [x] Tasks auto-move to In Progress
- [x] Analytics help button works
- [x] No overflow errors
- [ ] Background notifications work
- [ ] Real file picker integrated
- [ ] Files upload to Storage

### Code Quality
- [x] No compilation errors
- [x] All imports resolved
- [x] Proper error handling
- [x] Loading states on async operations
- [x] User feedback (SnackBars)
- [x] Reactive UI with Provider

### Testing
- [ ] Manual testing completed
- [ ] Edge cases tested
- [ ] Performance acceptable
- [ ] Works on physical device
- [ ] Firebase indexes created
- [ ] Production environment tested

### Documentation
- [x] Implementation summary created
- [x] Testing checklist created
- [x] Code commented where needed
- [ ] User guide created (optional)

---

## 📝 Test Results Template

Copy this template to record your test results:

```
Date: ___________
Tester: ___________
Build: ___________

Test 1 - Task History: [ ] Pass [ ] Fail
Notes: _________________________________

Test 2 - Add Subject: [ ] Pass [ ] Fail
Notes: _________________________________

Test 3 - Subject Cards: [ ] Pass [ ] Fail
Notes: _________________________________

Test 4 - Delete Confirmation: [ ] Pass [ ] Fail
Notes: _________________________________

Test 5 - Attach Files: [ ] Pass [ ] Fail
Notes: _________________________________

Test 6 - Task Auto-Move: [ ] Pass [ ] Fail
Notes: _________________________________

Test 7 - Analytics Help: [ ] Pass [ ] Fail
Notes: _________________________________

Test 8 - No Overflow: [ ] Pass [ ] Fail
Notes: _________________________________

Overall Status: [ ] All Pass [ ] Issues Found
```

---

**Happy Testing! 🚀**
