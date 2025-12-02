import 'package:cloud_firestore/cloud_firestore.dart';

/// Active Recall Question
class RecallQuestion {
  final String id;
  final String userId;
  final String question;
  final String correctAnswer;
  final List<String> keywords; // For partial matching
  final String? topic;
  final int difficulty; // 1-5
  final int timesAsked;
  final double averageAccuracy;
  final DateTime createdAt;
  final DateTime? lastAskedAt;

  RecallQuestion({
    required this.id,
    required this.userId,
    required this.question,
    required this.correctAnswer,
    required this.keywords,
    this.topic,
    required this.difficulty,
    required this.timesAsked,
    required this.averageAccuracy,
    required this.createdAt,
    this.lastAskedAt,
  });

  factory RecallQuestion.fromJson(Map<String, dynamic> json) {
    return RecallQuestion(
      id: json['id'] as String,
      userId: json['userId'] as String,
      question: json['question'] as String,
      correctAnswer: json['correctAnswer'] as String,
      keywords: List<String>.from(json['keywords'] ?? []),
      topic: json['topic'] as String?,
      difficulty: json['difficulty'] as int? ?? 3,
      timesAsked: json['timesAsked'] as int? ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastAskedAt: json['lastAskedAt'] != null
          ? (json['lastAskedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'question': question,
      'correctAnswer': correctAnswer,
      'keywords': keywords,
      'topic': topic,
      'difficulty': difficulty,
      'timesAsked': timesAsked,
      'averageAccuracy': averageAccuracy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastAskedAt': lastAskedAt != null ? Timestamp.fromDate(lastAskedAt!) : null,
    };
  }
}

/// Active Recall Session
class RecallSession {
  final String id;
  final String userId;
  final List<String> questionIds;
  final List<RecallAttempt> attempts;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? topic;

  RecallSession({
    required this.id,
    required this.userId,
    required this.questionIds,
    required this.attempts,
    required this.startedAt,
    this.completedAt,
    this.topic,
  });

  int get xpEarned => attempts.fold<int>(0, (sum, attempt) => sum + attempt.xpEarned);
  
  double get accuracy {
    if (attempts.isEmpty) return 0.0;
    return attempts.fold<double>(0, (sum, attempt) => sum + attempt.accuracy) / attempts.length;
  }
  
  bool get isComplete => completedAt != null;

  RecallSession copyWith({
    List<RecallAttempt>? attempts,
    DateTime? completedAt,
  }) {
    return RecallSession(
      id: id,
      userId: userId,
      questionIds: questionIds,
      attempts: attempts ?? this.attempts,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      topic: topic,
    );
  }

  factory RecallSession.fromJson(Map<String, dynamic> json) {
    return RecallSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      questionIds: List<String>.from(json['questionIds'] ?? []),
      attempts: (json['attempts'] as List<dynamic>?)
              ?.map((e) => RecallAttempt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      startedAt: (json['startedAt'] as Timestamp).toDate(),
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      topic: json['topic'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'questionIds': questionIds,
      'attempts': attempts.map((a) => a.toJson()).toList(),
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'topic': topic,
      'xpEarned': xpEarned,
      'accuracy': accuracy,
    };
  }
}

/// Individual recall attempt within a session
class RecallAttempt {
  final String questionId;
  final String userAnswer;
  final double accuracy; // 0.0 to 1.0
  final int xpEarned;
  final DateTime answeredAt;

  RecallAttempt({
    required this.questionId,
    required this.userAnswer,
    required this.accuracy,
    required this.xpEarned,
    required this.answeredAt,
  });

  bool get isCorrect => accuracy >= 0.9;
  bool get isPartiallyCorrect => accuracy >= 0.5 && accuracy < 0.9;

  factory RecallAttempt.fromJson(Map<String, dynamic> json) {
    return RecallAttempt(
      questionId: json['questionId'] as String,
      userAnswer: json['userAnswer'] as String,
      accuracy: (json['accuracy'] as num).toDouble(),
      xpEarned: json['xpEarned'] as int,
      answeredAt: (json['answeredAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'accuracy': accuracy,
      'xpEarned': xpEarned,
      'answeredAt': Timestamp.fromDate(answeredAt),
    };
  }
}

