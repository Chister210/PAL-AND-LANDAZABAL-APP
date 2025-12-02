import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/pomodoro_service.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final _topicController = TextEditingController();
  final _courseCodeController = TextEditingController();

  @override
  void dispose() {
    _topicController.dispose();
    _courseCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pomodoroService = context.watch<PomodoroService>();

    return WillPopScope(
      onWillPop: () async {
        // Allow back navigation to home screen
        context.go('/');
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pomodoro Timer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => _showHelpDialog(context),
              tooltip: 'How to use',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(context, pomodoroService),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Timer Display
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getStateColor(pomodoroService.state),
                        _getStateColor(pomodoroService.state).withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getStateColor(pomodoroService.state).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Circle
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: pomodoroService.progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      // Time Text
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pomodoroService.formattedTime,
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getStateText(pomodoroService.state),
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (pomodoroService.currentPomodoros > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${pomodoroService.currentPomodoros} Pomodoro${pomodoroService.currentPomodoros > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

              // Control Buttons
              if (!pomodoroService.isActive)
                _buildStartButton(context, pomodoroService)
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (pomodoroService.state != PomodoroState.paused)
                      ElevatedButton.icon(
                        onPressed: pomodoroService.pause,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: pomodoroService.resume,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Resume'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: pomodoroService.stop,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: pomodoroService.skip,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Info Cards
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Work Time',
                      '${pomodoroService.workDuration} min',
                      Icons.work,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Short Break',
                      '${pomodoroService.shortBreakDuration} min',
                      Icons.coffee,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Long Break',
                      '${pomodoroService.longBreakDuration} min',
                      Icons.beach_access,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Tips
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Pomodoro Tips',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTip('Focus on one task during work sessions'),
                      _buildTip('Take breaks seriously - rest your mind'),
                      _buildTip('After 4 pomodoros, take a longer break'),
                      _buildTip('Remove distractions before starting'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ), // End of body
    ), // End of Scaffold
  ); // End of WillPopScope
  }

  Widget _buildStartButton(BuildContext context, PomodoroService service) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showStartDialog(context, service),
          icon: const Icon(Icons.play_arrow, size: 32),
          label: const Text('Start Pomodoro'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }

  Color _getStateColor(PomodoroState state) {
    switch (state) {
      case PomodoroState.working:
        return const Color(0xFF6C63FF);
      case PomodoroState.shortBreak:
        return const Color(0xFF4CAF50);
      case PomodoroState.longBreak:
        return const Color(0xFFFF9800);
      case PomodoroState.paused:
        return Colors.grey;
      default:
        return const Color(0xFF6C63FF);
    }
  }

  String _getStateText(PomodoroState state) {
    switch (state) {
      case PomodoroState.working:
        return 'Focus Time';
      case PomodoroState.shortBreak:
        return 'Short Break';
      case PomodoroState.longBreak:
        return 'Long Break';
      case PomodoroState.paused:
        return 'Paused';
      default:
        return 'Ready to Start';
    }
  }

  void _showStartDialog(BuildContext context, PomodoroService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Pomodoro Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _topicController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'What are you studying? (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _courseCodeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Course Code (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.startWork(
                topic: _topicController.text.isNotEmpty ? _topicController.text : null,
                courseCode: _courseCodeController.text.isNotEmpty ? _courseCodeController.text : null,
              );
              Navigator.pop(context);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'How to Use Pomodoro',
                style: TextStyle(fontSize: 18, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The Pomodoro Technique helps you focus by breaking work into intervals.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                softWrap: true,
              ),
              const SizedBox(height: 16),
              _buildHelpStep('1', 'Set Your Topic', 'Enter what you\'ll be studying (optional)'),
              _buildHelpStep('2', 'Start Timer', 'Default: 25 minutes of focused work'),
              _buildHelpStep('3', 'Work Without Distraction', 'Focus solely on your task until timer ends'),
              _buildHelpStep('4', 'Take a Break', 'Short break (5 min) after each session'),
              _buildHelpStep('5', 'Repeat', 'After 4 sessions, take a long break (15 min)'),
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
                        Text('Pro Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• Use timer settings (⚙️) to customize durations', style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text('• Eliminate all distractions before starting', style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text('• Use breaks to rest, not check social media', style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text('• Track multiple sessions for better productivity', style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text('• Earn XP for completing sessions!', style: TextStyle(color: Colors.white, fontSize: 13)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, PomodoroService service) {
    final workController = TextEditingController(text: service.workDuration.toString());
    final shortBreakController = TextEditingController(text: service.shortBreakDuration.toString());
    final longBreakController = TextEditingController(text: service.longBreakDuration.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pomodoro Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2E),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: workController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Work Duration (minutes)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shortBreakController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Short Break (minutes)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: longBreakController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Long Break (minutes)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
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
            onPressed: () {
              service.updateSettings(
                workDuration: int.tryParse(workController.text),
                shortBreakDuration: int.tryParse(shortBreakController.text),
                longBreakDuration: int.tryParse(longBreakController.text),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
