# UI Redesign Implementation Plan - IntelliPlan

## Design Specifications

### Color Palette
✅ **COMPLETED** - Updated in `lib/config/theme.dart`
- Background: `#121212` (bg/base)
- Surface: `#2C2C2C` (surface/high)
- Input: `#2A2A2A` (inputBg)
- Primary: `#7F5AF0` (violet)
- Success: `#2CB67D` (green)
- Alert: `#F25F4C` (red)
- Warning: `#FF9F43` (orange)
- Text Primary: `#FFFFFF` (white)
- Text Secondary: `#A1A1A1` (gray)

### Typography
✅ **COMPLETED** - Updated in `lib/config/theme.dart`
- **Titles**: Poppins Bold (18-36sp)
- **Body**: Inter Regular/Medium (14-18sp)
- **Labels**: Manrope Medium (12-14sp)
- **Inputs**: DM Sans (16sp)

---

## Implementation Status

### ✅ Phase 1: Foundation (COMPLETED)
1. **Theme & Colors** - `lib/config/theme.dart`
   - Updated all colors to match design spec
   - Configured font families (Poppins, Inter, Manrope, DM Sans)
   - Set up dark theme as primary
   - Input decoration theme with proper styling

2. **Splash Screen** - `lib/screens/splash/splash_screen.dart`
   - 2-second duration with fade + scale animation
   - Center logo (lightbulb icon)
   - Background: #121212
   - Version text at bottom
   - Auto-navigates to Welcome screen

3. **Welcome Screen** - `lib/screens/welcome/welcome_screen.dart`
   - Gradient background (violet → base)
   - Large logo with tagline: "Smarter Scheduling Starts Here"
   - "Get Started" button (white bg, violet text)
   - "Sign In" link for existing users
   - Navigates to Registration flow

---

### 🔄 Phase 2: Authentication Flow (IN PROGRESS)

#### Next Steps:

1. **Registration Flow** (Multi-step)
   - **Step 1**: Name + Birthdate
     - Text field for full name
     - Date picker for birthdate
     - Background: #121212, Card: #2C2C2C
     - Progress indicator (1/4)
   
   - **Step 2**: Gender + Student Status
     - Chip group for gender selection
     - Optional student status toggle
     - Progress indicator (2/4)
   
   - **Step 3**: Study Preference (KEY FEATURE)
     - 3 vertical cards:
       - **Pomodoro**: "Work in short focused bursts with breaks"
       - **Spaced Repetition**: "Review at intervals to improve memory"
       - **Active Recall**: "Test yourself to strengthen learning"
     - Each card: bg #2C2C2C, selected border #7F5AF0
     - Progress indicator (3/4)
   
   - **Step 4**: Confirmation
     - Summary of selections
     - "Great! We'll tailor IntelliPlan for you 🎯"
     - Continue button → Auth screen

2. **Update Login/Signup Screens**
   - Remove Facebook sign-in completely
   - Keep only Google Sign-In
   - Update UI:
     - Background: #121212
     - Form panel: #2C2C2C, 16dp radius
     - Inputs: #2A2A2A bg, white text, #A1A1A1 hint
     - Focus border: #7F5AF0
     - Button: #7F5AF0 bg
     - Error text: #F25F4C, Manrope 12sp

---

### 📋 Phase 3: Home Screen Redesign (PENDING)

#### Components to Build:

1. **Today at a Glance Card**
   - Card bg: #2C2C2C, 16dp radius, 16dp padding
   - Label: "Next Task" (Manrope 12sp, #A1A1A1)
   - Task title: Poppins Bold 16sp, white
   - Time: Manrope 14sp, #A1A1A1
   - CTA: "Start Focus" button (#7F5AF0)

2. **Week Bar**
   - Container bg: #1E1E1E, height 64dp
   - Mon-Sun circles:
     - Selected: bg #7F5AF0, text white
     - Unselected: transparent, text #A1A1A1
   - Inter Medium 12sp for day labels

3. **Upcoming Tasks List**
   - Task Cards: #2C2C2C bg, 16dp radius
   - Subject chips with colors (Math=blue, Eng=green)
   - Actions: Edit (#7F5AF0), Delete (#F25F4C), Done (#2CB67D)
   - Empty state: "No tasks scheduled today"

4. **Tips Carousel**
   - Horizontal scroll
   - Card: 280x160dp, #2C2C2C bg
   - Inter Regular 14sp, emoji 32dp

5. **Quick Add Input**
   - Inline text field + add button
   - Input bg: #2A2A2A, 48dp height
   - Add button: circle #7F5AF0, 48dp

6. **FAB (Floating Action Button)**
   - Default: #7F5AF0, 56dp, + icon
   - **Radial Expansion** (5 shortcuts):
     1. Schedule/Task → 📅 #7F5AF0
     2. Gamification/Rewards → 🏆 #2CB67D
     3. Group/Collab → 👥 #F25F4C
     4. Dashboard → 📊 #FF9F43
     5. Settings → ⚙️ #A1A1A1
   - Each mini FAB: 48dp circle, white icon 20dp

---

### 📊 Phase 4: Task Board (Kanban) (PENDING)

**Rename**: "My Tasks" → **"Planner"** or **"Task Board"**

#### Features:

1. **3 Kanban Columns**
   - **To Do**: Label #7F5AF0 (violet)
   - **In Progress**: Label #FF9F43 (orange)
   - **Done**: Label #2CB67D (green)
   - Horizontal swipe between columns
   - Manrope SemiBold 14sp for headers

2. **Task Cards**
   - Reuse existing Task Card design
   - Drag & drop between columns
   - Title: Poppins Bold 16sp
   - Subject chip with color
   - Time: Manrope 14sp, #A1A1A1

3. **Task History Section**
   - Toggle/tab at top
   - Grouped by month
   - Compressed cards (64dp height)
   - Completed tasks: strikethrough, faded

4. **Sorting & Filters**
   - Dropdown: bg #2A2A2A, 12dp radius
   - Options:
     - By Subject
     - By Priority (High/Medium/Low)
     - Alphabetical (A-Z)
     - Deadline (Soonest → Latest)
   - Active item: #7F5AF0

5. **FAB**
   - + icon to add new task
   - Optional radial expansion

---

### ⏱️ Phase 5: Focus Timer + Plant (PENDING)

1. **Timer Screen**
   - Big numeric: Roboto 48sp
   - Ring stroke: #7F5AF0 (accent)
   - Background ring: #333333
   - Control buttons: 48x48 circular, #2C2C2C bg
   - Session presets: 25/5, custom, auto-start toggle

2. **Digital Plant Card**
   - Card bg: #2C2C2C
   - Plant asset/illustration
   - "Keep focus to grow your plant 🌱"
   - Small progress bar: #7F5AF0 or #2CB67D

---

### 📈 Phase 6: Dashboard Analytics (PENDING)

1. **Bar Chart** (Weekly Productivity)
   - Fill: #7F5AF0
   - Grid lines: #333333 (subtle)

2. **Pie Chart** (Task Types)
   - Use accent colors:
     - Primary: #7F5AF0
     - Success: #2CB67D
     - Alert: #F25F4C
   - Legend chips with colored indicators

3. **Calendar Preview**
   - Surface bg: #1E1E1E
   - Today badge highlight
   - Active days: #7F5AF0

4. **Dynamic Tips Card**
   - Same as Tips Carousel on Home

---

### 👥 Phase 7: Collaboration (PENDING)

**Kanban Board for Groups**:
- Columns: Backlog / In Progress / Done
- Reuse Task Card shell
- Share/invite functionality
- #2C2C2C cards on #121212 bg

---

### 👤 Phase 8: Profile & Settings (PENDING)

- Avatar + name + email
- Theme preference (stays dark)
- Notifications toggle
- Study preferences (editable from onboarding)
- Data export option

---

### 🔧 Phase 9: Admin Panel (Web) (FUTURE)

- Overview dashboard (totals, weekly growth)
- Task log table with filters
- Alt row shading: #1E1E1E
- Status pills with colored backgrounds

---

## Files Created So Far

### New Files:
1. `lib/screens/splash/splash_screen.dart` ✅
2. `lib/screens/welcome/welcome_screen.dart` ✅

### Modified Files:
1. `lib/config/theme.dart` ✅ (complete redesign)

---

## Next Immediate Steps

1. Create Registration Flow (4 screens)
2. Update Login/Signup screens (remove Facebook)
3. Update routing in `lib/config/routes.dart`
4. Add route handlers for new screens
5. Test navigation flow: Splash → Welcome → Registration → Auth → Home

---

## Design System Quick Reference

### Spacing
- Card padding: 16dp
- Section spacing: 20dp
- Button padding: 24h x 16v

### Border Radius
- Cards: 16dp
- Buttons: 12dp
- Inputs: 12dp
- Chips: varies (usually 16-20dp)

### Elevation
- Cards: elevation 1 (subtle shadow)
- FAB: elevation 8
- Buttons: elevation 0

### Icon Sizes
- Small: 16dp
- Medium: 20dp
- Large: 24dp
- Button icons: 20dp
- FAB icon: 24dp
- Emoji/illustrations: 32dp

---

## Notes

- All screens use dark theme by default (#121212 background)
- Google Sign-In is the only SSO method
- Gamification system is already implemented (previous work)
- Focus on mobile-first design
- Use Smart Animate in Figma for smooth transitions
- Maintain consistency with color palette across all screens

---

*Last Updated: Implementation in progress - Phase 1 complete, Phase 2 starting*
