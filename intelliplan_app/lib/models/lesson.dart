class Lesson {
  final String id;
  final String title;
  final String description;
  final String subject;
  final int duration; // in minutes
  final LessonDifficulty difficulty;
  final List<String> topics;
  final bool isCompleted;
  final double? progress;
  final DateTime? completedAt;
  
  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.duration,
    required this.difficulty,
    required this.topics,
    required this.isCompleted,
    this.progress,
    this.completedAt,
  });
  
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      subject: json['subject'],
      duration: json['duration'],
      difficulty: LessonDifficulty.values.firstWhere(
        (e) => e.toString() == 'LessonDifficulty.${json['difficulty']}',
        orElse: () => LessonDifficulty.medium,
      ),
      topics: List<String>.from(json['topics'] ?? []),
      isCompleted: json['isCompleted'] ?? false,
      progress: json['progress']?.toDouble(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'duration': duration,
      'difficulty': difficulty.toString().split('.').last,
      'topics': topics,
      'isCompleted': isCompleted,
      'progress': progress,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

enum LessonDifficulty {
  beginner,
  medium,
  advanced,
  expert,
}
