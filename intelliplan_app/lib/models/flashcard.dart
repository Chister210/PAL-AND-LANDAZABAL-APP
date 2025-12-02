import 'package:cloud_firestore/cloud_firestore.dart';

enum CardDifficulty { easy, medium, hard }

class Flashcard {
  final String id;
  final String userId;
  final String deckName;
  final String question;
  final String answer;
  final String? courseCode;
  final List<String>? tags;
  final DateTime createdAt;
  
  // Spaced Repetition (SM-2 Algorithm)
  final double easeFactor; // 1.3 - 2.5+
  final int interval; // Days until next review
  final int repetitions; // Number of successful reviews
  final DateTime? nextReviewDate;
  final DateTime? lastReviewedAt;
  final CardDifficulty? lastDifficulty;

  Flashcard({
    required this.id,
    required this.userId,
    required this.deckName,
    required this.question,
    required this.answer,
    this.courseCode,
    this.tags,
    required this.createdAt,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    this.nextReviewDate,
    this.lastReviewedAt,
    this.lastDifficulty,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      userId: json['userId'] as String,
      deckName: json['deckName'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      courseCode: json['courseCode'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      interval: json['interval'] as int? ?? 0,
      repetitions: json['repetitions'] as int? ?? 0,
      nextReviewDate: json['nextReviewDate'] != null
          ? (json['nextReviewDate'] as Timestamp).toDate()
          : null,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? (json['lastReviewedAt'] as Timestamp).toDate()
          : null,
      lastDifficulty: json['lastDifficulty'] != null
          ? CardDifficulty.values.firstWhere(
              (e) => e.toString() == 'CardDifficulty.${json['lastDifficulty']}',
              orElse: () => CardDifficulty.medium,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deckName': deckName,
      'question': question,
      'answer': answer,
      'courseCode': courseCode,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'easeFactor': easeFactor,
      'interval': interval,
      'repetitions': repetitions,
      'nextReviewDate': nextReviewDate != null ? Timestamp.fromDate(nextReviewDate!) : null,
      'lastReviewedAt': lastReviewedAt != null ? Timestamp.fromDate(lastReviewedAt!) : null,
      'lastDifficulty': lastDifficulty?.toString().split('.').last,
    };
  }

  bool get isDueForReview {
    if (nextReviewDate == null) return true;
    return DateTime.now().isAfter(nextReviewDate!);
  }

  Flashcard copyWith({
    String? id,
    String? userId,
    String? deckName,
    String? question,
    String? answer,
    String? courseCode,
    List<String>? tags,
    DateTime? createdAt,
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? nextReviewDate,
    DateTime? lastReviewedAt,
    CardDifficulty? lastDifficulty,
  }) {
    return Flashcard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deckName: deckName ?? this.deckName,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      courseCode: courseCode ?? this.courseCode,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      lastDifficulty: lastDifficulty ?? this.lastDifficulty,
    );
  }
}
