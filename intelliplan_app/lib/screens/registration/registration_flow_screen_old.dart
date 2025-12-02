import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../widgets/animated_feedback_dialog.dart';

class RegistrationFlowScreen extends StatefulWidget {
  const RegistrationFlowScreen({super.key});

  @override
  State<RegistrationFlowScreen> createState() => _RegistrationFlowScreenState();
}

class _RegistrationFlowScreenState extends State<RegistrationFlowScreen> {
  int _currentStep = 0;
  
  // Form data
  final TextEditingController _nameController = TextEditingController();
  DateTime? _birthdate;
  String? _gender;
  bool _isStudent = true;
  String? _studyPreference;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // Show congratulations before navigating
      AnimatedFeedbackDialog.showCongratulations(
        context,
        title: 'All Set!',
        message: 'We\'ve tailored IntelliPlan just for you. Let\'s get started! 🎯',
        buttonText: 'Sign In',
        onContinue: () => context.go('/login'),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        backgroundColor: AppTheme.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: _currentStep > 0
              ? _previousStep
              : () async {
                  try {
                    print('DEBUG: Back button pressed on registration flow');
                    
                    // Sign out the user
                    await FirebaseAuth.instance.signOut();
                    print('DEBUG: Sign out completed');
                    
                    // Wait for sign out to complete
                    await Future.delayed(const Duration(milliseconds: 300));
                    
                    if (!mounted) {
                      print('DEBUG: Widget not mounted, cannot navigate');
                      return;
                    }
                    
                    print('DEBUG: Attempting to navigate to /welcome');
                    // Use GoRouter's context.go()
                    context.go('/welcome');
                    print('DEBUG: Navigation command sent');
                    
                  } catch (e, stackTrace) {
                    print('ERROR in back button: $e');
                    print('ERROR Stack trace: $stackTrace');
                  }
                },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentStep 
                            ? AppTheme.accentPrimary 
                            : AppTheme.textSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Content
            Expanded(
              child: _buildCurrentStep(),
            ),
          ],
        ),
      ),
    );
  }

  // Build only the current step
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return _buildStep1();
    }
  }

  // Step 1: Name + Birthdate
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let\'s get to know you',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about yourself',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          
          // Name field
          Text(
            'Full Name',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              hintStyle: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.textHint),
              filled: true,
              fillColor: AppTheme.inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accentPrimary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Birthdate field
          Text(
            'Birthdate',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.accentPrimary,
                        surface: AppTheme.surfaceHigh,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _birthdate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.inputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _birthdate != null
                        ? '${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year}'
                        : 'Select your birthdate',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: _birthdate != null ? AppTheme.textPrimary : AppTheme.textHint,
                    ),
                  ),
                  const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nameController.text.isNotEmpty && _birthdate != null
                  ? _nextStep
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: AppTheme.textPrimary,
                disabledBackgroundColor: AppTheme.textSecondary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Gender + Student Status
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A bit more about you',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalize your experience',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          
          // Gender selection
          Text(
            'Gender (Optional)',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChip('Male', _gender == 'Male', () => setState(() => _gender = 'Male')),
              const SizedBox(width: 12),
              _buildChip('Female', _gender == 'Female', () => setState(() => _gender = 'Female')),
              const SizedBox(width: 12),
              _buildChip('Other', _gender == 'Other', () => setState(() => _gender = 'Other')),
            ],
          ),
          const SizedBox(height: 32),
          
          // Student status
          Text(
            'Are you a student?',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChip('Yes', _isStudent, () => setState(() => _isStudent = true)),
              const SizedBox(width: 12),
              _buildChip('No', !_isStudent, () => setState(() => _isStudent = false)),
            ],
          ),
          const SizedBox(height: 40),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: AppTheme.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Study Preference
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your study style',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Which technique fits you best? You can change this later',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Pomodoro
          _buildStudyCard(
            'Pomodoro',
            'Work in short focused bursts with breaks',
            Icons.timer_outlined,
            _studyPreference == 'Pomodoro',
            () => setState(() => _studyPreference = 'Pomodoro'),
          ),
          const SizedBox(height: 16),
          
          // Spaced Repetition
          _buildStudyCard(
            'Spaced Repetition',
            'Review at intervals to improve memory',
            Icons.replay_outlined,
            _studyPreference == 'Spaced Repetition',
            () => setState(() => _studyPreference = 'Spaced Repetition'),
          ),
          const SizedBox(height: 16),
          
          // Active Recall
          _buildStudyCard(
            'Active Recall',
            'Test yourself to strengthen learning',
            Icons.psychology_outlined,
            _studyPreference == 'Active Recall',
            () => setState(() => _studyPreference = 'Active Recall'),
          ),
          const SizedBox(height: 40),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _studyPreference != null ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: AppTheme.textPrimary,
                disabledBackgroundColor: AppTheme.textSecondary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Confirmation
  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.accentSuccess.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 50,
              color: AppTheme.accentSuccess,
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Great! We\'ll tailor IntelliPlan for you 🎯',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'You\'re all set to start your productivity journey with ${_studyPreference ?? 'your preferred'} technique',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Name', _nameController.text),
                const SizedBox(height: 12),
                _buildSummaryRow('Birthdate', _birthdate != null ? '${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year}' : 'Not set'),
                if (_gender != null) ...[
                  const SizedBox(height: 12),
                  _buildSummaryRow('Gender', _gender!),
                ],
                const SizedBox(height: 12),
                _buildSummaryRow('Status', _isStudent ? 'Student' : 'Working'),
                const SizedBox(height: 12),
                _buildSummaryRow('Study Style', _studyPreference ?? 'Not selected'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Continue to login
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: AppTheme.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue to Sign In',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentPrimary : AppTheme.inputBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudyCard(String title, String description, IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.accentPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected 
                    ? AppTheme.accentPrimary.withOpacity(0.2)
                    : AppTheme.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? AppTheme.accentPrimary : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.accentPrimary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
