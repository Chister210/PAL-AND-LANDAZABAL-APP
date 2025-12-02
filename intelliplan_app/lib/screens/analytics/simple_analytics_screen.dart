import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../services/auth_service.dart';

class SimpleAnalyticsScreen extends StatefulWidget {
  const SimpleAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<SimpleAnalyticsScreen> createState() => _SimpleAnalyticsScreenState();
}

class _SimpleAnalyticsScreenState extends State<SimpleAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<QuerySnapshot>? _sessionSubscription;
  StreamSubscription<QuerySnapshot>? _recallSubscription;
  StreamSubscription<QuerySnapshot>? _spacedRepSubscription;
  
  // Simple data holders
  int _totalSessions = 0;
  int _totalMinutes = 0;
  int _todaySessions = 0;
  int _todayMinutes = 0;
  int _pomodoroCount = 0;
  int _activeRecallCount = 0;
  int _spacedRepCount = 0;
  Map<String, int> _dailyMinutes = {};
  Map<String, int> _hourlyProductivity = {}; // Track productivity by hour
  List<Map<String, dynamic>> _recommendations = [];
  
  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }
  
  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _recallSubscription?.cancel();
    _spacedRepSubscription?.cancel();
    super.dispose();
  }
  
  void _setupRealtimeListener() async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.id;
      
      if (userId == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }
      
      debugPrint('📡 Setting up analytics listeners for user: $userId');
      
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Cancel existing subscriptions
      await _sessionSubscription?.cancel();
      await _recallSubscription?.cancel();
      await _spacedRepSubscription?.cancel();
      
      // Listen to study_sessions
      _sessionSubscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('study_sessions')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .snapshots()
          .listen((snapshot) {
            debugPrint('🔄 Study sessions update: ${snapshot.docs.length}');
            if (mounted) _processAllData();
          }, onError: (error) {
            debugPrint('❌ Study sessions error: $error');
          });
      
      // Listen to recall_sessions (Active Recall)
      _recallSubscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('recall_sessions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .snapshots()
          .listen((snapshot) {
            debugPrint('🔄 Active Recall sessions update: ${snapshot.docs.length}');
            if (mounted) _processAllData();
          }, onError: (error) {
            debugPrint('❌ Recall sessions error: $error');
          });
      
      // Listen to flashcard reviews (Spaced Repetition)
      _spacedRepSubscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcard_reviews')
          .where('reviewedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .snapshots()
          .listen((snapshot) {
            debugPrint('🔄 Spaced Repetition reviews update: ${snapshot.docs.length}');
            if (mounted) _processAllData();
          }, onError: (error) {
            debugPrint('❌ Spaced repetition error: $error');
          });
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error setting up listeners: $e');
      debugPrint('Stack: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _processAllData() async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.id;
      if (userId == null) return;
      
      debugPrint('📊 Processing all analytics data...');
      
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Fetch all data
      final studySessionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('study_sessions')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      final recallSessionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recall_sessions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      final flashcardReviewsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcard_reviews')
          .where('reviewedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      // Combine and process
      final allDocs = [
        ...studySessionsSnapshot.docs,
        ...recallSessionsSnapshot.docs.map((doc) {
          final data = doc.data();
          // Convert recall session to study session format
          final attempts = data['attempts'] as List? ?? [];
          final estimatedMinutes = (attempts.length * 2).clamp(5, 60); // ~2 min per question
          return {
            ...data,
            'id': doc.id,
            'technique': 'activeRecall',
            'durationMinutes': estimatedMinutes,
            'startTime': data['createdAt'],
          };
        }),
        ...flashcardReviewsSnapshot.docs.map((doc) {
          final data = doc.data();
          // Each review ~1 minute
          return {
            ...data,
            'id': doc.id,
            'technique': 'spacedRepetition',
            'durationMinutes': 1,
            'startTime': data['reviewedAt'],
          };
        }),
      ];
      
      debugPrint('📊 Total combined data points: ${allDocs.length}');
      
      _processSessionData(allDocs);
      
    } catch (e) {
      debugPrint('❌ Error processing all data: $e');
    }
  }
  
  void _processSessionData(List<dynamic> docs) {
    debugPrint('📊 Processing ${docs.length} sessions...');
    
    // Reset all counters
    _totalSessions = 0;
    _totalMinutes = 0;
    _todaySessions = 0;
    _todayMinutes = 0;
    _pomodoroCount = 0;
    _activeRecallCount = 0;
    _spacedRepCount = 0;
    _dailyMinutes = {};
    _hourlyProductivity = {};
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Process each session
    for (var doc in docs) {
      try {
        // Handle both DocumentSnapshot and Map types
        Map<String, dynamic> data;
        if (doc is QueryDocumentSnapshot) {
          data = doc.data() as Map<String, dynamic>;
        } else if (doc is Map) {
          data = Map<String, dynamic>.from(doc);
        } else {
          continue;
        }
        
        // Get duration
        final duration = data['durationMinutes'] as int? ?? 0;
        if (duration <= 0) continue;
        
        // Get technique
        final technique = data['technique'] as String? ?? 'unknown';
        
        // Count it
        _totalSessions++;
        _totalMinutes += duration;
        
        // Count by technique
        if (technique == 'pomodoro' || technique == 'Pomodoro') {
          _pomodoroCount++;
        } else if (technique == 'activeRecall' || technique == 'active_recall') {
          _activeRecallCount++;
        } else if (technique == 'spacedRepetition' || technique == 'spaced_repetition') {
          _spacedRepCount++;
        }
        
        // Get date for daily chart and today's stats
        final startTime = (data['startTime'] as Timestamp?)?.toDate();
        if (startTime != null) {
          // Check if today
          final sessionDate = DateTime(startTime.year, startTime.month, startTime.day);
          if (sessionDate.isAtSameMomentAs(today)) {
            _todaySessions++;
            _todayMinutes += duration;
          }
          
          final dateKey = '${startTime.month}/${startTime.day}';
          _dailyMinutes[dateKey] = (_dailyMinutes[dateKey] ?? 0) + duration;
          
          // Track productivity by hour
          final hourKey = '${startTime.hour}:00';
          _hourlyProductivity[hourKey] = (_hourlyProductivity[hourKey] ?? 0) + duration;
        }
        
      } catch (e) {
        debugPrint('⚠️ Error processing session: $e');
      }
    }
    
    debugPrint('✅ Processed: $_totalSessions sessions, $_totalMinutes minutes, today: $_todaySessions');
    
    // Generate recommendations
    _generateRecommendations();
    
    setState(() {
      _isLoading = false;
      _error = null;
    });
  }
  
  void _generateRecommendations() {
    _recommendations.clear();
    
    if (_totalSessions < 3) {
      // Not enough data yet
      _recommendations.add({
        'icon': Icons.info_outline,
        'color': const Color(0xFF3B82F6),
        'title': 'Building Your Profile',
        'description': 'Complete more study sessions to get personalized recommendations',
      });
      return;
    }
    
    // Find most productive hour
    if (_hourlyProductivity.isNotEmpty) {
      final bestHour = _hourlyProductivity.entries.reduce((a, b) => 
        a.value > b.value ? a : b
      );
      
      final hour = int.parse(bestHour.key.split(':')[0]);
      String timeOfDay;
      String emoji;
      
      if (hour >= 6 && hour < 12) {
        timeOfDay = 'morning';
        emoji = '☀️';
      } else if (hour >= 12 && hour < 17) {
        timeOfDay = 'afternoon';
        emoji = '🌤️';
      } else if (hour >= 17 && hour < 21) {
        timeOfDay = 'evening';
        emoji = '🌆';
      } else {
        timeOfDay = 'night';
        emoji = '🌙';
      }
      
      _recommendations.add({
        'icon': Icons.wb_sunny,
        'color': const Color(0xFFF59E0B),
        'title': '$emoji Your Peak Time: ${bestHour.key}',
        'description': 'You\'re most productive in the $timeOfDay. Schedule important tasks around ${bestHour.key}.',
      });
    }
    
    // Check study consistency
    final daysWithSessions = _dailyMinutes.length;
    if (daysWithSessions < 3) {
      _recommendations.add({
        'icon': Icons.calendar_today,
        'color': const Color(0xFFEF4444),
        'title': 'Build Consistency',
        'description': 'Try to study at least 4-5 days per week for better retention',
      });
    } else if (daysWithSessions >= 5) {
      _recommendations.add({
        'icon': Icons.emoji_events,
        'color': const Color(0xFF10B981),
        'title': 'Great Consistency! 🎉',
        'description': 'You\'re studying $daysWithSessions days - keep up the excellent habit!',
      });
    }
    
    // Average session length recommendation
    if (_totalSessions > 0) {
      final avgMinutes = _totalMinutes ~/ _totalSessions;
      
      if (avgMinutes < 15) {
        _recommendations.add({
          'icon': Icons.timer,
          'color': const Color(0xFFEF4444),
          'title': 'Extend Your Sessions',
          'description': 'Your average session is ${avgMinutes}min. Try 25-30 minute Pomodoro sessions for deeper focus.',
        });
      } else if (avgMinutes > 60) {
        _recommendations.add({
          'icon': Icons.battery_alert,
          'color': const Color(0xFFF59E0B),
          'title': 'Take More Breaks',
          'description': 'Sessions average ${avgMinutes}min. Break them up with 5-10 min breaks to stay fresh.',
        });
      } else {
        _recommendations.add({
          'icon': Icons.check_circle,
          'color': const Color(0xFF10B981),
          'title': 'Perfect Session Length ✓',
          'description': '${avgMinutes}min sessions are ideal for maintaining focus and retention.',
        });
      }
    }
    
    // Technique diversity recommendation
    final techniqueCount = (_pomodoroCount > 0 ? 1 : 0) + 
                           (_activeRecallCount > 0 ? 1 : 0) + 
                           (_spacedRepCount > 0 ? 1 : 0);
    
    if (techniqueCount == 1) {
      if (_pomodoroCount > 0) {
        _recommendations.add({
          'icon': Icons.psychology,
          'color': const Color(0xFF8B5CF6),
          'title': 'Try Active Recall',
          'description': 'Test yourself regularly - it\'s proven to improve long-term retention by 50%+',
        });
      } else if (_activeRecallCount > 0) {
        _recommendations.add({
          'icon': Icons.timelapse,
          'color': const Color(0xFF8B5CF6),
          'title': 'Add Pomodoro Sessions',
          'description': 'Use Pomodoro for focused work on new material - 25 min work, 5 min break',
        });
      }
    } else if (techniqueCount >= 2) {
      _recommendations.add({
        'icon': Icons.auto_awesome,
        'color': const Color(0xFF8B5CF6),
        'title': 'Great Technique Mix! ⚡',
        'description': 'You\'re using multiple study methods - this maximizes learning effectiveness.',
      });
    }
    
    // Tomorrow's optimal study time
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    if (_hourlyProductivity.isNotEmpty) {
      final bestHour = _hourlyProductivity.entries.reduce((a, b) => 
        a.value > b.value ? a : b
      );
      final hour = int.parse(bestHour.key.split(':')[0]);
      
      _recommendations.add({
        'icon': Icons.event_available,
        'color': const Color(0xFF06B6D4),
        'title': '📅 Tomorrow\'s Plan',
        'description': 'Schedule your toughest task for ${tomorrow.month}/${tomorrow.day} at ${bestHour.key} - your peak performance window.',
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _totalSessions == 0
                  ? _buildEmptyState()
                  : _buildContent(),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error loading analytics'),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _setupRealtimeListener();
            },
            child: const Text('Retry'),
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
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Study Data Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete study sessions to see your analytics',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          if (_recommendations.isNotEmpty) ...[
            _buildRecommendations(),
            const SizedBox(height: 24),
          ],
          _buildTechniqueBreakdown(),
          const SizedBox(height: 24),
          _buildDailyChart(),
        ],
      ),
    );
  }
  
  Widget _buildStatsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Sessions',
                _totalSessions.toString(),
                Icons.event_note,
                const Color(0xFF667EEA),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Time',
                '${_totalMinutes} min',
                Icons.timer,
                const Color(0xFF764BA2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Today',
                '$_todaySessions sessions',
                Icons.today,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Today\'s Time',
                '$_todayMinutes min',
                Icons.access_time,
                const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Recommendations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (rec['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      rec['icon'] as IconData,
                      color: rec['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec['description'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
  
  Widget _buildTechniqueBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Techniques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 20),
          _buildTechniqueRow(
            'Pomodoro',
            _pomodoroCount,
            const Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          _buildTechniqueRow(
            'Active Recall',
            _activeRecallCount,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildTechniqueRow(
            'Spaced Repetition',
            _spacedRepCount,
            const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTechniqueRow(String name, int count, Color color) {
    final percentage = _totalSessions > 0 ? (count / _totalSessions * 100) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            Text(
              '$count sessions (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _totalSessions > 0 ? count / _totalSessions : 0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDailyChart() {
    if (_dailyMinutes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No study data yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    // Get last 7 days
    final now = DateTime.now();
    final chartData = <FlSpot>[];
    final dateLabels = <String>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';
      final minutes = _dailyMinutes[dateKey]?.toDouble() ?? 0.0;
      chartData.add(FlSpot((6 - i).toDouble(), minutes));
      
      if (i == 0) {
        dateLabels.add('Today');
      } else if (i == 1) {
        dateLabels.add('Yesterday');
      } else {
        dateLabels.add('${i}d ago');
      }
    }
    
    final maxY = chartData.fold<double>(0, (max, spot) => spot.y > max ? spot.y : max);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 Days Study Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dateLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dateLabels[index],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY > 0 ? maxY * 1.2 : 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: const Color(0xFF667EEA),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF667EEA),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667EEA).withOpacity(0.3),
                          const Color(0xFF667EEA).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
