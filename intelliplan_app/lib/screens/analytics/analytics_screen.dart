import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../services/analytics_service.dart';
import '../../models/study_session.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    
    // Load analytics data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final analyticsService = context.read<AnalyticsService>();
      
      debugPrint('🔄 Analytics Screen: Refreshing analytics data');
      debugPrint('📊 Current sessions: ${analyticsService.totalSessions}');
      
      // Don't re-initialize! Just refresh the data if needed
      // The service already has real-time listeners set up
      // Just trigger a rebuild by calling setState
      
    } catch (e) {
      debugPrint('❌ Error refreshing analytics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final analyticsService = context.watch<AnalyticsService>();
    
    // Debug logging
    debugPrint('🎨 Analytics UI: totalSessions=${analyticsService.totalSessions}, '
        'totalMinutes=${analyticsService.totalMinutes}, '
        'recommendations=${analyticsService.recommendations.length}, '
        'isLoading=$_isLoading');
    
    // Check if there's any data at all
    final hasData = analyticsService.totalSessions > 0 ||
                    analyticsService.recommendations.isNotEmpty ||
                    analyticsService.deadlinePressures.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () => _showHelpDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing analytics...')),
              );
              await _loadAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics refreshed!')),
                );
              }
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !hasData
                ? _buildEmptyState()
                : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSmartTips(analyticsService),
                  const SizedBox(height: 16),
                  _buildOverviewCards(analyticsService),
                  const SizedBox(height: 24),
                  _buildDeadlinePressure(analyticsService),
                  const SizedBox(height: 24),
                  _buildOptimalTimeSlots(analyticsService),
                  const SizedBox(height: 24),
                  _buildProductivityChart(analyticsService),
                  const SizedBox(height: 24),
                  _buildRecommendationsSection(analyticsService),
                  const SizedBox(height: 24),
                  _buildProductivityPatterns(analyticsService),
                  const SizedBox(height: 24),
                  _buildStudyTechniquesBreakdown(analyticsService),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No Analytics Data Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start studying to see your productivity insights!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildEmptyStateTip('🍅', 'Start a Pomodoro session', 'Track your focus time'),
                    const SizedBox(height: 12),
                    _buildEmptyStateTip('📝', 'Add study tasks', 'Organize your assignments'),
                    const SizedBox(height: 12),
                    _buildEmptyStateTip('📊', 'Complete study sessions', 'Build your analytics'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/pomodoro'),
              icon: const Icon(Icons.timer),
              label: const Text('Start Pomodoro'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateTip(String emoji, String title, String subtitle) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards(AnalyticsService service) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Sessions',
            '${service.totalSessions}',
            Icons.event_note,
            Colors.blue,
            '${service.todaySessions} today',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Study Time',
            '${service.totalMinutes ~/ 60}h',
            Icons.timer,
            Colors.purple,
            '${service.totalMinutes % 60}m extra',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityChart(AnalyticsService service) {
    final chartData = service.weeklyProductivityData;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Productivity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Last 7 days activity',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: chartData.isEmpty
                  ? const Center(child: Text('No data available'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: () {
                          try {
                            final maxVal = chartData.values.reduce((a, b) => a > b ? a : b);
                            return maxVal > 0 ? (maxVal * 1.2).ceilToDouble() : 100.0;
                          } catch (e) {
                            return 100.0;
                          }
                        }(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final day = chartData.keys.elementAt(group.x.toInt());
                              return BarTooltipItem(
                                '$day\n${rod.toY.toInt()} min',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                                  final day = chartData.keys.elementAt(value.toInt());
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      day.substring(0, 3),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}m',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 30,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(chartData.length, (index) {
                          try {
                            final minutes = chartData.values.elementAt(index);
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: minutes.toDouble().clamp(0.0, double.infinity),
                                  gradient: const LinearGradient(
                                    colors: [Colors.blue, Colors.purple],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          } catch (e) {
                            // Return empty bar on error
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: 0,
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }
                        }),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(AnalyticsService service) {
    final recommendations = service.recommendations;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lightbulb, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Recommendations',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Personalized study suggestions',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recommendations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.trending_up, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Complete more study sessions to get personalized recommendations',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recommendations.map((rec) => _buildRecommendationCard(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(StudyRecommendation recommendation) {
    final confidenceColor = recommendation.confidence >= 0.7
        ? Colors.green
        : recommendation.confidence >= 0.5
            ? Colors.orange
            : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommendation.type == RecommendationType.optimal
            ? Colors.green.withOpacity(0.1)
            : recommendation.type == RecommendationType.avoid
                ? Colors.red.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommendation.type == RecommendationType.optimal
              ? Colors.green.withOpacity(0.3)
              : recommendation.type == RecommendationType.avoid
                  ? Colors.red.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                recommendation.type == RecommendationType.optimal
                    ? Icons.star
                    : recommendation.type == RecommendationType.avoid
                        ? Icons.warning
                        : Icons.info,
                color: recommendation.type == RecommendationType.optimal
                    ? Colors.green
                    : recommendation.type == RecommendationType.avoid
                        ? Colors.red
                        : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(recommendation.confidence * 100).toInt()}%',
                  style: TextStyle(
                    color: confidenceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityPatterns(AnalyticsService service) {
    final patterns = service.productivityPatterns;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.cyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.insights, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productivity Patterns',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('When you study best'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (patterns.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Complete more sessions to discover your patterns',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...patterns.entries.map((entry) => _buildPatternRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternRow(String timeOfDay, ProductivityPattern pattern) {
    final color = _getTimeColor(timeOfDay);
    final maxScore = 10.0;
    final percentage = (pattern.averageScore / maxScore).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Icon(_getTimeIcon(timeOfDay), color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeOfDay(timeOfDay),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    '${pattern.sessionCount} sessions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pattern.averageScore.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTechniquesBreakdown(AnalyticsService service) {
    final techniques = _getTechniqueStats(service);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.pink, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Techniques',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('Your learning methods'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (techniques.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Start using study techniques to see breakdown',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...techniques.entries.map((entry) => _buildTechniqueRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getTechniqueStats(AnalyticsService service) {
    final sessions = service.recentSessions;
    final stats = <String, int>{
      'Pomodoro': 0,
      'Spaced Repetition': 0,
      'Active Recall': 0,
    };
    
    debugPrint('📊 Technique Stats Debug: Total sessions: ${sessions.length}');
    
    for (var session in sessions) {
      debugPrint('📊 Session technique: ${session.technique} (${session.technique.toString()})');
      switch (session.technique) {
        case StudyTechnique.pomodoro:
          stats['Pomodoro'] = (stats['Pomodoro'] ?? 0) + 1;
          break;
        case StudyTechnique.spacedRepetition:
          stats['Spaced Repetition'] = (stats['Spaced Repetition'] ?? 0) + 1;
          debugPrint('✅ Counted Spaced Repetition session');
          break;
        case StudyTechnique.activeRecall:
          stats['Active Recall'] = (stats['Active Recall'] ?? 0) + 1;
          debugPrint('✅ Counted Active Recall session');
          break;
        default:
          debugPrint('⚠️ Unknown technique: ${session.technique}');
          break;
      }
    }
    
    debugPrint('📊 Final technique stats: $stats');
    
    // Remove entries with 0 count so only used techniques show
    stats.removeWhere((key, value) => value == 0);
    
    return stats;
  }

  Widget _buildTechniqueRow(String technique, int count) {
    final color = _getTechniqueColor(technique);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getTechniqueIcon(technique), color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  technique,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count sessions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimeColor(String timeOfDay) {
    switch (timeOfDay.toLowerCase()) {
      case 'morning':
        return Colors.orange;
      case 'afternoon':
        return Colors.blue;
      case 'evening':
        return Colors.purple;
      case 'night':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getTimeIcon(String timeOfDay) {
    switch (timeOfDay.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.wb_cloudy;
      case 'evening':
        return Icons.brightness_3;
      case 'night':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  String _formatTimeOfDay(String timeOfDay) {
    return timeOfDay[0].toUpperCase() + timeOfDay.substring(1);
  }

  Color _getTechniqueColor(String technique) {
    switch (technique) {
      case 'Pomodoro':
        return Colors.red;
      case 'Spaced Repetition':
        return Colors.green;
      case 'Active Recall':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTechniqueIcon(String technique) {
    switch (technique) {
      case 'Pomodoro':
        return Icons.timer;
      case 'Spaced Repetition':
        return Icons.layers;
      case 'Active Recall':
        return Icons.psychology;
      default:
        return Icons.book;
    }
  }

  // ==================== PRESCRIPTIVE ANALYTICS WIDGETS ====================

  Widget _buildSmartTips(AnalyticsService service) {
    final tips = service.getSmartStudyTips();
    
    if (tips.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Smart Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: Colors.blue.shade700, fontSize: 16)),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlinePressure(AnalyticsService service) {
    final deadlines = service.deadlinePressures;
    
    if (deadlines.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deadline Pressure',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Upcoming assignments requiring attention',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...deadlines.take(5).map((deadline) => _buildDeadlinePressureCard(deadline)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlinePressureCard(DeadlinePressure deadline) {
    Color urgencyColor;
    IconData urgencyIcon;
    
    switch (deadline.urgencyLevel) {
      case 'critical':
        urgencyColor = Colors.red;
        urgencyIcon = Icons.error;
        break;
      case 'high':
        urgencyColor = Colors.orange;
        urgencyIcon = Icons.warning;
        break;
      case 'medium':
        urgencyColor = Colors.yellow.shade700;
        urgencyIcon = Icons.info;
        break;
      default:
        urgencyColor = Colors.blue;
        urgencyIcon = Icons.schedule;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: urgencyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: urgencyColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(urgencyIcon, color: urgencyColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  deadline.assignment.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  deadline.urgencyLevel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deadline.assignment.courseCode,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                deadline.daysRemaining == 0
                    ? 'Due TODAY'
                    : deadline.daysRemaining == 1
                        ? 'Due TOMORROW'
                        : 'Due in ${deadline.daysRemaining} days',
                style: TextStyle(
                  color: deadline.daysRemaining <= 1 ? urgencyColor : Colors.grey[700],
                  fontWeight: deadline.daysRemaining <= 1 ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${deadline.hoursNeeded}h needed',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 1 - deadline.riskScore,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(urgencyColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Text(
            'Risk: ${(deadline.riskScore * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimalTimeSlots(AnalyticsService service) {
    final slots = service.optimalTimeSlots.take(6).toList();
    
    if (slots.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.teal],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.schedule, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optimal Study Times',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Best times based on your productivity',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...slots.map((slot) => _buildTimeSlotCard(slot)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(OptimalTimeSlot slot) {
    final isPast = slot.date.isBefore(DateTime.now());
    final isToday = slot.date.day == DateTime.now().day &&
                    slot.date.month == DateTime.now().month &&
                    slot.date.year == DateTime.now().year;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPast 
            ? Colors.grey.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPast 
              ? Colors.grey.withOpacity(0.3)
              : isToday
                  ? Colors.green
                  : Colors.green.withOpacity(0.3),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  slot.date.day.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  _getMonthName(slot.date.month),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        slot.timeSlot,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  slot.reason,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Productivity: ${slot.productivityScore.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${slot.durationMinutes} min',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Analytics Dashboard Help',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This dashboard provides insights into your study habits and productivity.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Smart Insights',
                'Quick tips based on your recent study patterns',
                Icons.lightbulb_outline,
              ),
              _buildHelpItem(
                'Overview Cards',
                'Your total sessions and study time at a glance',
                Icons.dashboard,
              ),
              _buildHelpItem(
                'Weekly Productivity',
                'Bar chart showing your study minutes over the last 7 days',
                Icons.bar_chart,
              ),
              _buildHelpItem(
                'AI Recommendations',
                'Personalized suggestions to improve your study efficiency',
                Icons.lightbulb,
              ),
              _buildHelpItem(
                'Productivity Patterns',
                'Shows when you study best (morning, afternoon, evening, night)',
                Icons.insights,
              ),
              _buildHelpItem(
                'Study Techniques',
                'Breakdown of your usage of Pomodoro, Spaced Repetition, and Active Recall',
                Icons.pie_chart,
              ),
              _buildHelpItem(
                'Deadline Pressure',
                'Upcoming assignments with urgency levels and risk scores',
                Icons.warning_amber_rounded,
              ),
              _buildHelpItem(
                'Optimal Study Times',
                'Recommended time slots when you\'re most productive',
                Icons.schedule,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tip: Complete more study sessions to get more accurate insights!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


