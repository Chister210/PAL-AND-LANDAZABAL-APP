import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../services/team_service.dart';
import '../../services/notification_service.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentColumn = 0;
  bool _showHistory = false;
  Timer? _taskCheckTimer;
  String _searchQuery = '';
  
  // Filter options
  String? _selectedSubjectFilter;
  String? _selectedAlphabeticalFilter; // 'A to Z' or 'Z to A'
  String? _selectedDeadlineFilter; // 'Soonest' or 'Latest'
  String? _selectedPriorityFilter; // 'Low', 'Medium', 'High'

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkOverdueTasks();
    // Check every 5 minutes for overdue tasks
    _taskCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkOverdueTasks();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _taskCheckTimer?.cancel();
    super.dispose();
  }

  /// Check for overdue tasks and update their status automatically
  Future<void> _checkOverdueTasks() async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      
      // Get all pending and in_progress tasks for current user
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Filter manually since we need to check multiple status formats
      final pendingOrInProgress = tasksSnapshot.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'pending' || status == 'inProgress' || status == 'in_progress' || status == 'in_Progress';
      }).toList();

      final batch = FirebaseFirestore.instance.batch();
      int updatedCount = 0;

      for (final doc in pendingOrInProgress) {
        final data = doc.data();
        final dueDate = data['dueDate'] as Timestamp?;
        
        if (dueDate != null) {
          final deadline = dueDate.toDate();
          
          // If task is overdue and not in progress, move to in_progress
          if (now.isAfter(deadline) && data['status'] == 'pending') {
            batch.update(doc.reference, {
              'status': 'inProgress',
              'autoMoved': true,
              'autoMovedAt': FieldValue.serverTimestamp(),
            });
            updatedCount++;
          }
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
        debugPrint('Auto-moved $updatedCount overdue tasks to In Progress');
      }
    } catch (e) {
      debugPrint('Error checking overdue tasks: $e');
    }
  }

  void _onColumnChanged(int index) {
    setState(() => _currentColumn = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        backgroundColor: AppTheme.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          _showHistory ? 'Task History' : 'Task Board',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (_showHistory)
            IconButton(
              icon: Image.asset(
                'assets/icons/search.png',
                width: 24,
                height: 24,
                color: AppTheme.textPrimary,
              ),
              onPressed: () => _showSearchDialog(),
            ),
          IconButton(
            icon: Image.asset(
              'assets/icons/sort.png',
              width: 24,
              height: 24,
              color: AppTheme.textPrimary,
            ),
            onPressed: () => _showFilterBottomSheet(),
          ),
          IconButton(
            icon: Image.asset(
              _showHistory ? 'assets/icons/dashboard.png' : 'assets/icons/history.png',
              width: 24,
              height: 24,
              color: AppTheme.textPrimary,
            ),
            onPressed: () => setState(() => _showHistory = !_showHistory),
          ),
        ],
      ),
      body: _showHistory ? _buildHistoryView() : _buildKanbanView(),
      floatingActionButton: _showHistory ? null : FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: AppTheme.accentPrimary.withOpacity(0.9),
        elevation: 8,
        icon: const Icon(Icons.add, color: Colors.white, size: 28),
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildKanbanView() {
    final userId = context.watch<AuthService>().currentUser?.id;
    
    if (userId == null) {
      return Center(
        child: Text(
          'Please log in to view tasks',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        // Column selector tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildColumnTab('To Do', 0),
              _buildColumnTab('In Progress', 1),
              _buildColumnTab('Done', 2),
            ],
          ),
        ),
        
        // PageView for columns
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentColumn = index),
            children: [
              _buildFirestoreTaskColumn(userId, 'pending', 'To Do', AppTheme.accentPrimary),
              _buildFirestoreTaskColumn(userId, 'in_progress', 'In Progress', const Color(0xFFFFA726)),
              _buildFirestoreTaskColumn(userId, 'completed', 'Done', AppTheme.accentSuccess),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumnTab(String label, int index) {
    final isSelected = _currentColumn == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onColumnChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFirestoreTaskColumn(String userId, String status, String columnName, Color columnColor) {
    // For Progress column, show both pending and in_progress tasks
    // For other columns, use specific status
    Query<Map<String, dynamic>> query;
    if (status == 'in_progress') {
      // Progress tab shows ALL non-completed tasks (pending + in_progress)
      query = FirebaseFirestore.instance
          .collection('tasks')
          .where('status', whereIn: ['pending', 'in_progress', 'inProgress']);
    } else {
      query = FirebaseFirestore.instance
          .collection('tasks')
          .where('status', isEqualTo: status);
    }

    // Note: Removed orderBy to avoid composite index requirement
    // Sorting will be done client-side

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.accentAlert),
                const SizedBox(height: 16),
                Text(
                  'Error loading tasks',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please create the required Firestore index',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get user's team IDs to include team tasks
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('teams')
              .where('memberIds', arrayContains: userId)
              .snapshots(),
          builder: (context, teamSnapshot) {
            List<String> userTeamIds = [];
            if (teamSnapshot.hasData) {
              userTeamIds = teamSnapshot.data!.docs.map((doc) => doc.id).toList();
            }

            // Filter for user's personal tasks OR team tasks where user is member
            var tasks = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) return false;
              
              final isTeamTask = data['isTeamTask'] == true;
              if (isTeamTask) {
                final taskTeamId = data['teamId'] as String?;
                return taskTeamId != null && userTeamIds.contains(taskTeamId);
              } else {
                return data['userId'] == userId;
              }
            }).toList();

        // Apply client-side filters
        if (_selectedSubjectFilter != null) {
          tasks = tasks.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data?['subject']?.toString().toLowerCase() == _selectedSubjectFilter!.toLowerCase();
          }).toList();
        }

        if (_selectedPriorityFilter != null) {
          tasks = tasks.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data?['priority']?.toString().toLowerCase() == _selectedPriorityFilter!.toLowerCase();
          }).toList();
        }

        // Apply client-side sorting
        if (_selectedAlphabeticalFilter != null) {
          tasks.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTitle = aData?['title'] ?? '';
            final bTitle = bData?['title'] ?? '';
            return _selectedAlphabeticalFilter == 'A to Z' 
                ? aTitle.compareTo(bTitle)
                : bTitle.compareTo(aTitle);
          });
        }

        if (_selectedDeadlineFilter != null) {
          tasks.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aDate = (aData?['dueDate'] as Timestamp?)?.toDate();
            final bDate = (bData?['dueDate'] as Timestamp?)?.toDate();
            
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            
            return _selectedDeadlineFilter == 'Soonest'
                ? aDate.compareTo(bDate)
                : bDate.compareTo(aDate);
          });
        } else {
          // Default sort by due date (soonest first)
          tasks.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aDate = (aData?['dueDate'] as Timestamp?)?.toDate();
            final bDate = (bData?['dueDate'] as Timestamp?)?.toDate();
            
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            
            return aDate.compareTo(bDate);
          });
        }

        if (tasks.isEmpty) {
          return _buildEmptyState(columnName);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section headers
            _buildSectionHeader('My Tasks', tasks.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data?['isTeamTask'] != true;
            }).length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tasks.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  return data?['isTeamTask'] != true;
                }).length + 1,
                itemBuilder: (context, index) {
                  final myTasks = tasks.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    return data?['isTeamTask'] != true;
                  }).toList();
                  
                  if (index < myTasks.length) {
                    final taskDoc = myTasks[index];
                    final taskData = taskDoc.data() as Map<String, dynamic>?;
                    return _buildFirestoreTaskCard(
                      taskDoc.id,
                      taskData ?? {},
                      columnColor,
                      status,
                    );
                  } else {
                    return _buildAddTaskButton();
                  }
                },
              ),
            ),
            
            // Team Tasks section
            _buildSectionHeader('Team Tasks', tasks.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data?['isTeamTask'] == true;
            }).length),
            Expanded(
              child: tasks.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return data?['isTeamTask'] == true;
              }).isEmpty
                  ? _buildEmptyTeamState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.where((doc) {
                        final data = doc.data() as Map<String, dynamic>?;
                        return data?['isTeamTask'] == true;
                      }).length,
                      itemBuilder: (context, index) {
                        final teamTasks = tasks.where((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          return data?['isTeamTask'] == true;
                        }).toList();
                        final taskDoc = teamTasks[index];
                        final taskData = taskDoc.data() as Map<String, dynamic>?;
                        return _buildFirestoreTaskCard(
                          taskDoc.id,
                          taskData ?? {},
                          columnColor,
                          status,
                        );
                      },
                    ),
            ),
          ],
        );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String columnName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.surfaceHigh,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(
              Icons.add,
              size: 40,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks scheduled for today.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap here to get started!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTeamState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentPrimary,
                  width: 3,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(
                Icons.add,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks scheduled for today.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap here to get started!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTaskButton() {
    return GestureDetector(
      onTap: () => _showAddTaskDialog(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.surfaceHigh,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/add.png',
              width: 20,
              height: 20,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Add new task?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirestoreTaskCard(String taskId, Map<String, dynamic> taskData, Color columnColor, String currentStatus) {
    final title = taskData['title'] ?? 'Untitled';
    final subject = taskData['subject'] ?? 'General';
    final priority = taskData['priority'] ?? 'medium';
    final dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();
    final startTime = taskData['startTime'] as String?;
    final endTime = taskData['endTime'] as String?;
    
    Color subjectColor = AppTheme.accentPrimary;
    if (subject.toLowerCase().contains('math')) {
      subjectColor = AppTheme.subjectMath;
    } else if (subject.toLowerCase().contains('english')) {
      subjectColor = AppTheme.subjectEnglish;
    } else if (subject.toLowerCase().contains('science')) {
      subjectColor = AppTheme.subjectScience;
    } else if (subject.toLowerCase().contains('history')) {
      subjectColor = AppTheme.subjectHistory;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: columnColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and priority
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildPriorityBadge(priority),
              ],
            ),
            const SizedBox(height: 8),
            
            // Subject and time info
            Text(
              startTime != null && endTime != null
                  ? '$subject - ${dueDate != null ? DateFormat('EEEE').format(dueDate) : 'No date'}, Time Start - Time End'
                  : subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            
            // Actions - only show for non-completed tasks
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Only show Edit, Delete, and Complete buttons if task is NOT completed
                if (currentStatus != 'completed') ...[
                  // Edit button
                  GestureDetector(
                    onTap: () => _showEditTaskDialog(taskId, taskData),
                    child: Icon(
                      Icons.edit,
                      size: 20,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Delete button
                  GestureDetector(
                    onTap: () => _deleteTask(taskId, title),
                    child: Image.asset(
                      'assets/icons/trash.png',
                      width: 20,
                      height: 20,
                      color: AppTheme.accentAlert,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Complete/Move button
                  GestureDetector(
                    onTap: () {
                      if (currentStatus == 'pending') {
                        _moveTask(taskId, 'in_progress');
                      } else if (currentStatus == 'in_progress') {
                        _showCompleteDialog(taskId, title);
                      }
                    },
                    child: Icon(
                      currentStatus == 'in_progress' 
                          ? Icons.check_circle
                          : Icons.chevron_right,
                      size: 20,
                      color: AppTheme.accentSuccess,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;
    
    switch (priority.toLowerCase()) {
      case 'high':
        color = AppTheme.accentAlert;
        label = 'High';
        break;
      case 'low':
        color = AppTheme.accentSuccess;
        label = 'Low';
        break;
      default:
        color = const Color(0xFFFFA726);
        label = 'Medium';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // Smart Date Conflict Dialog with Suggestions
  Future<Map<String, dynamic>?> _showSmartDateConflictDialog(
    BuildContext context,
    DateTime selectedDate,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> existingTasks,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allTasks,
    TimeOfDay? currentTime,
  ) async {
    // Find available dates (next 14 days that have no tasks)
    final availableDates = _findAvailableDates(allTasks, selectedDate, 14);
    
    // Find available time slots for the selected date
    final availableTimeSlots = _findAvailableTimeSlots(existingTasks, currentTime);
    
    // Get existing task details for display
    final existingTaskNames = existingTasks.map((doc) {
      final data = doc.data();
      return data['title'] as String? ?? 'Unnamed Task';
    }).toList();

    DateTime? suggestedDate;
    TimeOfDay? suggestedTime;
    
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Date Already Taken!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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
                // Show existing tasks on this date
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${existingTasks.length} task(s) on ${DateFormat('EEEE, MMM dd').format(selectedDate)}:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[300],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...existingTaskNames.take(3).map((name) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.red[300]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (existingTaskNames.length > 3)
                        Text(
                          '...and ${existingTaskNames.length - 3} more',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Suggested Alternative Dates Section
                Text(
                  '📅 Suggested Available Dates:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Date suggestion chips with day groups
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Show MTW (Mon-Tue-Wed) and ThF (Thu-Fri) groupings
                    ...availableDates.take(6).map((date) {
                      final isSelected = suggestedDate != null && 
                          suggestedDate!.year == date.year &&
                          suggestedDate!.month == date.month &&
                          suggestedDate!.day == date.day;
                      final dayName = DateFormat('E').format(date);
                      final isMTW = ['Mon', 'Tue', 'Wed'].contains(dayName);
                      
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => suggestedDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.accentPrimary 
                                : (isMTW ? Colors.blue.withOpacity(0.15) : Colors.purple.withOpacity(0.15)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? AppTheme.accentPrimary 
                                  : (isMTW ? Colors.blue.withOpacity(0.5) : Colors.purple.withOpacity(0.5)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dayName,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : (isMTW ? Colors.blue[300] : Colors.purple[300]),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d').format(date),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Suggested Time Slots Section
                Text(
                  '⏰ Suggested Time Slots:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Time slot chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableTimeSlots.take(6).map((time) {
                    final isSelected = suggestedTime != null && 
                        suggestedTime!.hour == time.hour && 
                        suggestedTime!.minute == time.minute;
                    final isMorning = time.hour < 12;
                    final isAfternoon = time.hour >= 12 && time.hour < 17;
                    
                    Color chipColor;
                    if (isMorning) {
                      chipColor = Colors.amber;
                    } else if (isAfternoon) {
                      chipColor = Colors.orange;
                    } else {
                      chipColor = Colors.indigo;
                    }
                    
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => suggestedTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accentSuccess : chipColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentSuccess : chipColor.withOpacity(0.5),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMorning ? Icons.wb_sunny : (isAfternoon ? Icons.wb_twilight : Icons.nights_stay),
                              size: 14,
                              color: isSelected ? Colors.white : chipColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              time.format(context),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Quick day group buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildDayGroupButton(
                        'MTW',
                        'Mon-Wed',
                        Colors.blue,
                        () {
                          // Find next MTW date
                          final mtwDate = _findNextDayInGroup(allTasks, ['monday', 'tuesday', 'wednesday']);
                          if (mtwDate != null) {
                            setDialogState(() => suggestedDate = mtwDate);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDayGroupButton(
                        'ThF',
                        'Thu-Fri',
                        Colors.purple,
                        () {
                          // Find next ThF date
                          final thfDate = _findNextDayInGroup(allTasks, ['thursday', 'friday']);
                          if (thfDate != null) {
                            setDialogState(() => suggestedDate = thfDate);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDayGroupButton(
                        'Weekend',
                        'Sat-Sun',
                        Colors.green,
                        () {
                          // Find next weekend date
                          final weekendDate = _findNextDayInGroup(allTasks, ['saturday', 'sunday']);
                          if (weekendDate != null) {
                            setDialogState(() => suggestedDate = weekendDate);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                
                // Show selected suggestion
                if (suggestedDate != null || suggestedTime != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSuccess.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentSuccess.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.accentSuccess, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selected: ${suggestedDate != null ? DateFormat('EEE, MMM d').format(suggestedDate!) : DateFormat('EEE, MMM d').format(selectedDate)}${suggestedTime != null ? ' at ${suggestedTime!.format(context)}' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentSuccess,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                // Continue with original date
                Navigator.pop(dialogContext, {'date': selectedDate, 'time': currentTime});
              },
              child: Text('Keep Original', style: GoogleFonts.inter(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: (suggestedDate != null || suggestedTime != null) ? () {
                Navigator.pop(dialogContext, {
                  'date': suggestedDate ?? selectedDate,
                  'time': suggestedTime ?? currentTime,
                });
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentSuccess,
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              ),
              child: Text(
                'Use Suggestion',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to find available dates
  List<DateTime> _findAvailableDates(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allTasks,
    DateTime startDate,
    int daysToCheck,
  ) {
    final availableDates = <DateTime>[];
    final now = DateTime.now();
    
    for (int i = 1; i <= daysToCheck; i++) {
      final checkDate = now.add(Duration(days: i));
      final checkDay = DateTime(checkDate.year, checkDate.month, checkDate.day);
      
      final hasTask = allTasks.any((doc) {
        final data = doc.data();
        final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
        if (dueDate == null) return false;
        return dueDate.year == checkDay.year &&
               dueDate.month == checkDay.month &&
               dueDate.day == checkDay.day;
      });
      
      if (!hasTask) {
        availableDates.add(checkDate);
      }
    }
    
    return availableDates;
  }

  // Helper method to find available time slots
  List<TimeOfDay> _findAvailableTimeSlots(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> existingTasks,
    TimeOfDay? currentTime,
  ) {
    // Define common study time slots
    final allTimeSlots = [
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 10, minute: 0),
      const TimeOfDay(hour: 11, minute: 0),
      const TimeOfDay(hour: 13, minute: 0),
      const TimeOfDay(hour: 14, minute: 0),
      const TimeOfDay(hour: 15, minute: 0),
      const TimeOfDay(hour: 16, minute: 0),
      const TimeOfDay(hour: 17, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
      const TimeOfDay(hour: 19, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
    ];
    
    // Get times already taken
    final takenTimes = existingTasks.map((doc) {
      final data = doc.data();
      final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
      if (dueDate != null) {
        return TimeOfDay.fromDateTime(dueDate);
      }
      return null;
    }).where((t) => t != null).cast<TimeOfDay>().toList();
    
    // Filter out taken times and current time
    return allTimeSlots.where((slot) {
      final isTaken = takenTimes.any((taken) => 
          taken.hour == slot.hour && taken.minute == slot.minute);
      final isCurrent = currentTime != null && 
          currentTime.hour == slot.hour && currentTime.minute == slot.minute;
      return !isTaken && !isCurrent;
    }).toList();
  }

  // Helper method to find next available day in a group
  DateTime? _findNextDayInGroup(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allTasks,
    List<String> dayNames,
  ) {
    final now = DateTime.now();
    
    for (int i = 1; i <= 14; i++) {
      final checkDate = now.add(Duration(days: i));
      final dayName = DateFormat('EEEE').format(checkDate).toLowerCase();
      
      if (dayNames.contains(dayName)) {
        final checkDay = DateTime(checkDate.year, checkDate.month, checkDate.day);
        final hasTask = allTasks.any((doc) {
          final data = doc.data();
          final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
          if (dueDate == null) return false;
          return dueDate.year == checkDay.year &&
                 dueDate.month == checkDay.month &&
                 dueDate.day == checkDay.day;
        });
        
        if (!hasTask) {
          return checkDate;
        }
      }
    }
    return null;
  }

  // Build day group button widget
  Widget _buildDayGroupButton(String label, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final customSubjectController = TextEditingController();
    final notesController = TextEditingController();
    String selectedPriority = 'Medium';
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool showCustomSubject = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceAlt,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Create Task',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Task title
                TextField(
                  controller: titleController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter task title...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Subject dropdown with add new option
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: null,  // Always show as unselected to avoid duplicate value error
                      hint: Text(
                        subjectController.text.isEmpty ? 'Select Subject' : subjectController.text,
                        style: GoogleFonts.inter(
                          color: subjectController.text.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary,
                        ),
                      ),
                      dropdownColor: AppTheme.surfaceHigh,
                      items: [
                        ...['Math', 'English', 'Science', 'History', 'General'].map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(
                              subject,
                              style: GoogleFonts.inter(color: AppTheme.textPrimary),
                            ),
                          );
                        }),
                        DropdownMenuItem(
                          value: '__add_new__',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, color: AppTheme.accentPrimary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Add New Subject',
                                style: GoogleFonts.inter(
                                  color: AppTheme.accentPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == '__add_new__') {
                          _showAddSubjectDialog(subjectController);
                        } else {
                          setState(() {
                            subjectController.text = value ?? '';
                            showCustomSubject = false;
                            customSubjectController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ),
                
                // Custom subject input (shown when "Other" is selected)
                if (showCustomSubject) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: customSubjectController,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter custom subject name...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surfaceHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.edit, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                
                // Date and Time
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
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
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null && mounted) {
                            // Allow multiple tasks with the same date/time - no conflict blocking
                            // Users can set simultaneous deadlines for different subjects
                            setState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: selectedDate != null 
                              ? Border.all(color: AppTheme.accentPrimary, width: 2)
                              : null,
                          ),
                          child: Row(
                            children: [
                              Text(
                                selectedDate != null 
                                  ? DateFormat('MMM dd').format(selectedDate!)
                                  : 'Date',
                                style: GoogleFonts.inter(
                                  color: selectedDate != null 
                                    ? AppTheme.textPrimary 
                                    : AppTheme.textSecondary,
                                  fontWeight: selectedDate != null 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: selectedDate != null 
                                  ? AppTheme.accentPrimary 
                                  : AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: selectedTime != null 
                              ? Border.all(color: AppTheme.accentPrimary, width: 2)
                              : null,
                          ),
                          child: Row(
                            children: [
                              Text(
                                selectedTime != null 
                                  ? selectedTime!.format(context)
                                  : 'Time',
                                style: GoogleFonts.inter(
                                  color: selectedTime != null 
                                    ? AppTheme.textPrimary 
                                    : AppTheme.textSecondary,
                                  fontWeight: selectedTime != null 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: selectedTime != null 
                                  ? AppTheme.accentPrimary 
                                  : AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Priority
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priority:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityButton('Low', selectedPriority, AppTheme.accentSuccess, () {
                          setState(() => selectedPriority = 'Low');
                        }),
                        const SizedBox(width: 8),
                        _buildPriorityButton('Medium', selectedPriority, const Color(0xFFFFA726), () {
                          setState(() => selectedPriority = 'Medium');
                        }),
                        const SizedBox(width: 8),
                        _buildPriorityButton('High', selectedPriority, AppTheme.accentAlert, () {
                          setState(() => selectedPriority = 'High');
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Notes
                TextField(
                  controller: notesController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter additional notes...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a task title')),
                  );
                  return;
                }
                
                if (subjectController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a subject')),
                  );
                  return;
                }
                
                if (showCustomSubject && customSubjectController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a custom subject name')),
                  );
                  return;
                }

                final userId = context.read<AuthService>().currentUser?.id;
                if (userId == null) return;
                
                // Use custom subject if "Other" was selected
                final finalSubject = showCustomSubject 
                    ? customSubjectController.text.trim()
                    : subjectController.text.trim();

                final taskDeadline = selectedDate ?? DateTime.now().add(const Duration(days: 1));

                try {
                  debugPrint('\ud83c\udfaf TASK BOARD: Creating new task');
                  
                  // Create task data
                  final taskData = {
                    'userId': userId,
                    'title': titleController.text.trim(),
                    'subject': finalSubject,
                    'status': 'pending',  // Use 'pending' for To-Do tab
                    'priority': selectedPriority.toLowerCase(),
                    'dueDate': Timestamp.fromDate(taskDeadline),
                    'scheduledDate': Timestamp.fromDate(taskDeadline),
                    'notes': notesController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                    'isTeamTask': false,
                  };
                  
                  debugPrint('\ud83d\udcdd Task data prepared: ${taskData['title']}, status=${taskData['status']}');
                  
                  // Generate task ID
                  final taskId = DateTime.now().millisecondsSinceEpoch.toString();
                  debugPrint('\ud83c\udff7\ufe0f Generated task ID: $taskId');
                  
                  // Save to BOTH collections
                  debugPrint('\ud83d\udcbe Saving to user subcollection: users/$userId/tasks/$taskId');
                  await FirebaseFirestore.instance.collection('users').doc(userId).collection('tasks').doc(taskId).set(taskData);
                  debugPrint('\u2705 Saved to user subcollection');
                  
                  debugPrint('\ud83d\udcbe Saving to top-level collection: tasks/$taskId');
                  await FirebaseFirestore.instance.collection('tasks').doc(taskId).set(taskData);
                  debugPrint('\u2705 Saved to top-level collection');
                  debugPrint('\u2705 TASK CREATED SUCCESSFULLY IN BOTH COLLECTIONS!');

                  // Track achievement
                  if (mounted) {
                    final gamificationService = context.read<GamificationService>();
                    await gamificationService.trackTaskCreated();
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task added successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding task: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'SAVE',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label, String selected, Color color, VoidCallback onTap) {
    final isSelected = label == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditTaskDialog(String taskId, Map<String, dynamic> taskData) async {
    final titleController = TextEditingController(text: taskData['title']);
    final subjectController = TextEditingController(text: taskData['subject']);
    final notesController = TextEditingController(text: taskData['notes'] ?? '');
    String selectedPriority = (taskData['priority'] ?? 'medium').toString().capitalize();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceAlt,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Task',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter task title...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subjectController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Subject',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priority:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityButton('Low', selectedPriority, AppTheme.accentSuccess, () {
                          setState(() => selectedPriority = 'Low');
                        }),
                        const SizedBox(width: 8),
                        _buildPriorityButton('Medium', selectedPriority, const Color(0xFFFFA726), () {
                          setState(() => selectedPriority = 'Medium');
                        }),
                        const SizedBox(width: 8),
                        _buildPriorityButton('High', selectedPriority, AppTheme.accentAlert, () {
                          setState(() => selectedPriority = 'High');
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter additional notes...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text(
                      'Save Changes?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    content: Text(
                      'Are you sure you want to save these changes?',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'SAVE',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
                
                if (confirmSave != true) return;
                
                try {
                  await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
                    'title': titleController.text.trim(),
                    'subject': subjectController.text.trim(),
                    'priority': selectedPriority.toLowerCase(),
                    'notes': notesController.text.trim(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating task: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'SAVE CHANGES',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask(String taskId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Delete Task?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Are you sure that you are going to delete this task?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAlert,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'CONFIRM',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting task: $e')),
          );
        }
      }
    }
  }

  Future<void> _showCompleteDialog(String taskId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mark as Completed?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'This task will be moved to your completed list.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentSuccess,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'FINISH',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _moveTask(taskId, 'completed');
    }
  }

  Future<void> _moveTask(String taskId, String newStatus) async {
    try {
      // Get task data to check due date and userId
      final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
      final taskData = taskDoc.data();
      
      final updateData = {
        'status': newStatus,
        if (newStatus == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      };
      
      // Update top-level collection
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update(updateData);
      
      // Also update user subcollection if userId exists
      if (taskData != null && taskData['userId'] != null) {
        final userId = taskData['userId'] as String;
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('tasks')
              .doc(taskId)
              .update(updateData);
        } catch (e) {
          debugPrint('⚠️ User subcollection update failed (task may not exist there): $e');
        }
      }

      // Track achievement for task completion
      if (newStatus == 'completed' && mounted) {
        final gamificationService = context.read<GamificationService>();
        
        // Check if task was completed on time
        bool onTime = false;
        if (taskData != null && taskData['dueDate'] != null) {
          final dueDate = (taskData['dueDate'] as Timestamp).toDate();
          onTime = DateTime.now().isBefore(dueDate);
        }
        
        await gamificationService.trackTaskCompleted(onTime: onTime);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAddSubjectDialog(TextEditingController subjectController) {
    final customSubjectController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.book, color: AppTheme.accentPrimary),
            const SizedBox(width: 12),
            Text(
              'Add New Subject',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customSubjectController,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter subject name',
                hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                prefixIcon: Icon(Icons.label, color: AppTheme.accentPrimary),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              'This subject will be available for all your tasks',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newSubject = customSubjectController.text.trim();
              if (newSubject.isNotEmpty) {
                setState(() {
                  subjectController.text = newSubject;
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Subject "$newSubject" added!'),
                    backgroundColor: AppTheme.accentSuccess,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Add',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceAlt,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Filter your Tasks by?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Subject filter
              Text(
                'Subject:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSubjectFilter,
                    hint: Text('Selection', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                    dropdownColor: AppTheme.surfaceHigh,
                    items: [null, 'Math', 'English', 'Science', 'History', 'General'].map((subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Text(
                          subject ?? 'All',
                          style: GoogleFonts.inter(color: AppTheme.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSubjectFilter = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Alphabetical filter
              Text(
                'Alphabetical:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterRadio('A to Z', _selectedAlphabeticalFilter == 'A to Z', () {
                      setState(() => _selectedAlphabeticalFilter = 'A to Z');
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterRadio('Z to A', _selectedAlphabeticalFilter == 'Z to A', () {
                      setState(() => _selectedAlphabeticalFilter = 'Z to A');
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Deadline filter
              Text(
                'Deadline:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterRadio('Soonest', _selectedDeadlineFilter == 'Soonest', () {
                      setState(() => _selectedDeadlineFilter = 'Soonest');
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterRadio('Latest', _selectedDeadlineFilter == 'Latest', () {
                      setState(() => _selectedDeadlineFilter = 'Latest');
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Priority filter
              Text(
                'Priority:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityFilterButton('Low', AppTheme.accentSuccess, setState),
                  const SizedBox(width: 8),
                  _buildPriorityFilterButton('Medium', const Color(0xFFFFA726), setState),
                  const SizedBox(width: 8),
                  _buildPriorityFilterButton('High', AppTheme.accentAlert, setState),
                ],
              ),
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        this.setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentSuccess,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CONFIRM',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRadio(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.accentPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.accentPrimary : AppTheme.textSecondary,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityFilterButton(String label, Color color, StateSetter setState) {
    final isSelected = _selectedPriorityFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPriorityFilter = isSelected ? null : label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryView() {
    final userId = context.watch<AuthService>().currentUser?.id;
    
    if (userId == null) {
      return Center(
        child: Text(
          'Please log in to view history',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
      );
    }

    // First get user's team IDs, then query both personal and team completed tasks
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where('memberIds', arrayContains: userId)
          .snapshots(),
      builder: (context, teamSnapshot) {
        List<String> userTeamIds = [];
        if (teamSnapshot.hasData) {
          userTeamIds = teamSnapshot.data!.docs.map((doc) => doc.id).toList();
        }

        // Query personal completed tasks from user subcollection
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('tasks')
              .where('status', isEqualTo: 'completed')
              .snapshots(),
          builder: (context, personalSnapshot) {
            if (personalSnapshot.hasError) {
              // Handle Firestore index error or other errors gracefully
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No history data yet',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add tasks to see your history here',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showHistory = false),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!personalSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Query team completed tasks from top-level tasks collection
            return StreamBuilder<QuerySnapshot?>(
              stream: userTeamIds.isEmpty
                  ? Stream.value(null) // Empty stream if no teams
                  : FirebaseFirestore.instance
                      .collection('tasks')
                      .where('status', isEqualTo: 'completed')
                      .where('isTeamTask', isEqualTo: true)
                      .snapshots(),
              builder: (context, teamTaskSnapshot) {
                // Combine personal and team completed tasks
                List<QueryDocumentSnapshot> completedTasks = [];
                
                // Add personal tasks
                completedTasks.addAll(personalSnapshot.data!.docs);
                
                // Add team tasks (filter by user's teams)
                if (teamTaskSnapshot.hasData && teamTaskSnapshot.data != null) {
                  final teamTasks = teamTaskSnapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final taskTeamId = data?['teamId'] as String?;
                    return taskTeamId != null && userTeamIds.contains(taskTeamId);
                  }).toList();
                  completedTasks.addAll(teamTasks);
                }
        
                // Sort by completedAt (most recent first)
                completedTasks.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['completedAt'] as Timestamp?;
                  final bTime = bData['completedAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime); // descending order
                });

                // Filter by search query
                final filteredTasks = _searchQuery.isEmpty
                    ? completedTasks
                    : completedTasks.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '').toString().toLowerCase();
                        final subject = (data['subject'] ?? '').toString().toLowerCase();
                        return title.contains(_searchQuery.toLowerCase()) ||
                               subject.contains(_searchQuery.toLowerCase());
                      }).toList();

                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.history : Icons.search_off,
                          size: 64,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No history data yet'
                              : 'No tasks found matching "$_searchQuery"',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Add tasks to see your history here'
                              : 'Try a different search term',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_searchQuery.isEmpty)
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _showHistory = false),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        else
                          TextButton(
                            onPressed: () => setState(() => _searchQuery = ''),
                            child: Text(
                              'Clear Search',
                              style: GoogleFonts.inter(color: AppTheme.accentPrimary),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                // Group by month
                final groupedTasks = <String, List<QueryDocumentSnapshot>>{}; 
                for (var task in filteredTasks) {
                  final data = task.data() as Map<String, dynamic>;
                  final completedAt = (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final monthYear = DateFormat('MMMM yyyy').format(completedAt);
                  groupedTasks.putIfAbsent(monthYear, () => []).add(task);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedTasks.length,
                  itemBuilder: (context, index) {
                    final monthYear = groupedTasks.keys.elementAt(index);
                    final tasks = groupedTasks[monthYear]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '[$monthYear]',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        ...tasks.map((taskDoc) {
                          final taskData = taskDoc.data() as Map<String, dynamic>;
                          return _buildHistoryTaskCard(taskData);
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTaskCard(Map<String, dynamic> taskData) {
    final title = taskData['title'] ?? 'Untitled';
    final subject = taskData['subject'] ?? 'General';
    final priority = taskData['priority'] ?? 'medium';
    final isTeamTask = taskData['isTeamTask'] == true;
    final startTime = taskData['startTime'] as String?;
    final endTime = taskData['endTime'] as String?;
    final dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _buildPriorityBadge(priority),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isTeamTask ? AppTheme.accentPrimary.withOpacity(0.2) : AppTheme.accentSuccess.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isTeamTask ? 'Team Task' : 'My Task',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isTeamTask ? AppTheme.accentPrimary : AppTheme.accentSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            startTime != null && endTime != null
                ? '$subject - ${dueDate != null ? DateFormat('EEEE').format(dueDate) : 'No date'}, Time Start - Time End'
                : subject,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          if (isTeamTask) ...[
            const SizedBox(height: 12),
            Row(
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.surfaceAlt,
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController(text: _searchQuery);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Search Task',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: TextField(
          controller: searchController,
          autofocus: true,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter task name...',
            hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                searchController.clear();
              });
            },
            child: Text(
              'CLEAR',
              style: GoogleFonts.inter(color: AppTheme.accentAlert),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'DONE',
              style: GoogleFonts.inter(color: AppTheme.accentPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
