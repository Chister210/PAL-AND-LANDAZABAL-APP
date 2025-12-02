import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_schedule.dart';
import '../models/assignment.dart';
import '../models/study_task.dart';

class ScheduleService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _currentUserId;
  List<ClassSchedule> _classes = [];
  List<Assignment> _assignments = [];
  List<StudyTask> _tasks = [];
  bool _isInitialized = false;

  List<ClassSchedule> get classes => _classes;
  List<Assignment> get assignments => _assignments;
  List<StudyTask> get tasks => _tasks;
  bool get isInitialized => _isInitialized;
  
  List<Assignment> get upcomingAssignments {
    final now = DateTime.now();
    return _assignments
        .where((a) => a.status != AssignmentStatus.completed && a.dueDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
  
  List<Assignment> get overdueAssignments {
    return _assignments
        .where((a) => a.status != AssignmentStatus.completed && a.isOverdue)
        .toList();
  }
  
  List<StudyTask> get todaysTasks {
    final today = DateTime.now();
    return _tasks.where((task) {
      if (task.scheduledDate == null) return false;
      return task.scheduledDate!.year == today.year &&
          task.scheduledDate!.month == today.month &&
          task.scheduledDate!.day == today.day &&
          task.status != TaskStatus.completed;
    }).toList();
  }

  /// Initialize service for user
  Future<void> initializeForUser(String userId) async {
    if (_currentUserId == userId && _isInitialized) return;
    
    _currentUserId = userId;
    _isInitialized = false;
    
    await Future.wait([
      loadClasses(),
      loadAssignments(),
      loadTasks(),
    ]);
    
    _isInitialized = true;
    notifyListeners();
  }

  // ==================== CLASS SCHEDULE ====================

  /// Load all class schedules
  Future<void> loadClasses() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('classes')
          .orderBy('dayOfWeek')
          .orderBy('startTime')
          .get();
      
      _classes = snapshot.docs
          .map((doc) => ClassSchedule.fromJson(doc.data()))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  /// Add new class schedule
  Future<void> addClass(ClassSchedule classSchedule) async {
    if (_currentUserId == null) return;
    
    try {
      // Check for conflicts
      if (hasTimeConflict(classSchedule)) {
        throw Exception('Time conflict detected with existing class');
      }
      
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('classes')
          .doc(classSchedule.id)
          .set(classSchedule.toJson());
      
      _classes.add(classSchedule);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding class: $e');
      rethrow;
    }
  }

  /// Update class schedule
  Future<void> updateClass(ClassSchedule classSchedule) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('classes')
          .doc(classSchedule.id)
          .update(classSchedule.toJson());
      
      final index = _classes.indexWhere((c) => c.id == classSchedule.id);
      if (index != -1) {
        _classes[index] = classSchedule;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating class: $e');
      rethrow;
    }
  }

  /// Delete class schedule
  Future<void> deleteClass(String classId) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('classes')
          .doc(classId)
          .delete();
      
      _classes.removeWhere((c) => c.id == classId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting class: $e');
      rethrow;
    }
  }

  /// Check for time conflicts
  bool hasTimeConflict(ClassSchedule newClass) {
    return _classes.any((existing) {
      if (existing.id == newClass.id) return false; // Skip same class
      if (existing.dayOfWeek != newClass.dayOfWeek) return false;
      
      // Parse times
      final existingStart = _parseTime(existing.startTime);
      final existingEnd = _parseTime(existing.endTime);
      final newStart = _parseTime(newClass.startTime);
      final newEnd = _parseTime(newClass.endTime);
      
      // Check overlap
      return (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart));
    });
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Get classes for specific day
  List<ClassSchedule> getClassesForDay(String dayOfWeek) {
    return _classes.where((c) => c.dayOfWeek == dayOfWeek).toList();
  }

  // ==================== ASSIGNMENTS ====================

  /// Load all assignments
  Future<void> loadAssignments() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('assignments')
          .orderBy('dueDate')
          .get();
      
      _assignments = snapshot.docs
          .map((doc) => Assignment.fromJson(doc.data()))
          .toList();
      
      // Update overdue status
      await _updateOverdueAssignments();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading assignments: $e');
    }
  }

  /// Add new assignment
  Future<void> addAssignment(Assignment assignment) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('assignments')
          .doc(assignment.id)
          .set(assignment.toJson());
      
      _assignments.add(assignment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding assignment: $e');
      rethrow;
    }
  }

  /// Update assignment
  Future<void> updateAssignment(Assignment assignment) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('assignments')
          .doc(assignment.id)
          .update(assignment.toJson());
      
      final index = _assignments.indexWhere((a) => a.id == assignment.id);
      if (index != -1) {
        _assignments[index] = assignment;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating assignment: $e');
      rethrow;
    }
  }

  /// Mark assignment as completed
  Future<void> completeAssignment(String assignmentId) async {
    final assignment = _assignments.firstWhere((a) => a.id == assignmentId);
    final completed = assignment.copyWith(
      status: AssignmentStatus.completed,
      completedAt: DateTime.now(),
    );
    await updateAssignment(completed);
  }

  /// Delete assignment
  Future<void> deleteAssignment(String assignmentId) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('assignments')
          .doc(assignmentId)
          .delete();
      
      _assignments.removeWhere((a) => a.id == assignmentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting assignment: $e');
      rethrow;
    }
  }

  /// Update overdue assignments
  Future<void> _updateOverdueAssignments() async {
    for (var assignment in _assignments) {
      if (assignment.isOverdue && assignment.status != AssignmentStatus.overdue) {
        await updateAssignment(assignment.copyWith(status: AssignmentStatus.overdue));
      }
    }
  }

  // ==================== STUDY TASKS ====================

  /// Load all tasks
  Future<void> loadTasks() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get();
      
      _tasks = snapshot.docs
          .map((doc) => StudyTask.fromJson(doc.data()))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  /// Add new task
  Future<void> addTask(StudyTask task) async {
    if (_currentUserId == null) return;
    
    try {
      final taskJson = task.toJson();
      debugPrint('📝 Adding task: ${task.title}, Status: ${task.status}, ID: ${task.id}');
      debugPrint('📝 Task JSON status: ${taskJson['status']}');
      
      // Save to user subcollection for home screen
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tasks')
          .doc(task.id)
          .set(taskJson);
      debugPrint('✅ Saved to users/$_currentUserId/tasks/${task.id}');
      
      // Also save to top-level tasks collection for Task Board
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .set(taskJson);
      debugPrint('✅ Saved to tasks/${task.id}');
      
      _tasks.add(task);
      notifyListeners();
      debugPrint('✅ Task added successfully!');
    } catch (e) {
      debugPrint('❌ Error adding task: $e');
      rethrow;
    }
  }

  /// Update task
  Future<void> updateTask(StudyTask task) async {
    if (_currentUserId == null) return;
    
    try {
      final taskJson = task.toJson();
      
      // Update in user subcollection
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tasks')
          .doc(task.id)
          .update(taskJson);
      
      // Update in top-level tasks collection
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(taskJson);
      
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  /// Complete task
  Future<void> completeTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final completed = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
    await updateTask(completed);
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    if (_currentUserId == null) return;
    
    try {
      // Delete from user subcollection
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tasks')
          .doc(taskId)
          .delete();
      
      // Delete from top-level tasks collection
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .delete();
      
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  /// Get tasks for date
  List<StudyTask> getTasksForDate(DateTime date) {
    return _tasks.where((task) {
      if (task.scheduledDate == null) return false;
      return task.scheduledDate!.year == date.year &&
          task.scheduledDate!.month == date.month &&
          task.scheduledDate!.day == date.day;
    }).toList();
  }

  // ==================== HELPER METHODS ====================

  /// Get all events for a specific date (classes, assignments due, tasks)
  Map<String, dynamic> getEventsForDate(DateTime date) {
    final dayName = _getDayName(date);
    
    return {
      'classes': getClassesForDay(dayName),
      'tasks': getTasksForDate(date),
      'assignments': _assignments.where((a) {
        return a.dueDate.year == date.year &&
            a.dueDate.month == date.month &&
            a.dueDate.day == date.day;
      }).toList(),
    };
  }

  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  /// Check if user has conflicts on a specific date/time
  bool hasConflictOnDateTime(DateTime date, String startTime, String endTime) {
    final dayName = _getDayName(date);
    final classesOnDay = getClassesForDay(dayName);
    final tasksOnDay = getTasksForDate(date);
    
    // Check class conflicts
    for (var classItem in classesOnDay) {
      if (_timeOverlaps(startTime, endTime, classItem.startTime, classItem.endTime)) {
        return true;
      }
    }
    
    // Check task conflicts
    for (var task in tasksOnDay) {
      if (task.scheduledTime != null) {
        final taskEnd = _addMinutesToTime(task.scheduledTime!, task.durationMinutes);
        if (_timeOverlaps(startTime, endTime, task.scheduledTime!, taskEnd)) {
          return true;
        }
      }
    }
    
    return false;
  }

  bool _timeOverlaps(String start1, String end1, String start2, String end2) {
    final s1 = _parseTime(start1);
    final e1 = _parseTime(end1);
    final s2 = _parseTime(start2);
    final e2 = _parseTime(end2);
    
    return s1.isBefore(e2) && e1.isAfter(s2);
  }

  String _addMinutesToTime(String time, int minutes) {
    final dt = _parseTime(time).add(Duration(minutes: minutes));
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
