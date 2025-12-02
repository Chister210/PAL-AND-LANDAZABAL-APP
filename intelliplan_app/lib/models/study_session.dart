import 'package:cloud_firestore/cloud_firestore.dart';

enum StudyTechnique { pomodoro, spacedRepetition, activeRecall, normal }
enum SessionStatus { planned, active, paused, completed, cancelled }

class StudySession {
  final String id;
  final String userId;
  final StudyTechnique technique;
  final SessionStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String? courseCode;
  final String? topic;
  final int pomodoroCount; // Number of pomodoros completed
  final int breakCount; // Number of breaks taken
  final List<String>? notes;
  final double? productivityScore; // 0-100
  final DateTime createdAt;

  StudySession({
    required this.id,
    required this.userId,
    required this.technique,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.courseCode,
    this.topic,
    this.pomodoroCount = 0,
    this.breakCount = 0,
    this.notes,
    this.productivityScore,
    required this.createdAt,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    try {
      final startTime = _parseTimestamp(json['startTime']) ?? DateTime.now();
      final endTime = _parseTimestamp(json['endTime']);
      
      // Try to get duration from multiple sources
      int durationMinutes = _parseInt(json['durationMinutes'] ?? json['duration']);
      
      // If no duration field, calculate from endTime - startTime
      if (durationMinutes == 0 && endTime != null) {
        durationMinutes = endTime.difference(startTime).inMinutes;
        if (durationMinutes < 0) durationMinutes = 0; // Safeguard against negative durations
      }
      
      return StudySession(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        technique: _parseTechnique(json['technique']),
        status: _parseStatus(json['status']),
        startTime: startTime,
        endTime: endTime,
        durationMinutes: durationMinutes,
        courseCode: json['courseCode'] as String?,
        topic: json['topic'] as String?,
        pomodoroCount: (json['pomodoroCount'] ?? 0) as int,
        breakCount: (json['breakCount'] ?? 0) as int,
        notes: json['notes'] != null ? List<String>.from(json['notes']) : null,
        productivityScore: _parseDouble(json['productivityScore']),
        createdAt: _parseTimestamp(json['createdAt']) ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing StudySession: $e');
      // Return a default session on error
      return StudySession(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        technique: StudyTechnique.normal,
        status: SessionStatus.completed,
        startTime: DateTime.now(),
        durationMinutes: 0,
        createdAt: DateTime.now(),
      );
    }
  }
  
  static StudyTechnique _parseTechnique(dynamic value) {
    if (value == null) return StudyTechnique.normal;
    
    final String techniqueStr = value.toString().toLowerCase();
    
    if (techniqueStr.contains('pomodoro')) return StudyTechnique.pomodoro;
    if (techniqueStr.contains('spaced') || techniqueStr.contains('repetition')) {
      return StudyTechnique.spacedRepetition;
    }
    if (techniqueStr.contains('active') || techniqueStr.contains('recall')) {
      return StudyTechnique.activeRecall;
    }
    
    return StudyTechnique.normal;
  }
  
  static SessionStatus _parseStatus(dynamic value) {
    if (value == null) return SessionStatus.completed;
    
    final String statusStr = value.toString().toLowerCase();
    
    if (statusStr.contains('planned')) return SessionStatus.planned;
    if (statusStr.contains('active')) return SessionStatus.active;
    if (statusStr.contains('paused')) return SessionStatus.paused;
    if (statusStr.contains('cancelled')) return SessionStatus.cancelled;
    
    return SessionStatus.completed;
  }
  
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is DateTime) {
        return value;
      } else if (value is String) {
        return DateTime.parse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
    }
    
    return null;
  }
  
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
    } catch (e) {
      print('Error parsing double: $e');
    }
    
    return null;
  }
  
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    
    try {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
        final parsedDouble = double.tryParse(value);
        if (parsedDouble != null) return parsedDouble.toInt();
      }
    } catch (e) {
      print('Error parsing int: $e');
    }
    
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'technique': technique.toString().split('.').last,
      'status': status.toString().split('.').last,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationMinutes': durationMinutes,
      'courseCode': courseCode,
      'topic': topic,
      'pomodoroCount': pomodoroCount,
      'breakCount': breakCount,
      'notes': notes,
      'productivityScore': productivityScore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  StudySession copyWith({
    String? id,
    String? userId,
    StudyTechnique? technique,
    SessionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? courseCode,
    String? topic,
    int? pomodoroCount,
    int? breakCount,
    List<String>? notes,
    double? productivityScore,
    DateTime? createdAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      technique: technique ?? this.technique,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      courseCode: courseCode ?? this.courseCode,
      topic: topic ?? this.topic,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      breakCount: breakCount ?? this.breakCount,
      notes: notes ?? this.notes,
      productivityScore: productivityScore ?? this.productivityScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
