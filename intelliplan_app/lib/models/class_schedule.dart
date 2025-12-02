import 'package:cloud_firestore/cloud_firestore.dart';

class ClassSchedule {
  final String id;
  final String userId;
  final String courseName;
  final String courseCode;
  final String instructor;
  final String location;
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String startTime; // HH:mm format
  final String endTime;
  final String? color; // Hex color for UI
  final DateTime createdAt;

  ClassSchedule({
    required this.id,
    required this.userId,
    required this.courseName,
    required this.courseCode,
    required this.instructor,
    required this.location,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.color,
    required this.createdAt,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id'] as String,
      userId: json['userId'] as String,
      courseName: json['courseName'] as String,
      courseCode: json['courseCode'] as String,
      instructor: json['instructor'] as String,
      location: json['location'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      color: json['color'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'courseName': courseName,
      'courseCode': courseCode,
      'instructor': instructor,
      'location': location,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ClassSchedule copyWith({
    String? id,
    String? userId,
    String? courseName,
    String? courseCode,
    String? instructor,
    String? location,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? color,
    DateTime? createdAt,
  }) {
    return ClassSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      instructor: instructor ?? this.instructor,
      location: location ?? this.location,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
