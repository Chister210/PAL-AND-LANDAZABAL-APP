import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flashcard.dart';
import 'gamification_service.dart';

/// Spaced Repetition Service using SM-2 Algorithm
class SpacedRepetitionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationService? _gamificationService;
  
  String? _currentUserId;
  List<Flashcard> _flashcards = [];
  Map<String, List<Flashcard>> _deckMap = {};

  List<Flashcard> get flashcards => _flashcards;
  Map<String, List<Flashcard>> get deckMap => _deckMap;
  
  List<Flashcard> get dueCards {
    return _flashcards.where((card) => card.isDueForReview).toList();
  }
  
  List<String> get deckNames => _deckMap.keys.toList();

  SpacedRepetitionService(this._gamificationService);

  /// Initialize for user
  Future<void> initializeForUser(String userId) async {
    _currentUserId = userId;
    await loadFlashcards();
  }

  /// Load all flashcards
  Future<void> loadFlashcards() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('flashcards')
          .orderBy('createdAt', descending: true)
          .get();
      
      _flashcards = snapshot.docs
          .map((doc) => Flashcard.fromJson(doc.data()))
          .toList();
      
      _organizeDeck();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading flashcards: $e');
    }
  }

  void _organizeDeck() {
    _deckMap.clear();
    for (var card in _flashcards) {
      if (!_deckMap.containsKey(card.deckName)) {
        _deckMap[card.deckName] = [];
      }
      _deckMap[card.deckName]!.add(card);
    }
  }

  /// Add new flashcard
  Future<void> addFlashcard(Flashcard flashcard) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('flashcards')
          .doc(flashcard.id)
          .set(flashcard.toJson());
      
      _flashcards.add(flashcard);
      _organizeDeck();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding flashcard: $e');
      rethrow;
    }
  }

  /// Update flashcard
  Future<void> updateFlashcard(Flashcard flashcard) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('flashcards')
          .doc(flashcard.id)
          .update(flashcard.toJson());
      
      final index = _flashcards.indexWhere((c) => c.id == flashcard.id);
      if (index != -1) {
        _flashcards[index] = flashcard;
        _organizeDeck();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating flashcard: $e');
      rethrow;
    }
  }

  /// Delete flashcard
  Future<void> deleteFlashcard(String cardId) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('flashcards')
          .doc(cardId)
          .delete();
      
      _flashcards.removeWhere((c) => c.id == cardId);
      _organizeDeck();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting flashcard: $e');
      rethrow;
    }
  }

  /// Review flashcard with SM-2 algorithm
  /// difficulty: 0 = hard, 1 = medium, 2 = easy
  Future<void> reviewFlashcard(String cardId, CardDifficulty difficulty) async {
    debugPrint('🔄 reviewFlashcard called - cardId: $cardId, difficulty: ${difficulty.toString().split('.').last}');
    
    final card = _flashcards.firstWhere((c) => c.id == cardId);
    final updated = _calculateNextReview(card, difficulty);
    await updateFlashcard(updated);
    
    debugPrint('✅ Flashcard updated');
    
    // Award XP based on difficulty
    await _awardReviewXP(difficulty);
    
    // Update quest progress
    _gamificationService?.updateQuestProgress('spaced_repetition');
    
    // Save to study_sessions for analytics tracking
    debugPrint('📝 About to save review session...');
    await _saveReviewSession(difficulty);
    debugPrint('✅ Review session saved');
  }

  /// Award XP for reviewing a card
  Future<void> _awardReviewXP(CardDifficulty difficulty) async {
    if (_gamificationService == null) return;
    
    int xpAmount;
    String difficultyText;
    
    switch (difficulty) {
      case CardDifficulty.hard:
        xpAmount = 10;
        difficultyText = 'Hard';
        break;
      case CardDifficulty.medium:
        xpAmount = 15;
        difficultyText = 'Medium';
        break;
      case CardDifficulty.easy:
        xpAmount = 20;
        difficultyText = 'Easy';
        break;
    }
    
    await _gamificationService!.awardXP(
      xpAmount,
      source: 'Flashcard Review ($difficultyText)',
    );
  }
  
  /// Save review to study_sessions for analytics
  Future<void> _saveReviewSession(CardDifficulty difficulty) async {
    if (_currentUserId == null) return;
    
    try {
      final now = DateTime.now();
      final sessionId = _firestore.collection('users').doc().id;
      
      int productivityScore;
      switch (difficulty) {
        case CardDifficulty.easy:
          productivityScore = 100;
          break;
        case CardDifficulty.medium:
          productivityScore = 80;
          break;
        case CardDifficulty.hard:
          productivityScore = 60;
          break;
      }
      
      final studySessionData = {
        'id': sessionId,
        'userId': _currentUserId,
        'technique': 'spaced_repetition',
        'status': 'completed',
        'startTime': Timestamp.fromDate(now),
        'endTime': Timestamp.fromDate(now),
        'durationMinutes': 1,
        'topic': 'Flashcard Review',
        'pomodoroCount': 0,
        'breakCount': 0,
        'productivityScore': productivityScore.toDouble(),
        'completed': true,
        'createdAt': Timestamp.fromDate(now),
      };
      
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('study_sessions')
          .doc(sessionId)
          .set(studySessionData);
      
      debugPrint('✅✅✅ SPACED REPETITION SESSION SAVED ✅✅✅');
      debugPrint('📊 Session ID: $sessionId');
      debugPrint('📊 User ID: $_currentUserId');
      debugPrint('📊 Technique: ${studySessionData['technique']}');
      debugPrint('📊 Topic: ${studySessionData['topic']}');
      debugPrint('📊 Score: ${studySessionData['productivityScore']}');
      debugPrint('💾 Saved to: users/$_currentUserId/study_sessions/$sessionId');
    } catch (e) {
      debugPrint('❌ Error saving spaced repetition session: $e');
    }
  }

  /// SM-2 Algorithm implementation
  Flashcard _calculateNextReview(Flashcard card, CardDifficulty difficulty) {
    double newEaseFactor = card.easeFactor;
    int newRepetitions = card.repetitions;
    int newInterval = card.interval;

    // Quality of response (0-5 scale mapped from difficulty)
    // hard = 3, medium = 4, easy = 5
    final quality = difficulty == CardDifficulty.hard ? 3 :
                    difficulty == CardDifficulty.medium ? 4 : 5;

    if (quality >= 3) {
      // Correct response
      if (newRepetitions == 0) {
        newInterval = 1;
      } else if (newRepetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (newInterval * newEaseFactor).round();
      }
      newRepetitions++;
    } else {
      // Incorrect response - reset
      newRepetitions = 0;
      newInterval = 1;
    }

    // Update ease factor
    newEaseFactor = newEaseFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    
    // Ensure ease factor stays within bounds
    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }

    final nextReviewDate = DateTime.now().add(Duration(days: newInterval));

    return card.copyWith(
      easeFactor: newEaseFactor,
      interval: newInterval,
      repetitions: newRepetitions,
      nextReviewDate: nextReviewDate,
      lastReviewedAt: DateTime.now(),
      lastDifficulty: difficulty,
    );
  }

  /// Get flashcards by deck
  List<Flashcard> getFlashcardsByDeck(String deckName) {
    return _deckMap[deckName] ?? [];
  }

  /// Get due cards for deck
  List<Flashcard> getDueCardsForDeck(String deckName) {
    final deckCards = _deckMap[deckName] ?? [];
    return deckCards.where((card) => card.isDueForReview).toList();
  }

  /// Get deck statistics
  Map<String, dynamic> getDeckStats(String deckName) {
    final cards = getFlashcardsByDeck(deckName);
    final dueCards = getDueCardsForDeck(deckName);
    
    final newCards = cards.where((c) => c.repetitions == 0).length;
    final learningCards = cards.where((c) => c.repetitions > 0 && c.repetitions < 3).length;
    final masteredCards = cards.where((c) => c.repetitions >= 3).length;
    
    return {
      'totalCards': cards.length,
      'dueCards': dueCards.length,
      'newCards': newCards,
      'learningCards': learningCards,
      'masteredCards': masteredCards,
    };
  }

  /// Import flashcards from list
  Future<void> importFlashcards(String deckName, List<Map<String, String>> cardsData) async {
    for (var data in cardsData) {
      final card = Flashcard(
        id: DateTime.now().millisecondsSinceEpoch.toString() + cardsData.indexOf(data).toString(),
        userId: _currentUserId!,
        deckName: deckName,
        question: data['question']!,
        answer: data['answer']!,
        courseCode: data['courseCode'],
        createdAt: DateTime.now(),
      );
      
      await addFlashcard(card);
    }
  }

  /// Get study statistics
  Future<Map<String, dynamic>> getStudyStatistics() async {
    if (_currentUserId == null) return {};
    
    final totalCards = _flashcards.length;
    final totalDecks = _deckMap.length;
    final cardsReviewedToday = _flashcards.where((card) {
      if (card.lastReviewedAt == null) return false;
      final now = DateTime.now();
      final lastReview = card.lastReviewedAt!;
      return now.year == lastReview.year &&
          now.month == lastReview.month &&
          now.day == lastReview.day;
    }).length;
    
    final averageEaseFactor = _flashcards.isNotEmpty
        ? _flashcards.map((c) => c.easeFactor).reduce((a, b) => a + b) / _flashcards.length
        : 0.0;
    
    return {
      'totalCards': totalCards,
      'totalDecks': totalDecks,
      'dueCards': dueCards.length,
      'cardsReviewedToday': cardsReviewedToday,
      'averageEaseFactor': averageEaseFactor.toStringAsFixed(2),
    };
  }

  /// Reset card progress
  Future<void> resetCard(String cardId) async {
    final card = _flashcards.firstWhere((c) => c.id == cardId);
    final reset = card.copyWith(
      easeFactor: 2.5,
      interval: 0,
      repetitions: 0,
      nextReviewDate: DateTime.now(),
      lastReviewedAt: null,
      lastDifficulty: null,
    );
    await updateFlashcard(reset);
  }
}
