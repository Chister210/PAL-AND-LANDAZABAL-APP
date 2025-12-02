import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/active_recall.dart';
import '../services/active_recall_service.dart';

/// Active Recall Screen - Practice questions with answer validation
class ActiveRecallScreen extends StatefulWidget {
  const ActiveRecallScreen({Key? key}) : super(key: key);

  @override
  State<ActiveRecallScreen> createState() => _ActiveRecallScreenState();
}

class _ActiveRecallScreenState extends State<ActiveRecallScreen> {
  @override
  void initState() {
    super.initState();
    // Service will be initialized with user in main app
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
                'How to Use Active Recall',
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
                'Active Recall tests your ability to retrieve information from memory.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildHelpStep('1', 'Add Questions', 'Build your question bank with study topics'),
              _buildHelpStep('2', 'Multiple Question Types', 'You can add:'),
              const Padding(
                padding: EdgeInsets.only(left: 32, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Short answer questions', style: TextStyle(color: Colors.white)),
                    Text('• Essay questions', style: TextStyle(color: Colors.white)),
                    Text('• Concept explanations', style: TextStyle(color: Colors.white)),
                    Text('• Problem-solving questions', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildHelpStep('3', 'Start Session', 'Practice 10 random questions from your bank'),
              _buildHelpStep('4', 'Answer Questions', 'Type your answer without looking at the correct answer'),
              _buildHelpStep('5', 'Review & Compare', 'After answering, compare with the correct answer'),
              _buildHelpStep('6', 'Track Progress', 'View accuracy scores and improvement over time'),
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
                    Text('• Add keywords to help with answer validation', style: TextStyle(color: Colors.white)),
                    Text('• Use your own words when answering', style: TextStyle(color: Colors.white)),
                    Text('• Focus on understanding, not memorization', style: TextStyle(color: Colors.white)),
                    Text('• Review wrong answers to learn from mistakes', style: TextStyle(color: Colors.white)),
                    Text('• Practice regularly for better retention', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.quiz, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Adding Multiple Questions:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('1. Tap "Add New Question" button'),
                    Text('2. Enter your question and correct answer'),
                    Text('3. Optionally add keywords for better scoring'),
                    Text('4. Tap "Add Question" to save'),
                    Text('5. Repeat for each new question'),
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
                if (description.isNotEmpty)
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Active Recall'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'How to use',
          ),
          IconButton(
            icon: const Icon(Icons.library_books),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuestionBankScreen()),
              );
            },
            tooltip: 'Question Bank',
          ),
        ],
      ),
      body: Consumer<ActiveRecallService>(
        builder: (context, service, _) {
          if (service.hasActiveSession) {
            return const _SessionView();
          } else {
            return const _HomeView();
          }
        },
      ),
    );
  }
}

/// Home View - Start session or manage questions
class _HomeView extends StatelessWidget {
  const _HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveRecallService>(
      builder: (context, service, _) {
        final stats = service.getStatistics();
        final questionCount = stats['totalQuestions'] as int;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Statistics Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Question Bank',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: 'Questions',
                            value: questionCount.toString(),
                            icon: Icons.quiz,
                          ),
                          _StatItem(
                            label: 'Avg Accuracy',
                            value: '${(stats['averageAccuracy'] * 100).toStringAsFixed(0)}%',
                            icon: Icons.trending_up,
                          ),
                          _StatItem(
                            label: 'Attempts',
                            value: stats['totalAttempts'].toString(),
                            icon: Icons.history,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Start Session Button
              if (questionCount > 0)
                ElevatedButton.icon(
                  onPressed: () async {
                    final started = await service.startSession(questionCount: 10);
                    if (!started && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to start session. Please try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Practice Session'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                  ),
                )
              else
                const Text(
                  'Add questions to your bank to start practicing!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              
              const SizedBox(height: 16),

              // Add Question Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddQuestionScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Question'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                ),
              ),

              const SizedBox(height: 24),

              // Recent Sessions
              Text(
                'Recent Sessions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              const _RecentSessionsList(),
            ],
          ),
        );
      },
    );
  }
}

/// Stat Item Widget
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

/// Recent Sessions List
class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveRecallService>(
      builder: (context, service, _) {
        return FutureBuilder<List<RecallSession>>(
          future: service.getRecentSessions(limit: 5),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No sessions yet', style: TextStyle(color: Colors.white70)),
                ),
              );
            }

            return Column(
              children: snapshot.data!.map((session) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: Text(
                        '${(session.accuracy * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    title: Text('${session.questionIds.length} questions', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      session.startedAt.toString().split('.')[0],
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '+${session.xpEarned}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

/// Session View - Active practice session
class _SessionView extends StatefulWidget {
  const _SessionView({Key? key}) : super(key: key);

  @override
  State<_SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<_SessionView> {
  final TextEditingController _answerController = TextEditingController();
  RecallAttempt? _lastAttempt;
  bool _showingFeedback = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer(ActiveRecallService service) async {
    if (_isSubmitting) {
      debugPrint('⏸️ Already submitting, ignoring duplicate request');
      return; // Prevent double submit
    }
    
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    debugPrint('🔄 UI: Set _isSubmitting = true');

    try {
      debugPrint('📝 UI: Calling service.submitAnswer()...');
      
      final attempt = await service.submitAnswer(_answerController.text.trim());
      
      debugPrint('📝 UI: Received attempt: ${attempt != null ? "accuracy=${attempt.accuracy}" : "NULL"} ');
      
      if (!mounted) {
        debugPrint('⚠️ UI: Widget unmounted, aborting');
        setState(() => _isSubmitting = false);
        return;
      }
      
      if (attempt == null) {
        debugPrint('❌ UI: Attempt is NULL - showing error');
        // Session already complete or no active session or timeout
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit answer. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      debugPrint('✅ UI: Setting state - _lastAttempt, _showingFeedback=true, _isSubmitting=false');
      setState(() {
        _lastAttempt = attempt;
        _showingFeedback = true;
        _isSubmitting = false;
      });
      debugPrint('✅ UI: State updated - _showingFeedback=$_showingFeedback');
      
      // Clear the answer field
      _answerController.clear();
    } catch (e, stackTrace) {
      debugPrint('❌ Error submitting answer: $e');
      debugPrint('Stack: $stackTrace');
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _nextQuestion(ActiveRecallService service) async {
    _answerController.clear();
    setState(() {
      _showingFeedback = false;
      _lastAttempt = null;
    });

    // Check if session complete
    if (service.isSessionComplete()) {
      debugPrint('✅ Session complete - auto-ending session for analytics');
      await service.endSession();
      if (mounted) {
        await _showSessionSummary(service);
      }
    }
  }

  Future<void> _showSessionSummary(ActiveRecallService service) async {
    final session = service.currentSession!;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Session Complete! 🎉', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryItem(
              label: 'Questions',
              value: session.attempts.length.toString(),
              icon: Icons.quiz,
            ),
            const SizedBox(height: 12),
            _SummaryItem(
              label: 'Accuracy',
              value: '${(session.accuracy * 100).toStringAsFixed(0)}%',
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 12),
            _SummaryItem(
              label: 'XP Earned',
              value: '+${session.xpEarned}',
              icon: Icons.bolt,
              color: Colors.blue,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              service.endSession();
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveRecallService>(
      builder: (context, service, _) {
        debugPrint('🔍 SessionView build - hasActiveSession: ${service.hasActiveSession}');
        
        final question = service.getCurrentQuestion();
        final progress = service.getSessionProgress();

        debugPrint('🔍 getCurrentQuestion result: ${question != null ? "Question found" : "NULL"}');

        if (question == null) {
          // Session exists but no current question - session complete or error
          debugPrint('⚠️ No current question - checking if session complete');
          if (service.isSessionComplete()) {
            debugPrint('✅ Session is complete');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSessionSummary(service);
            });
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  service.isSessionComplete() 
                    ? 'Loading session summary...' 
                    : 'Loading next question...',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress Text
                    Text(
                      'Question ${service.currentSession!.attempts.length + 1} of ${service.currentSession!.questionIds.length}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 24),

                    if (!_showingFeedback) ...[
                      // Question Card
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.help_outline, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Question',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                question.question,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Answer Input
                      TextField(
                        controller: _answerController,
                        maxLines: 5,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Your Answer',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'Type your answer here...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitAnswer(service),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Submit Answer'),
                      ),
                    ] else ...[
                      // Feedback Card
                      _FeedbackCard(
                        attempt: _lastAttempt!,
                        correctAnswer: question.correctAnswer,
                      ),
                      const SizedBox(height: 24),

                      // Next Button
                      ElevatedButton(
                        onPressed: () => _nextQuestion(service),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(
                          service.isSessionComplete() ? 'Finish Session' : 'Next Question',
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Cancel Button
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E2E),
                            title: const Text('Cancel Session?', style: TextStyle(color: Colors.white)),
                            content: const Text('Your progress will not be saved.', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Continue'),
                              ),
                              TextButton(
                                onPressed: () {
                                  service.cancelSession();
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel Session'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Cancel Session'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Feedback Card
class _FeedbackCard extends StatelessWidget {
  final RecallAttempt attempt;
  final String correctAnswer;

  const _FeedbackCard({
    Key? key,
    required this.attempt,
    required this.correctAnswer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCorrect = attempt.isCorrect;
    final isPartial = attempt.isPartiallyCorrect;
    
    Color getColor() {
      if (isCorrect) return Colors.green;
      if (isPartial) return Colors.orange;
      return Colors.red;
    }

    String getTitle() {
      if (isCorrect) return '✓ Correct!';
      if (isPartial) return '~ Partially Correct';
      return '✗ Incorrect';
    }

    return Card(
      color: getColor().withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : (isPartial ? Icons.radio_button_checked : Icons.cancel),
                  color: getColor(),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTitle(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: getColor(),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${(attempt.accuracy * 100).toStringAsFixed(0)}% match',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        '+${attempt.xpEarned} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Your Answer
            Text(
              'Your Answer:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              width: double.infinity,
              child: Text(attempt.userAnswer, style: const TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 16),
            
            // Correct Answer
            Text(
              'Correct Answer:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              width: double.infinity,
              child: Text(
                correctAnswer,
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Summary Item Widget
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _SummaryItem({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? Colors.white,
              ),
        ),
      ],
    );
  }
}

/// Add Question Screen
class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({Key? key}) : super(key: key);

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _topicController = TextEditingController();
  int _difficulty = 3;
  bool _isSaving = false;

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isSaving) return; // Prevent double tap
    
    setState(() => _isSaving = true);

    try {
      final service = context.read<ActiveRecallService>();
      
      // Add 5 second timeout
      final success = await service.addQuestion(
        question: _questionController.text.trim(),
        correctAnswer: _answerController.text.trim(),
        topic: _topicController.text.trim().isEmpty ? null : _topicController.text.trim(),
        difficulty: _difficulty,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ Add question timeout');
          return false;
        },
      );

      if (!mounted) return;
      
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Question added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to add question. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving question: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Question')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _questionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Question',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'What do you want to remember?',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a question';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _answerController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Correct Answer',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'The answer you should remember',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an answer';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _topicController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Topic (Optional)',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'e.g., Math, History',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Difficulty: $_difficulty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            Slider(
              value: _difficulty.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _difficulty.toString(),
              onChanged: (value) {
                setState(() {
                  _difficulty = value.toInt();
                });
              },
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isSaving ? null : _saveQuestion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Question'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Question Bank Screen
class QuestionBankScreen extends StatelessWidget {
  const QuestionBankScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Question Bank'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddQuestionScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ActiveRecallService>(
        builder: (context, service, _) {
          final questions = service.questionBank;
          
          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text('No questions yet', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddQuestionScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Question'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    question.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        question.correctAnswer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (question.topic != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                question.topic!,
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            'Asked ${question.timesAsked}x',
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                          const SizedBox(width: 8),
                          if (question.averageAccuracy > 0)
                            Text(
                              '${(question.averageAccuracy * 100).toInt()}% avg',
                              style: const TextStyle(fontSize: 10, color: Colors.green),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E2E),
                          title: const Text('Delete Question?', style: TextStyle(color: Colors.white)),
                          content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                service.deleteQuestion(question.id);
                                Navigator.pop(context);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
