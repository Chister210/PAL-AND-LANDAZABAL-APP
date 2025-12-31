import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/team.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import '../../services/schedule_service.dart';
import '../../services/analytics_service.dart';
import '../../services/gamification_service.dart';
import '../../services/pomodoro_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../services/active_recall_service.dart';
import '../../services/notification_service.dart';
import '../../services/subject_service.dart';
import '../subject/add_subject_dialog.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    // Initialize services when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      final scheduleService = context.read<ScheduleService>();
      final analyticsService = context.read<AnalyticsService>();
      final gamificationService = context.read<GamificationService>();
      final pomodoroService = context.read<PomodoroService>();
      final spacedRepetitionService = context.read<SpacedRepetitionService>();
      final activeRecallService = context.read<ActiveRecallService>();
      final subjectService = context.read<SubjectService>();
      final notificationService = NotificationService();
      
      if (authService.currentUser != null) {
        final userId = authService.currentUser!.id;
        scheduleService.initializeForUser(userId);
        analyticsService.initializeForUser(userId);
        gamificationService.initializeForUser(userId);
        pomodoroService.initializeForUser(userId);
        spacedRepetitionService.initializeForUser(userId);
        activeRecallService.initializeForUser(userId);
        subjectService.initializeForUser(userId);
        notificationService.initialize(userId);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userName = authService.currentUser?.name ?? 'Planner';

    return PopScope(
      canPop: false, // Prevent accidental exit from home screen
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Show exit confirmation dialog
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceAlt,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Exit App',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            content: Text(
              'Do you want to exit IntelliPlan?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAlert,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Exit',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
        
        if (shouldExit == true && context.mounted) {
          // Exit the app
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgBase,
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.go('/analytics'),
          backgroundColor: AppTheme.accentPrimary,
          child: const Icon(Icons.auto_graph),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNavBar(),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(userName),
              const SizedBox(height: 24),
              _buildStudyTechniqueButton(),
              const SizedBox(height: 24),
              _buildCalendar(),
              const SizedBox(height: 24),
              _buildSectionHeader('Today'),
              const SizedBox(height: 12),
              _buildMyTasks(),
              const SizedBox(height: 24),
              _buildTeamTasks(),
              const SizedBox(height: 24),
              _buildMySubjects(),
            ],
          ),
        ),
      ),
      // Floating Focus Button (Bottom Right with Animation)
      Positioned(
        bottom: 85,
        right: 20,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Transform.rotate(
                angle: (1 - value) * 6.28, // Full rotation
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentPrimary.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'focusButton',
              onPressed: () => context.go('/pomodoro'),
              backgroundColor: AppTheme.accentPrimary,
              elevation: 8,
              child: const Icon(Icons.timer, size: 30, color: Colors.white),
            ),
          ),
        ),
      ),
      ],
      ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $userName',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Let’s plan your day',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: _showMenuDrawer,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.menu, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  // Show Analytics Modal when + button is clicked
  Widget _buildStudyTechniqueButton() {
    final authService = context.watch<AuthService>();
    final studyTechnique = authService.currentUser?.studyTechnique;

    if (studyTechnique == null) {
      return const SizedBox.shrink();
    }

    // Define study technique data
    Map<String, dynamic> techniqueData = {};
    switch (studyTechnique) {
      case 'Pomodoro Technique':
        techniqueData = {
          'name': 'Pomodoro',
          'icon': '🍅',
          'color': AppTheme.accentAlert,
          'route': '/pomodoro',
          'description': 'Focus in 25-minute sessions',
        };
        break;
      case 'Spaced Repetition':
        techniqueData = {
          'name': 'Spaced Repetition',
          'icon': '📚',
          'color': AppTheme.accentPrimary,
          'route': '/spaced-repetition',
          'description': 'Review at optimal intervals',
        };
        break;
      case 'Active Recall Technique':
        techniqueData = {
          'name': 'Active Recall',
          'icon': '🧠',
          'color': AppTheme.accentSuccess,
          'route': '/active-recall',
          'description': 'Test your memory actively',
        };
        break;
      default:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.go(techniqueData['route']),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              techniqueData['color'].withOpacity(0.2),
              techniqueData['color'].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: techniqueData['color'].withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: techniqueData['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  techniqueData['icon'],
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    techniqueData['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    techniqueData['description'],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: techniqueData['color'],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7;
    
    final authService = context.watch<AuthService>();
    final userId = authService.currentUser?.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) {
              return SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Use StreamBuilder to get tasks for deadline indicators
          StreamBuilder<QuerySnapshot>(
            stream: userId != null 
                ? FirebaseFirestore.instance
                    .collection('tasks')
                    .where('userId', isEqualTo: userId)
                    .snapshots()
                : null,
            builder: (context, taskSnapshot) {
              // Extract dates that have task deadlines
              final Set<String> datesWithDeadlines = {};
              if (taskSnapshot.hasData && taskSnapshot.data != null) {
                for (var doc in taskSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
                  if (dueDate != null) {
                    // Store as string key for easy lookup
                    datesWithDeadlines.add('${dueDate.year}-${dueDate.month}-${dueDate.day}');
                  }
                }
              }
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: startWeekday + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < startWeekday) {
                    return const SizedBox();
                  }
                  
                  final day = index - startWeekday + 1;
                  final isToday = day == now.day;
                  final date = DateTime(now.year, now.month, day);
                  final isSelected = _selectedDate.year == date.year &&
                      _selectedDate.month == date.month &&
                      _selectedDate.day == date.day;
                  
                  // Check if this date has a deadline
                  final dateKey = '${date.year}-${date.month}-${date.day}';
                  final hasDeadline = datesWithDeadlines.contains(dateKey);

                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _selectedDate = date;
                      });
                      
                      // Show tasks for selected date
                      if (userId != null) {
                        final tasksSnapshot = await FirebaseFirestore.instance
                            .collection('tasks')
                            .where('userId', isEqualTo: userId)
                            .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
                            .where('dueDate', isLessThan: Timestamp.fromDate(DateTime(date.year, date.month, date.day + 1)))
                            .get();
                        
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: AppTheme.surfaceAlt,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text(
                                'Tasks for ${DateFormat('MMM dd, yyyy').format(date)}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: tasksSnapshot.docs.isEmpty
                                  ? Text(
                                      'No tasks scheduled for this date.',
                                      style: GoogleFonts.inter(color: Colors.white),
                                    )
                                  : SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: tasksSnapshot.docs.length,
                                        itemBuilder: (context, index) {
                                          final taskData = tasksSnapshot.docs[index].data();
                                          return Card(
                                            color: AppTheme.surfaceHigh,
                                            margin: const EdgeInsets.only(bottom: 8),
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.task_alt,
                                                color: taskData['status'] == 'completed'
                                                    ? AppTheme.accentSuccess
                                                    : AppTheme.accentPrimary,
                                              ),
                                              title: Text(
                                                taskData['title'] ?? 'Untitled',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '${taskData['subject'] ?? 'General'} • ${taskData['priority'] ?? 'medium'} priority',
                                                style: GoogleFonts.inter(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              trailing: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: taskData['status'] == 'completed'
                                                      ? AppTheme.accentSuccess.withOpacity(0.2)
                                                      : taskData['status'] == 'in_progress'
                                                          ? AppTheme.accentWarning.withOpacity(0.2)
                                                          : AppTheme.accentPrimary.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  taskData['status']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'PENDING',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: Text(
                                    'Close',
                                    style: GoogleFonts.inter(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        // Red background for dates with deadlines, otherwise normal styling
                        color: isSelected
                            ? AppTheme.accentPrimary
                            : hasDeadline
                                ? Colors.red.withOpacity(0.7)
                                : isToday
                                    ? AppTheme.accentPrimary.withOpacity(0.3)
                                    : Colors.transparent,
                        shape: BoxShape.circle,
                        // Add red border for better visibility on deadline dates
                        border: hasDeadline && !isSelected
                            ? Border.all(color: Colors.red, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: isToday || isSelected || hasDeadline ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyTasks() {
    final authService = context.watch<AuthService>();
    final userId = authService.currentUser?.id;

    if (userId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Tasks',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _dashedBorderBox(
            onTap: () => context.go('/login'),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.login, color: AppTheme.accentPrimary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Login to see your tasks',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Tasks',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          DateFormat('MMMM dd, yyyy').format(_selectedDate),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('tasks')
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _dashedBorderBox(
                onTap: () => context.go('/planner'),
                child: Text(
                  'Error loading tasks. Tap to go to planner.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return _dashedBorderBox(
                onTap: () => context.go('/planner'),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: AppTheme.accentPrimary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No tasks scheduled for today.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap here to get started!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Filter tasks for selected date
            final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
            final allTasks = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
              if (dueDate == null) return false;
              return dueDate.year == selectedDay.year &&
                     dueDate.month == selectedDay.month &&
                     dueDate.day == selectedDay.day;
            }).toList();
            final tasks = allTasks.take(5).toList();

            if (tasks.isEmpty) {
              return _dashedBorderBox(
                onTap: () => context.go('/planner'),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: AppTheme.accentPrimary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No tasks scheduled for today.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap here to get started!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: tasks.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Untitled';
                final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
                final priority = data['priority'] ?? 'medium';
                final status = data['status'] ?? 'pending';
                final taskId = doc.id;

                Color priorityColor = AppTheme.accentPrimary;
                if (priority == 'high') priorityColor = AppTheme.accentAlert;
                if (priority == 'low') priorityColor = AppTheme.accentSuccess;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                    decoration: status == 'completed' ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                if (dueDate != null)
                                  Text(
                                    DateFormat('h:mm a').format(dueDate),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            status == 'completed' ? Icons.check_circle : Icons.circle_outlined,
                            color: status == 'completed' ? AppTheme.accentSuccess : AppTheme.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status != 'completed')
                            TextButton.icon(
                              onPressed: () async {
                                debugPrint('🔵 Done button clicked for task: $taskId');
                                
                                // Show confirmation dialog
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppTheme.surfaceAlt,
                                    title: Text(
                                      'Mark as Completed?',
                                      style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                                    ),
                                    content: Text(
                                      'Are you sure you want to mark this task as completed?',
                                      style: GoogleFonts.inter(color: AppTheme.textSecondary),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentSuccess),
                                        child: Text('Confirm', style: GoogleFonts.inter(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm != true) return;
                                
                                try {
                                  // Only update user subcollection (old tasks only exist there)
                                  debugPrint('📝 Updating user subcollection: users/$userId/tasks/$taskId');
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .collection('tasks')
                                      .doc(taskId)
                                      .update({'status': 'completed', 'completedAt': FieldValue.serverTimestamp()});
                                  debugPrint('✅ User subcollection updated successfully');
                                      
                                  // Try to update top-level collection too (for new tasks)
                                  try {
                                    debugPrint('📝 Trying to update top-level: tasks/$taskId');
                                    await FirebaseFirestore.instance
                                        .collection('tasks')
                                        .doc(taskId)
                                        .update({'status': 'completed', 'completedAt': FieldValue.serverTimestamp()});
                                    debugPrint('✅ Top-level collection updated successfully');
                                  } catch (e) {
                                    debugPrint('⚠️ Top-level update failed (expected for old tasks): $e');
                                  }
                                } catch (e) {
                                  debugPrint('❌ ERROR updating task: $e');
                                }
                              },
                              icon: const Icon(Icons.check, size: 16),
                              label: Text(
                                'Done',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.accentSuccess,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () => _showEditTaskDialog(context, taskId, title, priority, dueDate),
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(
                              'Edit',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.accentPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppTheme.surfaceAlt,
                                  title: Text(
                                    'Delete Task',
                                    style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete this task?',
                                    style: GoogleFonts.inter(color: AppTheme.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentAlert),
                                      child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                debugPrint('🗑️ Delete button confirmed for task: $taskId');
                                try {
                                  // Only delete from user subcollection (old tasks only exist there)
                                  debugPrint('📝 Deleting from user subcollection: users/$userId/tasks/$taskId');
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .collection('tasks')
                                      .doc(taskId)
                                      .delete();
                                  debugPrint('✅ Deleted from user subcollection successfully');
                                      
                                  // Try to delete from top-level collection too (for new tasks)
                                  try {
                                    debugPrint('📝 Trying to delete from top-level: tasks/$taskId');
                                    await FirebaseFirestore.instance
                                        .collection('tasks')
                                        .doc(taskId)
                                        .delete();
                                    debugPrint('✅ Deleted from top-level collection successfully');
                                  } catch (e) {
                                    debugPrint('⚠️ Top-level delete failed (expected for old tasks): $e');
                                  }
                                } catch (e) {
                                  debugPrint('❌ ERROR deleting task: $e');
                                }
                              }
                            },
                            icon: const Icon(Icons.delete, size: 16),
                            label: Text(
                              'Delete',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.accentAlert,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTeamTasks() {
    final authService = context.watch<AuthService>();
    final teamService = context.watch<TeamService>();
    final userId = authService.currentUser?.id;

    if (userId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Tasks',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _dashedBorderBox(
            onTap: () => context.go('/login'),
            child: Text(
              'Login to see team tasks',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Team Tasks',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/team'),
              icon: const Icon(Icons.group, size: 16, color: AppTheme.accentPrimary),
              label: Text(
                'View Teams',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.accentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Team>>(
          stream: teamService.getUserTeams(userId),
          builder: (context, teamsSnapshot) {
            if (!teamsSnapshot.hasData || teamsSnapshot.data!.isEmpty) {
              return _dashedBorderBox(
                onTap: () => context.go('/team'),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.group_add, color: AppTheme.accentPrimary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No teams yet',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to create or join a team!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final teams = teamsSnapshot.data!;
            final teamIds = teams.map((t) => t.id).toList();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('isTeamTask', isEqualTo: true)
                  .where('teamId', whereIn: teamIds.isEmpty ? [''] : teamIds)
                  .limit(20)
                  .snapshots(),
              builder: (context, tasksSnapshot) {
                if (tasksSnapshot.hasError) {
                  return _dashedBorderBox(
                    onTap: () => context.go('/team'),
                    child: Text(
                      'Error loading team tasks',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                }

                if (!tasksSnapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final tasks = tasksSnapshot.data!.docs;

                if (tasks.isEmpty) {
                  return _dashedBorderBox(
                    onTap: () => context.go('/planner'),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.accentPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.task_alt, color: AppTheme.accentPrimary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No team tasks yet',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to create tasks in planner!',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: tasks.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled';
                    final teamId = data['teamId'] ?? '';
                    final taskId = doc.id;
                    final team = teams.firstWhere(
                      (t) => t.id == teamId,
                      orElse: () => teams.first,
                    );
                    final priority = data['priority'] ?? 'medium';
                    final status = data['status'] ?? 'pending';

                    Color priorityColor = AppTheme.accentPrimary;
                    if (priority == 'high') {
                      priorityColor = AppTheme.accentAlert;
                    } else if (priority == 'low') {
                      priorityColor = AppTheme.accentSuccess;
                    } else {
                      priorityColor = const Color(0xFFFFA726);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: priorityColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                        decoration: status == 'completed' ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    Text(
                                      team.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                status == 'completed' ? Icons.check_circle : Icons.circle_outlined,
                                color: status == 'completed' ? AppTheme.accentSuccess : AppTheme.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (status != 'completed')
                                TextButton.icon(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('tasks')
                                        .doc(taskId)
                                        .update({'status': 'completed'});
                                  },
                                  icon: const Icon(Icons.check, size: 16),
                                  label: Text(
                                    'Complete',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.accentSuccess,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                ),
                              TextButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppTheme.surfaceAlt,
                                      title: Text(
                                        'Delete Task',
                                        style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete this team task?',
                                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentAlert),
                                          child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('tasks')
                                        .doc(taskId)
                                        .delete();
                                  }
                                },
                                icon: const Icon(Icons.delete, size: 16),
                                label: Text(
                                  'Delete',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.accentAlert,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }
  Widget _buildMySubjects() {
    final authService = context.watch<AuthService>();
    final subjectService = context.watch<SubjectService>();
    final userId = authService.currentUser?.id;

    if (userId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Subjects',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _dashedBorderBox(
            onTap: () => context.go('/login'),
            child: Text(
              'Login to see your subjects',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      );
    }

    final subjects = subjectService.subjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Subjects',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...subjects.map((subject) {
                return Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textSecondary.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Subject name
                      Text(
                        subject.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Schedule (days)
                      Text(
                        subject.weekdaysDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Time
                      Text(
                        subject.timeDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Action buttons Row 1 (Edit, Delete, Attach)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _subjectActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            onTap: () => _editSubject(subject),
                          ),
                          _subjectActionButton(
                            icon: Icons.delete_outline,
                            label: 'Delete',
                            color: Colors.red,
                            onTap: () => _deleteSubject(subject.id, subject.name),
                          ),
                          _subjectActionButton(
                            icon: Icons.attach_file_outlined,
                            label: 'Attach',
                            onTap: () => _attachFilesToSubject(subject),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Action buttons Row 2 (Notifications, Suggestions)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _subjectActionButton(
                            icon: Icons.notifications_outlined,
                            label: 'Notify',
                            color: Colors.orange,
                            onTap: () => _showSubjectNotificationSettings(subject),
                          ),
                          _subjectActionButton(
                            icon: Icons.lightbulb_outlined,
                            label: 'Tips',
                            color: Colors.amber,
                            onTap: () => _showSubjectSuggestions(subject),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              // Add Subject button
              SizedBox(
                width: 160,
                child: _dashedBorderBox(
                  onTap: _addNewSubject,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.library_add, color: AppTheme.accentPrimary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '+ Add Subject',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subjectActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? AppTheme.accentPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color ?? AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewSubject() {
    showDialog(
      context: context,
      builder: (context) => const AddSubjectDialog(),
    );
  }

  void _editSubject(subject) {
    showDialog(
      context: context,
      builder: (context) => AddSubjectDialog(subject: subject),
    );
  }

  void _deleteSubject(String subjectId, String subjectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Delete Subject?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure that you are going to delete this subject "$subjectName"?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final subjectService = context.read<SubjectService>();
              
              // Get subject to cancel its notifications
              final subject = subjectService.subjects.firstWhere(
                (s) => s.id == subjectId,
                orElse: () => throw 'Subject not found',
              );
              
              // Cancel notifications for this subject
              final notificationService = NotificationService();
              await notificationService.cancelSubjectNotifications(
                subjectId,
                subject.weekdays,
              );
              
              await subjectService.deleteSubject(subjectId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Subject deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'CONFIRM',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _attachFilesToSubject(subject) {
    showDialog(
      context: context,
      builder: (context) => AddSubjectDialog(subject: subject),
    );
  }

  // Subject Notification Settings Dialog
  void _showSubjectNotificationSettings(subject) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Notifications for ${subject.name}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationOption(
              'Class Reminders',
              'Get notified 30 minutes before class',
              Icons.access_time,
              true,
            ),
            const SizedBox(height: 12),
            _buildNotificationOption(
              'Assignment Due',
              'Reminder for upcoming deadlines',
              Icons.assignment_late,
              true,
            ),
            const SizedBox(height: 12),
            _buildNotificationOption(
              'Study Sessions',
              'Recommended study time alerts',
              Icons.school,
              false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notification settings saved for ${subject.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPrimary),
            child: Text('Save', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption(String title, String subtitle, IconData icon, bool enabled) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: enabled ? AppTheme.accentPrimary : AppTheme.textSecondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) {},
            activeColor: AppTheme.accentPrimary,
          ),
        ],
      ),
    );
  }

  // Subject Study Suggestions Dialog
  void _showSubjectSuggestions(subject) {
    final analyticsService = context.read<AnalyticsService>();
    final recommendations = analyticsService.recommendations;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Study Tips for ${subject.name}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personalized suggestions based on subject type
              _buildSuggestionCard(
                '📚 Best Study Time',
                subject.fieldOfStudy == 'Major Subject'
                    ? 'Major subjects need 2-3 hour deep focus sessions. Try morning hours for better retention.'
                    : 'Minor subjects work well with shorter 45-60 minute sessions.',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildSuggestionCard(
                '🎯 Recommended Technique',
                subject.fieldOfStudy == 'Major Subject'
                    ? 'Use Pomodoro (25 min focus + 5 min break) for intense study sessions.'
                    : 'Active Recall works great for minor subjects - test yourself frequently!',
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildSuggestionCard(
                '📅 Schedule Suggestion',
                'Based on your class days (${subject.weekdaysDisplay}), try studying this subject on alternate days for spaced repetition.',
                Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildSuggestionCard(
                '⏰ Optimal Time Slot',
                recommendations.isNotEmpty
                    ? 'Your peak productivity: ${recommendations.first.timeSlot}'
                    : 'Complete more study sessions to get personalized time recommendations.',
                Colors.orange,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/analytics');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPrimary),
            child: Text('View Analytics', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedBorderBox({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppTheme.textSecondary.withOpacity(0.3),
          strokeWidth: 1.5,
          borderRadius: 16,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }

  // Analytics Widget for Modal
  Widget _buildUserAnalytics() {
    final authService = context.watch<AuthService>();
    final userId = authService.currentUser?.id;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!.docs;
        final completedTasks = tasks.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'completed';
        }).length;

        final pendingTasks = tasks.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'pending';
        }).length;

        final totalTasks = tasks.length;
        final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100).toInt() : 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Activity',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Icon(Icons.bar_chart, color: AppTheme.accentPrimary, size: 24),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completion Rate',
                        style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      Text(
                        '$completionRate%',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: completionRate / 100,
                      minHeight: 10,
                      backgroundColor: AppTheme.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Completed',
                      value: completedTasks.toString(),
                      color: AppTheme.accentSuccess,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.pending_outlined,
                      label: 'Pending',
                      value: pendingTasks.toString(),
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.assignment_outlined,
                      label: 'Total',
                      value: totalTasks.toString(),
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborationWidget() {
    final authService = context.watch<AuthService>();
    final teamService = context.watch<TeamService>();
    final userId = authService.currentUser?.id;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Team>>(
      stream: teamService.getUserTeams(userId),
      builder: (context, teamsSnapshot) {
        final teams = teamsSnapshot.data ?? [];
        final activeTeamCount = teams.length;
        final totalMembers = teams.fold<int>(0, (sum, team) => sum + team.members.length);
        
        // Get team tasks count
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .where('isTeamTask', isEqualTo: true)
              .where('teamId', whereIn: teams.isEmpty ? [''] : teams.map((t) => t.id).toList())
              .snapshots(),
          builder: (context, tasksSnapshot) {
            final taskCount = tasksSnapshot.data?.docs.length ?? 0;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.surfaceHigh, AppTheme.accentPrimary.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentPrimary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.group, color: AppTheme.accentPrimary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Team Collaboration',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: activeTeamCount > 0 ? AppTheme.accentSuccess.withOpacity(0.2) : AppTheme.textSecondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$activeTeamCount Active',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: activeTeamCount > 0 ? AppTheme.accentSuccess : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Team Members Display
                  if (teams.isNotEmpty) ...[
                    Row(
                      children: [
                        ...teams.take(5).expand((team) {
                          return team.members.take(1).map((member) {
                            return _buildTeamMemberAvatar(
                              _getInitials(member.name),
                              _getColorForInitials(member.name),
                            );
                          });
                        }).take(5),
                        if (totalMembers > 5)
                          Text(
                            '+${totalMembers - 5} more',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'No team members yet',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildCollabStat(
                          icon: Icons.task_alt,
                          value: taskCount.toString(),
                          label: 'Team Tasks',
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCollabStat(
                          icon: Icons.people,
                          value: totalMembers.toString(),
                          label: 'Members',
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/team'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.people, size: 20),
                    label: Text(
                      'View Team Dashboard',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getColorForInitials(String name) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.pink,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildTeamMemberAvatar(String initials, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.bgBase, width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCollabStat({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsWidget() {
    final gamificationService = context.watch<GamificationService>();
    final userGamification = gamificationService.userGamification;
    final achievements = gamificationService.achievements;

    // Calculate level progress
    final currentLevel = userGamification?.level ?? 1;
    final currentXP = userGamification?.xp ?? 0;
    final xpForNextLevel = 100 * currentLevel;
    final xpProgress = currentXP / xpForNextLevel;
    final xpNeeded = xpForNextLevel - currentXP;

    // Get recent unlocked achievements (last 4)
    final unlockedAchievements = achievements
        .where((a) => a.unlocked && a.unlockedAt != null)
        .toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
    final recentAchievements = unlockedAchievements.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceHigh,
            AppTheme.accentSuccess.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentSuccess.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSuccess.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.emoji_events, color: AppTheme.accentSuccess, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rewards & Achievements',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Points Display - Real Data
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Points',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${userGamification?.studyPoints ?? 0}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentSuccess,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level ${userGamification?.level ?? 1} • ${userGamification?.title ?? "New Learner"}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentSuccess.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.stars, color: AppTheme.accentSuccess, size: 48),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Recent Achievements - Real Data
          Text(
            'Recent Achievements',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          recentAchievements.isEmpty
              ? Center(
                  child: Text(
                    'Complete tasks to unlock achievements!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: recentAchievements.map((achievement) {
                    return _buildBadge(
                      _getAchievementIcon(achievement.id),
                      achievement.name.length > 12 
                          ? '${achievement.name.substring(0, 10)}..' 
                          : achievement.name,
                      _getAchievementColor(achievement.id),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 20),
          // Next Level Progress - Real Data
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Level',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '$xpNeeded XP to Level ${currentLevel + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentSuccess,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: xpProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentSuccess),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/achievements'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentSuccess,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.emoji_events, size: 20),
            label: Text(
              'View All Achievements',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon(String achievementId) {
    // Map achievement IDs to appropriate icons
    if (achievementId.contains('first_task')) return Icons.workspace_premium;
    if (achievementId.contains('streak')) return Icons.local_fire_department;
    if (achievementId.contains('session')) return Icons.timer;
    if (achievementId.contains('team')) return Icons.military_tech;
    if (achievementId.contains('task')) return Icons.check_circle;
    if (achievementId.contains('points')) return Icons.trending_up;
    return Icons.emoji_events;
  }

  Color _getAchievementColor(String achievementId) {
    // Color based on achievement ID pattern
    if (achievementId.contains('task')) return Colors.purple;
    if (achievementId.contains('session') || achievementId.contains('study')) return Colors.blue;
    if (achievementId.contains('streak') || achievementId.contains('daily')) return Colors.orange;
    if (achievementId.contains('team') || achievementId.contains('collab')) return Colors.green;
    if (achievementId.contains('master') || achievementId.contains('expert')) return Colors.amber;
    if (achievementId.contains('explore') || achievementId.contains('new')) return Colors.pink;
    return Colors.blue;
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScheduleWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Schedule',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'View and manage your upcoming tasks and events.',
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: AppTheme.surfaceAlt,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_filled,
              label: 'Home',
              isActive: true,
              onTap: () {},
            ),
            _buildNavItem(
              icon: Icons.search,
              label: 'Planner',
              onTap: () => context.go('/planner'),
            ),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(
              icon: Icons.people_outline,
              label: 'Team',
              onTap: () => context.go('/team'),
            ),
            _buildNavItem(
              icon: Icons.emoji_events_outlined,
              label: 'Rewards',
              onTap: () => context.go('/achievements'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    final color = isActive ? AppTheme.accentPrimary : AppTheme.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  void _showMenuDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.textPrimary),
              title: Text('Settings', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: AppTheme.textPrimary),
              title: Text('Task Board', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                context.go('/planner');
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: AppTheme.textPrimary),
              title: Text('Achievements', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                context.go('/achievements');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: AppTheme.textPrimary),
              title: Text('Analytics', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                context.go('/analytics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.accentAlert),
              title: Text('Logout', style: GoogleFonts.inter(color: AppTheme.accentAlert)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthService>().logout();
                if (mounted) context.go('/welcome');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, String taskId, String currentTitle, String currentPriority, DateTime? currentDueDate) {
    final titleController = TextEditingController(text: currentTitle);
    String selectedPriority = currentPriority;
    DateTime selectedDate = currentDueDate ?? DateTime.now();
    TimeOfDay selectedTime = currentDueDate != null 
        ? TimeOfDay.fromDateTime(currentDueDate) 
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceAlt,
          title: Text(
            'Edit Task',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.accentPrimary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Priority',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityChip('low', 'Low', AppTheme.accentSuccess, selectedPriority, (value) {
                      setState(() => selectedPriority = value);
                    }),
                    const SizedBox(width: 8),
                    _buildPriorityChip('medium', 'Medium', const Color(0xFFFFA726), selectedPriority, (value) {
                      setState(() => selectedPriority = value);
                    }),
                    const SizedBox(width: 8),
                    _buildPriorityChip('high', 'High', AppTheme.accentAlert, selectedPriority, (value) {
                      setState(() => selectedPriority = value);
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Due Date & Time',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: AppTheme.accentPrimary,
                                    onPrimary: Colors.white,
                                    surface: AppTheme.surfaceAlt,
                                    onSurface: Colors.white,
                                  ),
                                  textTheme: const TextTheme(
                                    bodyLarge: TextStyle(color: Colors.white),
                                    bodyMedium: TextStyle(color: Colors.white),
                                    titleMedium: TextStyle(color: Colors.white),
                                    headlineMedium: TextStyle(color: Colors.white),
                                    labelLarge: TextStyle(color: Colors.white),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          DateFormat('MMM d, y').format(selectedDate),
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(
                          selectedTime.format(context),
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Show confirmation dialog before saving
                final confirmSave = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: AppTheme.surfaceAlt,
                    title: Text(
                      'Save Changes?',
                      style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                    ),
                    content: Text(
                      'Are you sure you want to save these changes?',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPrimary),
                        child: Text('Save', style: GoogleFonts.inter(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                
                if (confirmSave != true) return;
                
                final newDueDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                
                final updateData = {
                  'title': titleController.text,
                  'priority': selectedPriority,
                  'dueDate': Timestamp.fromDate(newDueDate),
                  'scheduledDate': Timestamp.fromDate(newDueDate),
                };
                
                final currentUserId = context.read<AuthService>().currentUser?.id;
                if (currentUserId == null) return;
                
                // Only update user subcollection (old tasks only exist there)
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('tasks')
                    .doc(taskId)
                    .update(updateData);
                    
                // Try to update top-level collection too (for new tasks)
                try {
                  await FirebaseFirestore.instance
                      .collection('tasks')
                      .doc(taskId)
                      .update(updateData);
                } catch (e) {
                  // Ignore error if task doesn't exist in top-level collection
                }
                
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, Color color, String selectedValue, Function(String) onSelected) {
    final isSelected = value == selectedValue;
    return Expanded(
      child: InkWell(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppTheme.textSecondary.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected ? color : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter draws rounded dashed rectangle similar to mockup borders.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    double dashWidth = 8,
    double dashGap = 5,
  })  : dashWidth = dashWidth,
        dashGap = dashGap;

  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromLTRBR(0, 0, size.width, size.height, Radius.circular(borderRadius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = (distance + dashWidth).clamp(0.0, metric.length).toDouble();
        dashedPath.addPath(metric.extractPath(distance, nextDistance), Offset.zero);
        distance = nextDistance + dashGap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


