import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentPriority { low, medium, high, urgent }
enum AssignmentStatus { pending, inProgress, completed, overdue }

class Assignment {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String courseCode;
  final DateTime dueDate;
  final AssignmentPriority priority;
  final AssignmentStatus status;
  final int estimatedHours;
  final DateTime? completedAt;
  final DateTime createdAt;
  final List<String>? tags;
  final String? attachmentUrl;

  Assignment({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.courseCode,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.estimatedHours,
    this.completedAt,
    required this.createdAt,
    this.tags,
    this.attachmentUrl,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      courseCode: json['courseCode'] as String,
      dueDate: (json['dueDate'] as Timestamp).toDate(),
      priority: AssignmentPriority.values.firstWhere(
        (e) => e.toString() == 'AssignmentPriority.${json['priority']}',
        orElse: () => AssignmentPriority.medium,
      ),
      status: AssignmentStatus.values.firstWhere(
        (e) => e.toString() == 'AssignmentStatus.${json['status']}',
        orElse: () => AssignmentStatus.pending,
      ),
      estimatedHours: json['estimatedHours'] as int,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      attachmentUrl: json['attachmentUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'courseCode': courseCode,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'estimatedHours': estimatedHours,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'tags': tags,
      'attachmentUrl': attachmentUrl,
    };
  }

  bool get isOverdue => status != AssignmentStatus.completed && dueDate.isBefore(DateTime.now());

  Assignment copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? courseCode,
    DateTime? dueDate,
    AssignmentPriority? priority,
    AssignmentStatus? status,
    int? estimatedHours,
    DateTime? completedAt,
    DateTime? createdAt,
    List<String>? tags,
    String? attachmentUrl,
  }) {
    return Assignment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      courseCode: courseCode ?? this.courseCode,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}
