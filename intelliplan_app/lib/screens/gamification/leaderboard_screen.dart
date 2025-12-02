import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    final data = await _databaseService.getLeaderboard(limit: 50);
    setState(() {
      _leaderboardData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboardData.isEmpty
              ? const Center(
                  child: Text('No data available. Be the first on the leaderboard!'),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      // Header with Top 3
                      if (_leaderboardData.length >= 3)
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.leaderboard,
                                  size: 64, color: Colors.white),
                              const SizedBox(height: 12),
                              const Text(
                                'Top Learners',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Top 3 Podium
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (_leaderboardData.length >= 2)
                                    _buildPodiumItem(
                                      _leaderboardData[1],
                                      height: 100,
                                      color: const Color(0xFFC0C0C0),
                                    ),
                                  _buildPodiumItem(
                                    _leaderboardData[0],
                                    height: 130,
                                    color: const Color(0xFFFFD700),
                                  ),
                                  if (_leaderboardData.length >= 3)
                                    _buildPodiumItem(
                                      _leaderboardData[2],
                                      height: 80,
                                      color: const Color(0xFFCD7F32),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      // Rest of the leaderboard
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _leaderboardData.length > 3 
                              ? _leaderboardData.length - 3 
                              : 0,
                          itemBuilder: (context, index) {
                            final player = _leaderboardData[index + 3];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  child: Text(
                                    '${player['rank']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  player['name'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('Level ${player['level']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFFFB800)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${player['experience']} XP',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPodiumItem(
    Map<String, dynamic> player, {
    required double height,
    required Color color,
  }) {
    // Get first letter or emoji for avatar
    final name = player['name'] as String;
    final avatar = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white,
          child: Text(
            avatar,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name.split(' ')[0],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${player['experience']} XP',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${player['rank']}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
