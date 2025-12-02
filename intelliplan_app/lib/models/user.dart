import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final int level;
  final int experience;
  final DateTime createdAt;
  final String? studyTechnique;
  
  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.level,
    required this.experience,
    required this.createdAt,
    this.studyTechnique,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    // Handle createdAt - can be either Timestamp (old users) or String (new users)
    DateTime createdAtDate;
    if (json['createdAt'] is Timestamp) {
      createdAtDate = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAtDate = DateTime.parse(json['createdAt']);
    } else {
      createdAtDate = DateTime.now();
    }
    
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      createdAt: createdAtDate,
      studyTechnique: json['studyTechnique'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'level': level,
      'experience': experience,
      'createdAt': createdAt.toIso8601String(),
      'studyTechnique': studyTechnique,
    };
  }
  
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    int? level,
    int? experience,
    DateTime? createdAt,
    String? studyTechnique,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      createdAt: createdAt ?? this.createdAt,
      studyTechnique: studyTechnique ?? this.studyTechnique,
    );
  }
}
