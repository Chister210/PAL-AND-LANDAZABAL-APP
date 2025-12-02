import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectFile {
  final String name;
  final String? url;
  final int? sizeInBytes;
  final DateTime uploadedAt;

  SubjectFile({
    required this.name,
    this.url,
    this.sizeInBytes,
    required this.uploadedAt,
  });

  factory SubjectFile.fromJson(Map<String, dynamic> json) {
    return SubjectFile(
      name: json['name'] as String,
      url: json['url'] as String?,
      sizeInBytes: json['sizeInBytes'] as int?,
      uploadedAt: (json['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'sizeInBytes': sizeInBytes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

class Subject {
  final String id;
  final String userId;
  final String name;
  final List<String> weekdays; // e.g., ['Mon', 'Tue', 'Wed']
  final String startTime; // HH:mm format
  final String endTime; // HH:mm format
  final String fieldOfStudy; // 'Minor Subject' or 'Major Subject'
  final List<SubjectFile> files;
  final String? notes;
  final String? color; // Hex color for UI
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject({
    required this.id,
    required this.userId,
    required this.name,
    required this.weekdays,
    required this.startTime,
    required this.endTime,
    required this.fieldOfStudy,
    this.files = const [],
    this.notes,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      weekdays: (json['weekdays'] as List<dynamic>).cast<String>(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      fieldOfStudy: json['fieldOfStudy'] as String,
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => SubjectFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
      color: json['color'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'weekdays': weekdays,
      'startTime': startTime,
      'endTime': endTime,
      'fieldOfStudy': fieldOfStudy,
      'files': files.map((f) => f.toJson()).toList(),
      'notes': notes,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Subject copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? weekdays,
    String? startTime,
    String? endTime,
    String? fieldOfStudy,
    List<SubjectFile>? files,
    String? notes,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      weekdays: weekdays ?? this.weekdays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      files: files ?? this.files,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get weekdaysDisplay => weekdays.join(', ');
  
  String get timeDisplay => '$startTime - $endTime';
}
