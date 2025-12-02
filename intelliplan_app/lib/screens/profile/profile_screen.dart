import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../config/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    final authService = context.read<AuthService>();
    final gamificationService = context.read<GamificationService>();
    
    if (authService.currentUser != null) {
      // initializeForUser now checks internally if already initialized
      await gamificationService.initializeForUser(authService.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final gamificationService = context.watch<GamificationService>();
    final user = authService.currentUser;
    
    final unlockedAchievements = gamificationService.achievements.where((a) => a.unlocked).length;
    final currentXP = gamificationService.userGamification?.xp ?? 0;
    final currentLevel = gamificationService.userGamification?.level ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: user?.id != null
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.id)
                            .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      final userData = snapshot.data?.data() as Map<String, dynamic>?;
                      final profileImageUrl = userData?['profilePictureUrl'] as String?;
                      
                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.2),
                            backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                ? (profileImageUrl.startsWith('data:image')
                                    ? MemoryImage(
                                        base64Decode(profileImageUrl.split(',')[1]))
                                    : NetworkImage(profileImageUrl) as ImageProvider)
                                : null,
                            child: profileImageUrl == null || profileImageUrl.isEmpty
                                ? Text(
                                    user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user?.name ?? 'User',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          // Level Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Level $currentLevel',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.auto_graph, size: 32, color: Colors.green),
                            const SizedBox(height: 8),
                            Text(
                              '$currentXP',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text('Experience', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.emoji_events, size: 32, color: Colors.amber),
                            const SizedBox(height: 8),
                            gamificationService.achievements.isEmpty
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    '$unlockedAchievements',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                            const Text('Achievements', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Settings Options
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.school, color: Colors.white),
                      title: const Text('Study Technique', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        user?.studyTechnique ?? 'Not selected',
                        style: TextStyle(
                          color: AppTheme.accentPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () => _showStudyTechniqueDialog(context, authService),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.white),
                      title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () => _showEditProfileDialog(context, authService),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications, color: Colors.white),
                      title: const Text('Notifications', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () => _showNotificationSettingsDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.feedback, color: Colors.white),
                      title: const Text('Send Feedback', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () => context.push('/feedback'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help, color: Colors.white),
                      title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () => _showHelpDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info, color: Colors.white),
                      title: const Text('About', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _showLogoutConfirmation(context, authService),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showLogoutConfirmation(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.accentAlert),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.logout();
              if (context.mounted) {
                while (context.canPop()) {
                  context.pop();
                }
                context.pushReplacement('/welcome');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAlert,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static void _showStudyTechniqueDialog(BuildContext context, AuthService authService) {
    final currentTechnique = authService.currentUser?.studyTechnique;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Choose Study Technique',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTechniqueOption(
              context: dialogContext,
              authService: authService,
              technique: 'Pomodoro Technique',
              icon: '🍅',
              color: Colors.red,
              description: 'Work in 25-minute focused intervals',
              isSelected: currentTechnique == 'Pomodoro Technique',
            ),
            const SizedBox(height: 12),
            _buildTechniqueOption(
              context: dialogContext,
              authService: authService,
              technique: 'Spaced Repetition',
              icon: '📚',
              color: AppTheme.accentPrimary,
              description: 'Review at optimal intervals',
              isSelected: currentTechnique == 'Spaced Repetition',
            ),
            const SizedBox(height: 12),
            _buildTechniqueOption(
              context: dialogContext,
              authService: authService,
              technique: 'Active Recall Technique',
              icon: '🧠',
              color: Colors.green,
              description: 'Test yourself actively',
              isSelected: currentTechnique == 'Active Recall Technique',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTechniqueOption({
    required BuildContext context,
    required AuthService authService,
    required String technique,
    required String icon,
    required Color color,
    required String description,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _confirmTechniqueChange(context, authService, technique),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.surfaceHigh,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technique,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  static void _confirmTechniqueChange(
    BuildContext context,
    AuthService authService,
    String newTechnique,
  ) {
    final currentTechnique = authService.currentUser?.studyTechnique;
    
    if (currentTechnique == newTechnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$newTechnique is already selected'),
          backgroundColor: AppTheme.accentSuccess,
        ),
      );
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: AppTheme.accentPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Change Study Technique?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to change your study technique to:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    _getTechniqueIcon(newTechnique),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      newTechnique,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will update your home screen button and recommended study method.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(confirmContext); // Close confirmation dialog
              
              try {
                final userId = authService.currentUser?.id;
                if (userId != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({'studyTechnique': newTechnique});
                  
                  // Update local user object
                  await authService.refreshUser();
                  
                  if (context.mounted) {
                    Navigator.pop(context); // Close technique selection dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Study technique updated to $newTechnique'),
                        backgroundColor: AppTheme.accentSuccess,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating technique: $e'),
                      backgroundColor: AppTheme.accentAlert,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static String _getTechniqueIcon(String technique) {
    switch (technique) {
      case 'Pomodoro Technique':
        return '🍅';
      case 'Spaced Repetition':
        return '📚';
      case 'Active Recall Technique':
        return '🧠';
      default:
        return '📖';
    }
  }

  // Edit Profile Dialog
  static void _showEditProfileDialog(BuildContext context, AuthService authService) {
    final user = authService.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.accentPrimary.withOpacity(0.2),
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _pickProfileImage(context, authService),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.surfaceAlt, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Username Field
              Text(
                'Username',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter your name',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              // Username Change Cooldown Info
              FutureBuilder<DateTime?>(
                future: _getLastUsernameChange(user?.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final lastChange = snapshot.data!;
                    final daysSinceChange = DateTime.now().difference(lastChange).inDays;
                    final daysRemaining = 7 - daysSinceChange;
                    
                    if (daysRemaining > 0) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentWarning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: AppTheme.accentWarning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You can change your username in $daysRemaining days',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.accentWarning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                  return Text(
                    'You can change your username once every 7 days',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => _saveProfileChanges(
              context,
              dialogContext,
              authService,
              nameController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static Future<DateTime?> _getLastUsernameChange(String? userId) async {
    if (userId == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = doc.data();
      if (data != null && data.containsKey('lastUsernameChange')) {
        return (data['lastUsernameChange'] as Timestamp).toDate();
      }
    } catch (e) {
      debugPrint('Error getting last username change: $e');
    }
    return null;
  }

  static Future<void> _pickProfileImage(BuildContext context, AuthService authService) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Convert image to base64
      final userId = authService.currentUser?.id;
      if (userId != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        final imageDataUrl = 'data:image/jpeg;base64,$base64Image';

        // Update Firestore with base64 data URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'profilePictureUrl': imageDataUrl,
          'profileUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Clear image cache to force reload
        imageCache.clear();
        imageCache.clearLiveImages();

        // Refresh user to get new profile picture
        await authService.refreshUser();

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated! Pull down to refresh if not visible.'),
              backgroundColor: AppTheme.accentSuccess,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: AppTheme.accentAlert,
          ),
        );
      }
    }
  }

  static Future<void> _saveProfileChanges(
    BuildContext context,
    BuildContext dialogContext,
    AuthService authService,
    String newName,
  ) async {
    final user = authService.currentUser;
    if (user == null) return;

    // Validate name
    if (newName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: AppTheme.accentAlert,
        ),
      );
      return;
    }

    // Check if name changed
    if (newName.trim() == user.name) {
      Navigator.pop(dialogContext);
      return;
    }

    // Check cooldown
    final lastChange = await _getLastUsernameChange(user.id);
    if (lastChange != null) {
      final daysSinceChange = DateTime.now().difference(lastChange).inDays;
      if (daysSinceChange < 7) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can change your username in ${7 - daysSinceChange} days'),
              backgroundColor: AppTheme.accentWarning,
            ),
          );
        }
        return;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
        'name': newName.trim(),
        'lastUsernameChange': FieldValue.serverTimestamp(),
      });

      await authService.refreshUser();

      if (context.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.accentSuccess,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.accentAlert,
          ),
        );
      }
    }
  }

  // Notification Settings Dialog
  static void _showNotificationSettingsDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool pushNotifications = prefs.getBool('push_notifications') ?? true;
    bool pomodoroAlarm = prefs.getBool('pomodoro_alarm') ?? true;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceAlt,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Notification Settings',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Push Notifications Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: pushNotifications ? AppTheme.accentPrimary : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Push Notifications',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Get reminders for tasks and events',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: pushNotifications,
                      onChanged: (value) async {
                        setState(() => pushNotifications = value);
                        await prefs.setBool('push_notifications', value);
                      },
                      activeColor: AppTheme.accentPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Pomodoro Alarm Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alarm,
                      color: pomodoroAlarm ? AppTheme.accentPrimary : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pomodoro Alarm',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sound alert when timer completes',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: pomodoroAlarm,
                      onChanged: (value) async {
                        setState(() => pomodoroAlarm = value);
                        await prefs.setBool('pomodoro_alarm', value);
                      },
                      activeColor: AppTheme.accentPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // About Dialog
  static void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info, color: AppTheme.accentPrimary),
            const SizedBox(width: 12),
            Text(
              'About IntelliPlan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Logo/Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.school,
                    size: 48,
                    color: AppTheme.accentPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Version
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Description
              Text(
                'IntelliPlan is an intelligent study planner designed to help students optimize their learning through evidence-based study techniques, smart scheduling, and gamification.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Features
              _buildAboutFeature(
                icon: Icons.timer,
                title: 'Study Techniques',
                description: 'Pomodoro, Spaced Repetition, Active Recall',
              ),
              const SizedBox(height: 12),
              _buildAboutFeature(
                icon: Icons.groups,
                title: 'Team Collaboration',
                description: 'Study together and share tasks',
              ),
              const SizedBox(height: 12),
              _buildAboutFeature(
                icon: Icons.emoji_events,
                title: 'Gamification',
                description: 'Earn XP, unlock achievements, level up',
              ),
              const SizedBox(height: 12),
              _buildAboutFeature(
                icon: Icons.insights,
                title: 'Analytics',
                description: 'Track your productivity and progress',
              ),
              const SizedBox(height: 24),
              // Developed by
              Center(
                child: Column(
                  children: [
                    Text(
                      'Developed by',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pal & Landazabal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAboutFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.accentPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Help & Support Dialog
  static void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help, color: AppTheme.accentPrimary),
            const SizedBox(width: 12),
            Text(
              'Help & Support',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need assistance? We\'re here to help!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Contact Email
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email,
                    color: AppTheme.accentPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Support',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'IntelliPlan@gmail.com',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // FAQ Section
            Text(
              'Common Questions:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '• How do I change my study technique?',
              'Go to Profile → Study Technique',
            ),
            const SizedBox(height: 8),
            _buildHelpItem(
              '• How do I join a team?',
              'Go to Teams → Join Team → Enter team code',
            ),
            const SizedBox(height: 8),
            _buildHelpItem(
              '• How do I earn Study Points?',
              'Complete study sessions and tasks',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildHelpItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          answer,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
