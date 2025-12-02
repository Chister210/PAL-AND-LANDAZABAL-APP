import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskType { study, review, practice, collaborative, other }
enum TaskStatus { pending, inProgress, completed, cancelled }

class StudyTask {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TaskType type;
  final TaskStatus status;
  final DateTime? scheduledDate;
  final String? scheduledTime; // HH:mm format
  final int durationMinutes;
  final String? courseCode;
  final bool isCollaborative;
  final List<String>? collaboratorIds;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? notes;

  StudyTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.scheduledDate,
    this.scheduledTime,
    required this.durationMinutes,
    this.courseCode,
    this.isCollaborative = false,
    this.collaboratorIds,
    this.completedAt,
    required this.createdAt,
    this.notes,
  });

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    return StudyTask(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: TaskType.values.firstWhere(
        (e) => e.toString() == 'TaskType.${json['type']}',
        orElse: () => TaskType.study,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == 'TaskStatus.${json['status']}',
        orElse: () => TaskStatus.pending,
      ),
      scheduledDate: json['scheduledDate'] != null
          ? (json['scheduledDate'] as Timestamp).toDate()
          : null,
      scheduledTime: json['scheduledTime'] as String?,
      durationMinutes: json['durationMinutes'] as int,
      courseCode: json['courseCode'] as String?,
      isCollaborative: json['isCollaborative'] as bool? ?? false,
      collaboratorIds: json['collaboratorIds'] != null
          ? List<String>.from(json['collaboratorIds'])
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'dueDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null, // Add for Task Board compatibility
      'scheduledTime': scheduledTime,
      'durationMinutes': durationMinutes,
      'courseCode': courseCode,
      'isCollaborative': isCollaborative,
      'isTeamTask': false, // Personal tasks are never team tasks
      'collaboratorIds': collaboratorIds,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }

  StudyTask copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskType? type,
    TaskStatus? status,
    DateTime? scheduledDate,
    String? scheduledTime,
    int? durationMinutes,
    String? courseCode,
    bool? isCollaborative,
    List<String>? collaboratorIds,
    DateTime? completedAt,
    DateTime? createdAt,
    String? notes,
  }) {
    return StudyTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      courseCode: courseCode ?? this.courseCode,
      isCollaborative: isCollaborative ?? this.isCollaborative,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}
