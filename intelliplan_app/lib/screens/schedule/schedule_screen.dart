import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import 'package:intl/intl.dart';
import '../../services/schedule_service.dart';
import '../../services/auth_service.dart';
import '../../models/class_schedule.dart';
import '../../models/assignment.dart';
import '../../models/study_task.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeSchedule();
  }

  Future<void> _initializeSchedule() async {
    final authService = context.read<AuthService>();
    final scheduleService = context.read<ScheduleService>();
    
    if (authService.currentUser != null) {
      await scheduleService.initializeForUser(authService.currentUser!.id);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final authService = context.watch<AuthService>();

    if (authService.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Schedule')),
        body: const Center(child: Text('Please log in to view your schedule')),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Schedule')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Schedule'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Classes'),
            Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
            Tab(icon: Icon(Icons.task_alt), text: 'Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClassesTab(scheduleService),
          _buildAssignmentsTab(scheduleService),
          _buildTasksTab(scheduleService),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, scheduleService, authService.currentUser!.id),
        icon: const Icon(Icons.add),
        label: Text(_getAddButtonText()),
      ),
    );
  }

  String _getAddButtonText() {
    switch (_tabController.index) {
      case 0:
        return 'Add Class';
      case 1:
        return 'Add Assignment';
      case 2:
        return 'Add Task';
      default:
        return 'Add';
    }
  }

  Widget _buildClassesTab(ScheduleService service) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWeeklyOverview(service),
        const SizedBox(height: 24),
        ...days.map((day) => _buildDaySection(day, service)),
      ],
    );
  }

  Widget _buildWeeklyOverview(ScheduleService service) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Schedule',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('Your class timetable'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip('${service.classes.length} Classes', Icons.class_, Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip('${service.classes.map((c) => c.courseCode).toSet().length} Courses', Icons.book, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(String day, ScheduleService service) {
    final classes = service.getClassesForDay(day);
    
    if (classes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            day,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...classes.map((classItem) => _buildClassCard(classItem, service)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildClassCard(ClassSchedule classItem, ScheduleService service) {
    final color = classItem.color != null 
        ? Color(int.parse(classItem.color!.replaceFirst('#', '0xFF')))
        : Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showClassDetails(classItem, service),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        classItem.startTime,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_downward, size: 12),
                      Text(
                        classItem.endTime,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classItem.courseCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classItem.courseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(classItem.instructor, style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(classItem.location, style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab(ScheduleService service) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (service.overdueAssignments.isNotEmpty) ...[
          _buildSectionHeader('Overdue', Icons.warning, Colors.red),
          ...service.overdueAssignments.map((a) => _buildAssignmentCard(a, service)),
          const SizedBox(height: 16),
        ],
        _buildSectionHeader('Upcoming', Icons.event, Colors.blue),
        if (service.upcomingAssignments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No upcoming assignments'),
            ),
          )
        else
          ...service.upcomingAssignments.take(10).map((a) => _buildAssignmentCard(a, service)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment, ScheduleService service) {
    final isOverdue = assignment.isOverdue;
    final daysUntilDue = assignment.dueDate.difference(DateTime.now()).inDays;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isOverdue ? Colors.red[50] : null,
      child: InkWell(
        onTap: () => _showAssignmentDetails(assignment, service),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(assignment.priority).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      assignment.courseCode,
                      style: TextStyle(
                        color: _getPriorityColor(assignment.priority),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _getPriorityIcon(assignment.priority),
                    color: _getPriorityColor(assignment.priority),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                assignment.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                assignment.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: isOverdue ? Colors.red : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    isOverdue
                        ? 'Overdue!'
                        : daysUntilDue == 0
                            ? 'Due today'
                            : 'Due in $daysUntilDue days',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(assignment.dueDate),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (assignment.status != AssignmentStatus.pending)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Chip(
                    label: Text(assignment.status.toString().split('.').last),
                    backgroundColor: _getStatusColor(assignment.status),
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksTab(ScheduleService service) {
    final todaysTasks = service.todaysTasks;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateSelector(),
        const SizedBox(height: 16),
        _buildSectionHeader('Today\'s Tasks', Icons.task, Colors.purple),
        if (todaysTasks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No tasks for today!', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          )
        else
          ...todaysTasks.map((task) => _buildTaskCard(task, service)),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                });
              },
            ),
            Text(
              DateFormat('EEEE, MMMM dd').format(_selectedDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(StudyTask task, ScheduleService service) {
    final color = _getTaskTypeColor(task.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTaskDetails(task, service),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Checkbox(
                  value: task.status == TaskStatus.completed,
                  onChanged: (value) async {
                    if (value == true) {
                      await service.completeTask(task.id);
                    }
                  },
                  activeColor: color,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            task.scheduledTime ?? 'No time set',
                            style: TextStyle(color: color, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${task.durationMinutes} min',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(AssignmentPriority priority) {
    switch (priority) {
      case AssignmentPriority.urgent:
        return Colors.red;
      case AssignmentPriority.high:
        return Colors.orange;
      case AssignmentPriority.medium:
        return Colors.blue;
      case AssignmentPriority.low:
        return Colors.green;
    }
  }

  IconData _getPriorityIcon(AssignmentPriority priority) {
    switch (priority) {
      case AssignmentPriority.urgent:
        return Icons.priority_high;
      case AssignmentPriority.high:
        return Icons.arrow_upward;
      case AssignmentPriority.medium:
        return Icons.remove;
      case AssignmentPriority.low:
        return Icons.arrow_downward;
    }
  }

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.completed:
        return Colors.green;
      case AssignmentStatus.inProgress:
        return Colors.blue;
      case AssignmentStatus.overdue:
        return Colors.red;
      case AssignmentStatus.pending:
        return Colors.grey;
    }
  }

  Color _getTaskTypeColor(TaskType type) {
    switch (type) {
      case TaskType.study:
        return Colors.blue;
      case TaskType.review:
        return Colors.purple;
      case TaskType.practice:
        return Colors.orange;
      case TaskType.collaborative:
        return Colors.green;
      case TaskType.other:
        return Colors.grey;
    }
  }

  void _showAddDialog(BuildContext context, ScheduleService service, String userId) {
    switch (_tabController.index) {
      case 0:
        _showAddClassDialog(context, service, userId);
        break;
      case 1:
        _showAddAssignmentDialog(context, service, userId);
        break;
      case 2:
        _showAddTaskDialog(context, service, userId);
        break;
    }
  }

  void _showAddClassDialog(BuildContext context, ScheduleService service, String userId) {
    final formKey = GlobalKey<FormState>();
    final courseNameController = TextEditingController();
    final courseCodeController = TextEditingController();
    final instructorController = TextEditingController();
    final locationController = TextEditingController();
    String selectedDay = 'Monday';
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Class'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: courseCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Course Code',
                      hintText: 'e.g., CS101',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: courseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Course Name',
                      hintText: 'e.g., Introduction to Computer Science',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: instructorController,
                    decoration: const InputDecoration(
                      labelText: 'Instructor',
                      hintText: 'e.g., Prof. Smith',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g., Room 301',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: const InputDecoration(labelText: 'Day of Week'),
                    items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                        .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                        .toList(),
                    onChanged: (value) => setState(() => selectedDay = value ?? 'Monday'),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Start Time'),
                    trailing: Text(
                      startTime.format(context),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (time != null) {
                        setState(() => startTime = time);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Time'),
                    trailing: Text(
                      endTime.format(context),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (time != null) {
                        setState(() => endTime = time);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final classSchedule = ClassSchedule(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: userId,
                      courseName: courseNameController.text,
                      courseCode: courseCodeController.text,
                      instructor: instructorController.text,
                      location: locationController.text,
                      dayOfWeek: selectedDay,
                      startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                      endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                      createdAt: DateTime.now(),
                    );

                    await service.addClass(classSchedule);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Class added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add Class'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAssignmentDialog(BuildContext context, ScheduleService service, String userId) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final courseCodeController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    AssignmentPriority priority = AssignmentPriority.medium;
    int estimatedHours = 2;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Assignment'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., Research Paper',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Assignment details...',
                    ),
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: courseCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Course Code',
                      hintText: 'e.g., CS101',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due Date'),
                    subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(dueDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
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
                                headlineMedium: TextStyle(color: Colors.white),
                                labelLarge: TextStyle(color: Colors.white),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) setState(() => dueDate = date);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AssignmentPriority>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: AssignmentPriority.values
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Row(
                                children: [
                                  Icon(
                                    _getPriorityIcon(p),
                                    color: _getPriorityColor(p),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(p.toString().split('.').last.toUpperCase()),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => priority = value ?? AssignmentPriority.medium),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: estimatedHours.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Estimated Hours',
                      hintText: 'How long will this take?',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => estimatedHours = int.tryParse(v) ?? 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final assignment = Assignment(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: userId,
                      title: titleController.text,
                      description: descriptionController.text,
                      courseCode: courseCodeController.text,
                      dueDate: dueDate,
                      priority: priority,
                      status: AssignmentStatus.pending,
                      estimatedHours: estimatedHours,
                      createdAt: DateTime.now(),
                    );

                    await service.addAssignment(assignment);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Assignment added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add Assignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, ScheduleService service, String userId) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final courseCodeController = TextEditingController();
    DateTime scheduledDate = _selectedDate;
    TimeOfDay scheduledTime = TimeOfDay.now();
    int durationMinutes = 30;
    TaskType taskType = TaskType.study;
    bool isCollaborative = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during submission
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          bool isSubmitting = false;
          
          return AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'e.g., Study for exam',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Task details...',
                    ),
                    maxLines: 2,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: courseCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Course Code (Optional)',
                      hintText: 'e.g., CS101',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskType>(
                    value: taskType,
                    decoration: const InputDecoration(labelText: 'Task Type'),
                    items: TaskType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Row(
                                children: [
                                  Icon(
                                    _getTaskTypeIcon(t),
                                    color: _getTaskTypeColor(t),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(t.toString().split('.').last.toUpperCase()),
                                ],
                              ),
                            ))
                        .toSet()
                        .toList(),
                    onChanged: (value) => setState(() => taskType = value ?? TaskType.study),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Scheduled Date'),
                    subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(scheduledDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: scheduledDate,
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
                                headlineMedium: TextStyle(color: Colors.white),
                                labelLarge: TextStyle(color: Colors.white),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) setState(() => scheduledDate = date);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Scheduled Time'),
                    subtitle: Text(scheduledTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: scheduledTime,
                      );
                      if (time != null) setState(() => scheduledTime = time);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: durationMinutes.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      hintText: 'e.g., 30',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => durationMinutes = int.tryParse(v) ?? 30,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Collaborative Task'),
                    subtitle: const Text('Share with team members'),
                    value: isCollaborative,
                    onChanged: (value) => setState(() => isCollaborative = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() => isSubmitting = true);
                  
                  try {
                    final task = StudyTask(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: userId,
                      title: titleController.text,
                      description: descriptionController.text,
                      type: taskType,
                      status: TaskStatus.pending,
                      scheduledDate: scheduledDate,
                      scheduledTime: '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
                      durationMinutes: durationMinutes,
                      courseCode: courseCodeController.text.isEmpty ? null : courseCodeController.text,
                      isCollaborative: isCollaborative,
                      createdAt: DateTime.now(),
                    );

                    await service.addTask(task);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Task added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() => isSubmitting = false);
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Add Task'),
            ),
          ],
        );
        },
      ),
    );
  }

  IconData _getTaskTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.study:
        return Icons.book;
      case TaskType.review:
        return Icons.refresh;
      case TaskType.practice:
        return Icons.edit;
      case TaskType.collaborative:
        return Icons.group;
      case TaskType.other:
        return Icons.more_horiz;
    }
  }

  void _showClassDetails(ClassSchedule classItem, ScheduleService service) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(classItem.courseName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(classItem.courseCode, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const Divider(height: 32),
            _buildDetailRow(Icons.person, 'Instructor', classItem.instructor),
            _buildDetailRow(Icons.location_on, 'Location', classItem.location),
            _buildDetailRow(Icons.calendar_today, 'Day', classItem.dayOfWeek),
            _buildDetailRow(Icons.access_time, 'Time', '${classItem.startTime} - ${classItem.endTime}'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      service.deleteClass(classItem.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Class deleted')),
                      );
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignmentDetails(Assignment assignment, ScheduleService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(assignment.courseCode, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const Divider(height: 32),
            Text(assignment.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today, 'Due Date', DateFormat('MMM dd, yyyy').format(assignment.dueDate)),
            _buildDetailRow(Icons.priority_high, 'Priority', assignment.priority.toString().split('.').last),
            _buildDetailRow(Icons.timer, 'Estimated Time', '${assignment.estimatedHours} hours'),
            const SizedBox(height: 20),
            if (assignment.status != AssignmentStatus.completed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await service.completeAssignment(assignment.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assignment marked as completed!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(StudyTask task, ScheduleService service) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            Text(task.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.category, 'Type', task.type.toString().split('.').last),
            _buildDetailRow(Icons.access_time, 'Time', task.scheduledTime ?? 'Not set'),
            _buildDetailRow(Icons.timer, 'Duration', '${task.durationMinutes} minutes'),
            const SizedBox(height: 20),
            if (task.status != TaskStatus.completed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await service.completeTask(task.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task completed!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
