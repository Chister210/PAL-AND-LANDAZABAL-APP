import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/spaced_repetition_service.dart';
import '../../models/flashcard.dart';

class SpacedRepetitionScreen extends StatefulWidget {
  const SpacedRepetitionScreen({super.key});

  @override
  State<SpacedRepetitionScreen> createState() => _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen> with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  String? _selectedDeck;
  List<Flashcard> _currentDeck = [];
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  Future<void> _rateCard(CardDifficulty difficulty) async {
    if (_currentDeck.isEmpty) return;
    
    final service = context.read<SpacedRepetitionService>();
    final currentCard = _currentDeck[_currentCardIndex];
    
    await service.reviewFlashcard(currentCard.id, difficulty);
    
    // Show feedback
    final message = difficulty == CardDifficulty.easy
        ? 'Great! Next review in ${_getNextInterval(currentCard, difficulty)} days'
        : difficulty == CardDifficulty.medium
            ? 'Good! Keep practicing'
            : 'Try again soon!';
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: _getDifficultyColor(difficulty),
        ),
      );
    }
    
    // Move to next card
    setState(() {
      _currentDeck.removeAt(_currentCardIndex);
      if (_currentCardIndex >= _currentDeck.length && _currentDeck.isNotEmpty) {
        _currentCardIndex = 0;
      }
      _isFlipped = false;
      _flipController.reset();
    });
    
    // Reload if no more cards
    if (_currentDeck.isEmpty) {
      await service.loadFlashcards();
    }
  }

  int _getNextInterval(Flashcard card, CardDifficulty difficulty) {
    if (card.repetitions == 0) return 1;
    if (card.repetitions == 1) return 6;
    return (card.interval * card.easeFactor).round();
  }

  Color _getDifficultyColor(CardDifficulty difficulty) {
    switch (difficulty) {
      case CardDifficulty.easy:
        return Colors.green;
      case CardDifficulty.medium:
        return Colors.orange;
      case CardDifficulty.hard:
        return Colors.red;
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'How to Use Spaced Repetition',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Spaced Repetition uses flashcards to help you memorize information efficiently.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildHelpStep('1', 'Create Decks', 'Organize flashcards by topic (e.g., "Biology", "Math")'),
              _buildHelpStep('2', 'Add Flashcards', 'Tap + to create cards with question & answer'),
              _buildHelpStep('3', 'Study Cards', 'Select a deck and tap cards to flip them'),
              _buildHelpStep('4', 'Rate Difficulty', 'After each card, rate how well you knew it:'),
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Easy - Review in 5+ days', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Medium - Review in 2-3 days', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Hard - Review again today', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildHelpStep('5', 'Smart Scheduling', 'The system automatically schedules cards based on your performance'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Pro Tips:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• Study due cards daily for best results', style: TextStyle(color: Colors.white)),
                    Text('• Keep cards concise (one concept per card)', style: TextStyle(color: Colors.white)),
                    Text('• Use images or mnemonics for complex topics', style: TextStyle(color: Colors.white)),
                    Text('• Regular practice beats cramming!', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SpacedRepetitionService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Spaced Repetition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'How to use',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCardDialog(context, service),
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () => _showDeckManager(context, service),
          ),
        ],
      ),
      body: SafeArea(
        child: _selectedDeck == null
            ? _buildDeckSelection(service)
            : _buildReviewMode(service),
      ),
    );
  }

  Widget _buildDeckSelection(SpacedRepetitionService service) {
    final deckNames = service.deckNames;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Deck to Study',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a deck to review your flashcards',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          
          if (deckNames.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.builder(
                itemCount: deckNames.length,
                itemBuilder: (context, index) {
                  final deckName = deckNames[index];
                  final stats = service.getDeckStats(deckName);
                  final dueCards = stats['dueCards'] as int;
                  
                  return _buildDeckCard(deckName, stats, dueCards);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Decks Yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first deck to start learning',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddCardDialog(context, context.read<SpacedRepetitionService>()),
            icon: const Icon(Icons.add),
            label: const Text('Create Deck'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckCard(String deckName, Map<String, dynamic> stats, int dueCards) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDeck = deckName;
            _currentDeck = context.read<SpacedRepetitionService>().getDueCardsForDeck(deckName);
            _currentCardIndex = 0;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder_open,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deckName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats['totalCards']} cards',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  if (dueCards > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$dueCards due',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Up to date',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatChip('New', stats['newCards'], Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatChip('Learning', stats['learningCards'], Colors.orange),
                  const SizedBox(width: 8),
                  _buildStatChip('Mastered', stats['masteredCards'], Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReviewMode(SpacedRepetitionService service) {
    if (_currentDeck.isEmpty) {
      return _buildCompletedState();
    }

    final currentCard = _currentDeck[_currentCardIndex];
    final progress = (_currentCardIndex + 1) / _currentDeck.length;

    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          minHeight: 4,
        ),
        
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedDeck = null;
                    _currentDeck = [];
                    _currentCardIndex = 0;
                    _isFlipped = false;
                    _flipController.reset();
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDeck ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Card ${_currentCardIndex + 1} of ${_currentDeck.length}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Flashcard
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * 3.14159;
                  final isUnder = (angle > 3.14159 / 2);
                  
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isUnder
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(3.14159),
                            alignment: Alignment.center,
                            child: _buildCardFace(currentCard.answer, true),
                          )
                        : _buildCardFace(currentCard.question, false),
                  );
                },
              ),
            ),
          ),
        ),

        // Controls
        if (_isFlipped)
          _buildDifficultyButtons()
        else
          _buildFlipPrompt(),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCardFace(String text, bool isAnswer) {
    return Container(
      width: 320,
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAnswer
              ? [const Color(0xFF4CAF50), const Color(0xFF45A049)]
              : [const Color(0xFF6C63FF), const Color(0xFF5A52D5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAnswer ? Colors.green : Colors.purple).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(
                  isAnswer ? Icons.lightbulb : Icons.help_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  isAnswer ? 'Answer' : 'Question',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (!isAnswer)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, color: Colors.white70, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tap to reveal answer',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlipPrompt() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Card(
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flip, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Tap the card to see the answer',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'How well did you know this?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDifficultyButton(
                  'Hard',
                  'Study again',
                  Colors.red,
                  Icons.close,
                  CardDifficulty.hard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDifficultyButton(
                  'Medium',
                  'Good',
                  Colors.orange,
                  Icons.check,
                  CardDifficulty.medium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDifficultyButton(
                  'Easy',
                  'Mastered',
                  Colors.green,
                  Icons.done_all,
                  CardDifficulty.easy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton(
    String label,
    String subtitle,
    Color color,
    IconData icon,
    CardDifficulty difficulty,
  ) {
    return ElevatedButton(
      onPressed: () => _rateCard(difficulty),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All Done!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No more cards due in this deck',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedDeck = null;
                _currentDeck = [];
                _currentCardIndex = 0;
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Decks'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, SpacedRepetitionService service) {
    final deckController = TextEditingController();
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    final courseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Add Flashcard', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deckController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Deck Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: questionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Question',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.help_outline, color: Colors.white70),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: answerController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lightbulb_outline, color: Colors.white70),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Course Code (optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (deckController.text.isEmpty ||
                  questionController.text.isEmpty ||
                  answerController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              final card = Flashcard(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current_user', // Will be replaced with actual user ID
                deckName: deckController.text,
                question: questionController.text,
                answer: answerController.text,
                courseCode: courseController.text.isNotEmpty ? courseController.text : null,
                createdAt: DateTime.now(),
              );

              await service.addFlashcard(card);
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flashcard added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeckManager(BuildContext context, SpacedRepetitionService service) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: service.getStudyStatistics(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {};
            
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Study Statistics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStatRow('Total Cards', stats['totalCards']?.toString() ?? '0'),
                  _buildStatRow('Total Decks', stats['totalDecks']?.toString() ?? '0'),
                  _buildStatRow('Cards Due', stats['dueCards']?.toString() ?? '0'),
                  _buildStatRow('Reviewed Today', stats['cardsReviewedToday']?.toString() ?? '0'),
                  _buildStatRow('Avg Ease Factor', stats['averageEaseFactor']?.toString() ?? '2.5'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
