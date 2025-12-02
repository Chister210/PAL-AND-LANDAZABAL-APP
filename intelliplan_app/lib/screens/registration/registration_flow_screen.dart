import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';
import '../../config/theme.dart';

class RegistrationFlowScreen extends StatefulWidget {
  const RegistrationFlowScreen({super.key});

  @override
  State<RegistrationFlowScreen> createState() => _RegistrationFlowScreenState();
}

class _RegistrationFlowScreenState extends State<RegistrationFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _gender;
  String? _studyTechnique;
  DateTime? _birthdate;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _googleEmail;
  bool _isSigningInWithGoogle = false;
  
  // Username validation state
  bool _isCheckingUsername = false;
  bool _usernameExists = false;
  List<String> _usernameSuggestions = [];
  
  // Email validation state
  String? _emailError;

  final List<Map<String, dynamic>> _studyTechniques = [
    {
      'name': 'Pomodoro Technique',
      'image': 'assets/icons/pomodoro-technique.png',
      'description':
          '"Stay productive by working in 25-minute focus sessions followed by short breaks. Helps build discipline and avoid burnout."',
      'features': 'A focus timer with session tracking, break reminders, and optional gamified rewards.',
    },
    {
      'name': 'Active Recall Technique',
      'image': 'assets/icons/active_recall_technique.png',
      'description':
          '"Boost memory retention by actively retrieving information instead of passively reviewing notes."',
      'features': 'Flashcard quizzes, self-testing prompts, and progress tracking.',
    },
    {
      'name': 'Spaced Repetition',
      'image': 'assets/icons/space_repetition.png',
      'description':
          '"Optimize long-term retention by reviewing material at increasing intervals over time."',
      'features': 'Smart scheduling for review sessions based on your performance.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdateController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentPrimary,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceHigh,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthdate = picked;
        _birthdateController.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  int _calculateAge() {
    if (_birthdate == null) return 0;
    final now = DateTime.now();
    int age = now.year - _birthdate!.year;
    if (now.month < _birthdate!.month ||
        (now.month == _birthdate!.month && now.day < _birthdate!.day)) {
      age--;
    }
    return age;
  }

  String _getPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    if (password.length >= 8 && 
        password.contains(RegExp(r'[A-Z]')) && 
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Strong';
    }
    return 'Weak';
  }

  bool _validateStep1() {
    if (_firstNameController.text.trim().isEmpty) {
      _showError('Please enter your first name');
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showError('Please enter your last name');
      return false;
    }
    if (_birthdate == null) {
      _showError('Please select your birthdate');
      return false;
    }
    if (_gender == null) {
      _showError('Please select your gender');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_studyTechnique == null) {
      _showError('Please select a study technique');
      return false;
    }
    return true;
  }

  Future<bool> _validateStep3() async {
    if (_googleEmail != null) {
      // If signed in with Google, still need to validate username
      if (_usernameController.text.trim().isEmpty) {
        _showError('Please enter a username');
        return false;
      }
      if (_usernameController.text.trim().length < 8) {
        _showError('Username must be at least 8 characters');
        return false;
      }
      // Check for username duplicates
      final usernameExists = await _checkUsernameExists(_usernameController.text.trim());
      if (usernameExists) {
        final suggestions = await _generateUsernameSuggestions(_usernameController.text.trim());
        _showUsernameExistsDialog(suggestions);
        return false;
      }
      return true;
    }
    
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email address');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showError('Please enter a valid email address');
      return false;
    }
    if (_usernameController.text.trim().isEmpty) {
      _showError('Please enter a username');
      return false;
    }
    if (_usernameController.text.trim().length < 8) {
      _showError('Username must be at least 8 characters');
      return false;
    }
    // Check for username duplicates
    final usernameExists = await _checkUsernameExists(_usernameController.text.trim());
    if (usernameExists) {
      final suggestions = await _generateUsernameSuggestions(_usernameController.text.trim());
      _showUsernameExistsDialog(suggestions);
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please create a password');
      return false;
    }
    if (_getPasswordStrength() == 'Weak') {
      _showError('Please create a stronger password (at least 8 characters with uppercase, number, and special character)');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return false;
    }
    return true;
  }

  Future<bool> _checkUsernameExists(String username) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }

  Future<List<String>> _generateUsernameSuggestions(String baseUsername) async {
    List<String> suggestions = [];
    String cleanUsername = baseUsername.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    
    // Generate 5 suggestions
    for (int i = 0; i < 5; i++) {
      String suggestion;
      if (i == 0) {
        // Add random 3 digits
        suggestion = '$cleanUsername${Random().nextInt(900) + 100}';
      } else if (i == 1) {
        // Add random 4 digits
        suggestion = '$cleanUsername${Random().nextInt(9000) + 1000}';
      } else if (i == 2) {
        // Add underscore and 3 digits
        suggestion = '${cleanUsername}_${Random().nextInt(900) + 100}';
      } else if (i == 3) {
        // Add current year
        suggestion = '$cleanUsername${DateTime.now().year}';
      } else {
        // Add random letters
        const chars = 'abcdefghijklmnopqrstuvwxyz';
        final random = Random();
        final suffix = String.fromCharCodes(
          Iterable.generate(3, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
        );
        suggestion = '$cleanUsername$suffix';
      }
      
      // Make sure suggestion is at least 8 characters
      if (suggestion.length < 8) {
        suggestion = '${suggestion}_${Random().nextInt(900) + 100}';
      }
      
      // Check if suggestion is available
      final exists = await _checkUsernameExists(suggestion);
      if (!exists) {
        suggestions.add(suggestion);
      }
      
      if (suggestions.length >= 3) break; // Stop after finding 3 available suggestions
    }
    
    return suggestions;
  }

  // Real-time username validation
  Future<void> _checkUsernameRealtime(String username) async {
    // Clear previous state if username is too short
    if (username.trim().length < 8) {
      if (mounted) {
        setState(() {
          _usernameExists = false;
          _usernameSuggestions = [];
          _isCheckingUsername = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isCheckingUsername = true;
        _usernameExists = false;
        _usernameSuggestions = [];
      });
    }

    try {
      final exists = await _checkUsernameExists(username.trim());
      
      if (mounted) {
        if (exists) {
          final suggestions = await _generateUsernameSuggestions(username.trim());
          setState(() {
            _usernameExists = true;
            _usernameSuggestions = suggestions;
            _isCheckingUsername = false;
          });
        } else {
          setState(() {
            _usernameExists = false;
            _usernameSuggestions = [];
            _isCheckingUsername = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking username: $e');
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
        });
      }
    }
  }

  void _showUsernameExistsDialog(List<String> suggestions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Username Already Taken',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                'The username "${_usernameController.text}" is already in use.',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Here are some available suggestions:',
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _usernameController.text = suggestion;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.accentPrimary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, 
                            color: AppTheme.accentPrimary, 
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: GoogleFonts.inter(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, 
                            color: AppTheme.accentPrimary, 
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Try Another',
                style: GoogleFonts.inter(
                  color: AppTheme.accentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningInWithGoogle = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isSigningInWithGoogle = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Check if user already exists in Firestore
      if (userCredential.user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        if (userDoc.exists) {
          // User already registered
          setState(() => _isSigningInWithGoogle = false);
          await FirebaseAuth.instance.signOut();
          await googleSignIn.signOut();
          
          if (mounted) {
            _showErrorDialog(
              'Account Already Exists',
              'This Google account is already registered. Please sign in with your existing account instead.',
            );
          }
          return;
        }
      }
      
      setState(() {
        _googleEmail = userCredential.user?.email;
        _emailController.text = _googleEmail ?? '';
        _usernameController.text = userCredential.user?.displayName ?? '';
        _isSigningInWithGoogle = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed in with Google: $_googleEmail'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isSigningInWithGoogle = false);
      if (mounted) {
        String errorMessage = 'Google Sign-In failed';
        if (e.code == 'account-exists-with-different-credential') {
          errorMessage = 'An account already exists with this email using a different sign-in method.';
        }
        _showErrorDialog('Sign-In Error', errorMessage);
      }
    } catch (e) {
      setState(() => _isSigningInWithGoogle = false);
      if (mounted) {
        _showErrorDialog('Error', 'Google Sign-In failed. Please try again.');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  color: AppTheme.accentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
              child: Text(
                'Sign In Instead',
                style: GoogleFonts.inter(
                  color: AppTheme.accentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _nextPageWithValidation() async {
    bool isValid = false;
    
    switch (_currentPage) {
      case 0:
        isValid = _validateStep1();
        break;
      case 1:
        isValid = _validateStep2();
        break;
      case 2:
        isValid = await _validateStep3();
        break;
      default:
        isValid = true;
    }

    if (isValid) {
      _nextPage();
    }
  }

  Future<void> _completeRegistration() async {
    try {
      // Create account if not using Google
      User? user;
      
      if (_googleEmail == null) {
        // Regular email/password registration
        try {
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          user = userCredential.user;

          // Send email verification
          if (user != null && !user.emailVerified) {
            await user.sendEmailVerification();
            
            // Show verification dialog
            if (mounted) {
              await _showEmailVerificationDialog(user);
            }
            return; // Don't proceed until verified
          }
        } on FirebaseAuthException catch (e) {
          if (mounted) {
            String errorMessage = 'Error creating account';
            if (e.code == 'email-already-in-use') {
              errorMessage = 'This email address is already registered. Please sign in with your existing account instead.';
            } else if (e.code == 'invalid-email') {
              errorMessage = 'The email address is invalid. Please check and try again.';
            } else if (e.code == 'weak-password') {
              errorMessage = 'The password is too weak. Please create a stronger password.';
            }
            _showErrorDialog('Registration Error', errorMessage);
          }
          return;
        }
      } else {
        // Already signed in with Google
        user = FirebaseAuth.instance.currentUser;
      }

      // Save user data to Firestore
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          'birthdate': _birthdate?.toIso8601String(),
          'gender': _gender,
          'studyTechnique': _studyTechnique,
          'email': _googleEmail ?? _emailController.text.trim(),
          'username': _usernameController.text.trim(),
          'signInMethod': _googleEmail != null ? 'google' : 'email',
          'level': 1,
          'experience': 0,
          'createdAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      // Move to next page (summary)
      if (mounted) {
        _nextPage();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'An unexpected error occurred. Please try again.');
      }
    }
  }

  Future<void> _showEmailVerificationDialog(User user) async {
    bool isVerified = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.email, color: AppTheme.accentPrimary),
                  const SizedBox(width: 12),
                  Text(
                    'Verify Your Email',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We\'ve sent a verification email to:',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email ?? '',
                    style: GoogleFonts.inter(
                      color: AppTheme.accentPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isVerified)
                    Text(
                      'Please check your inbox and click the verification link.',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary),
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Email verified successfully!',
                            style: GoogleFonts.inter(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                if (!isVerified)
                  TextButton(
                    onPressed: () async {
                      await user.reload();
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null && currentUser.emailVerified) {
                        setState(() {
                          isVerified = true;
                        });
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email not verified yet. Please check your inbox.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'I\'ve Verified',
                      style: GoogleFonts.inter(color: AppTheme.accentPrimary),
                    ),
                  ),
                if (!isVerified)
                  TextButton(
                    onPressed: () async {
                      await user.sendEmailVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verification email resent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Resend Email',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary),
                    ),
                  ),
                if (isVerified)
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // Save user data and proceed
                      try {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'firstName': _firstNameController.text.trim(),
                          'lastName': _lastNameController.text.trim(),
                          'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                          'birthdate': _birthdate?.toIso8601String(),
                          'gender': _gender,
                          'studyTechnique': _studyTechnique,
                          'email': _emailController.text.trim(),
                          'username': _usernameController.text.trim(),
                          'signInMethod': 'email',
                          'level': 1,
                          'experience': 0,
                          'createdAt': DateTime.now().toIso8601String(),
                        }, SetOptions(merge: true));
                        
                        // Move to summary page
                        _nextPage();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPrimary,
                    ),
                    child: Text(
                      'Proceed to Login',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentPage > 0) {
          setState(() {
            _currentPage--;
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgBase,
        body: SafeArea(
          child: Column(
            children: [
              // Header with back button, logo and progress
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Back button
                    if (_currentPage > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                          onPressed: () {
                            setState(() {
                              _currentPage--;
                              _pageController.animateToPage(
                                _currentPage,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            });
                          },
                        ),
                      ),
                    // Logo
                    Image.asset(
                      'assets/icons/app_logo.png',
                      width: 120,
                      height: 120,
                    ),
                  const SizedBox(height: 24),
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Container(
                        width: index == _currentPage ? 12 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? AppTheme.accentPrimary
                              : index < _currentPage
                                  ? AppTheme.accentPrimary.withOpacity(0.5)
                                  : AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildStep1(), // Personal Info
                  _buildStep2(), // Study Technique
                  _buildStep3(), // Account Creation
                  _buildStep4(), // Summary
                  _buildStep5(), // Final Screen
                ],
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _currentPage == 4
                  ? Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to dashboard after registration completion
                          context.go('/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'GET STARTED',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        // Back button for Step 1 only
                        if (_currentPage == 0)
                          TextButton.icon(
                            onPressed: () => context.go('/welcome'),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(
                              'BACK',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                            ),
                          ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _currentPage == 3 ? _completeRegistration : _nextPageWithValidation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'CONTINUE',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // Step 1: Personal Information
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let\'s get to know you first!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // First Name
          Text(
            'First Name',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _firstNameController,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter First Name',
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Last Name
          Text(
            'Last Name',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lastNameController,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter Last Name',
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Birthdate
          Text(
            'Birthdate',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _birthdateController,
            readOnly: true,
            onTap: _selectDate,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'MM / DD / YY',
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: const Icon(Icons.calendar_today, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          // Gender
          Text(
            'Gender',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGenderButton('Male'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderButton('Female'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderButton('Prefer not to say'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String gender) {
    final isSelected = _gender == gender;
    return InkWell(
      onTap: () => setState(() => _gender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentPrimary : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          gender,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // Step 2: Study Technique Selection
  Widget _buildStep2() {
    final currentIndex = _studyTechniques.indexWhere(
      (technique) => technique['name'] == _studyTechnique,
    );
    final displayIndex = currentIndex == -1 ? 0 : currentIndex;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            'Which study technique\nfits you best?',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),

        // Technique Card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Icon
                  Image.asset(
                    _studyTechniques[displayIndex]['image'],
                    width: 70,
                    height: 70,
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    _studyTechniques[displayIndex]['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    _studyTechniques[displayIndex]['description'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Features
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgBase,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What to expect in the app?',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _studyTechniques[displayIndex]['features'],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Navigation arrows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: displayIndex > 0
                    ? () {
                        setState(() {
                          _studyTechnique =
                              _studyTechniques[displayIndex - 1]['name'];
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
              ),
              Row(
                children: List.generate(_studyTechniques.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == displayIndex
                          ? AppTheme.accentPrimary
                          : AppTheme.surfaceHigh,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              IconButton(
                onPressed: displayIndex < _studyTechniques.length - 1
                    ? () {
                        setState(() {
                          _studyTechnique =
                              _studyTechniques[displayIndex + 1]['name'];
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 3: Account Creation
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your IntelliPlan Account!',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"Let\'s set up your account so you can sync your tasks, progress, and study preferences anywhere."',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Email
          Text(
            'Email Address',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              setState(() {
                if (value.isEmpty) {
                  _emailError = null;
                } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  _emailError = 'Please enter a valid email address';
                } else {
                  _emailError = null;
                }
              });
            },
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your Email',
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accentAlert, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accentAlert, width: 2),
              ),
            ),
          ),
          if (_emailError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.accentAlert, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _emailError!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.accentAlert,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Username
          Text(
            'Username',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            onChanged: (value) {
              setState(() {});
              // Debounce username checking (wait 500ms after user stops typing)
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_usernameController.text == value) {
                  _checkUsernameRealtime(value);
                }
              });
            },
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your Username (min. 8 characters)',
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterText: '${_usernameController.text.length}/8 min',
              counterStyle: GoogleFonts.inter(
                color: _usernameController.text.length >= 8 
                    ? (_usernameExists ? Colors.red : Colors.green)
                    : AppTheme.textSecondary,
                fontSize: 12,
              ),
              suffixIcon: _isCheckingUsername
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_usernameController.text.length >= 8 && !_usernameExists)
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
            ),
          ),
          if (_usernameController.text.isNotEmpty && _usernameController.text.length < 8) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Username must be at least 8 characters',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
          if (_usernameExists && _usernameController.text.length >= 8) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Username "${_usernameController.text}" is already taken',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (_usernameSuggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Try these available usernames:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _usernameSuggestions.map((suggestion) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _usernameController.text = suggestion;
                        _usernameExists = false;
                        _usernameSuggestions = [];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.accentPrimary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, size: 14, color: AppTheme.accentPrimary),
                          const SizedBox(width: 4),
                          Text(
                            suggestion,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.accentPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 16),

          // Password (only show if NOT using Google)
          if (_googleEmail == null) ...[
            Text(
              'Password',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              onChanged: (_) => setState(() {}), // Trigger rebuild for password strength
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Create a Strong Password',
                hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Password strength progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _getPasswordStrength() == 'Strong' ? 1.0 : 0.5,
                            backgroundColor: AppTheme.surfaceHigh,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getPasswordStrength() == 'Strong' ? Colors.green : Colors.orange,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(
                            _getPasswordStrength() == 'Strong' ? Icons.check_circle : Icons.warning,
                            color: _getPasswordStrength() == 'Strong' ? Colors.green : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPasswordStrength() == 'Strong' ? 'Strong' : 'Weak',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getPasswordStrength() == 'Strong' ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Password requirements
                  _buildPasswordRequirement(
                    'At least 8 characters',
                  _passwordController.text.length >= 8,
                ),
                _buildPasswordRequirement(
                  'One uppercase letter',
                  _passwordController.text.contains(RegExp(r'[A-Z]')),
                ),
                _buildPasswordRequirement(
                  'One number',
                  _passwordController.text.contains(RegExp(r'[0-9]')),
                ),
                _buildPasswordRequirement(
                  'One special character (!@#\$%^&*)',
                  _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
                ),
              ],
            ),
          ],
            const SizedBox(height: 16),

            // Confirm Password
            Text(
              'Confirm Password',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_confirmPasswordVisible,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Re-enter Password',
                hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // OR Divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppTheme.textSecondary)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),

          // Google Sign-In Button
          if (_googleEmail == null)
            ElevatedButton.icon(
              onPressed: _isSigningInWithGoogle ? null : _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.surfaceHigh),
                ),
              ),
              icon: _isSigningInWithGoogle
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Image.asset(
                      'assets/icons/google.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.login, size: 24);
                      },
                    ),
              label: Text(
                _isSigningInWithGoogle ? 'Signing in...' : 'Sign up with Google',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signed in with Google',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          _googleEmail!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Step 4: Summary
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All set, ${_firstNameController.text}!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"Here\'s a quick look at your setup before we begin."',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),

          // First Name
          _buildSummaryField('First Name', _firstNameController.text),
          const SizedBox(height: 12),

          // Last Name
          _buildSummaryField('Last Name', _lastNameController.text),
          const SizedBox(height: 12),

          // Birthdate
          _buildSummaryField(
            'Birthdate',
            _birthdate != null
                ? '${_birthdate!.month}/${_birthdate!.day}/${_birthdate!.year} (${_calculateAge()} years old)'
                : '',
          ),
          const SizedBox(height: 12),

          // Email
          _buildSummaryField(
            'Email',
            _googleEmail ?? _emailController.text,
          ),
          const SizedBox(height: 12),

          // Study Preference
          Text(
            'Study Preference:',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (_studyTechnique != null)
                  Image.asset(
                    _studyTechniques.firstWhere(
                      (t) => t['name'] == _studyTechnique,
                      orElse: () => _studyTechniques[0],
                    )['image'],
                    width: 40,
                    height: 40,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _studyTechnique ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Step 5: Final Screen
  Widget _buildStep5() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to IntelliPlan,',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${_firstNameController.text} ${_lastNameController.text}!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Image.asset(
              'assets/icons/app_logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 32),

            // User Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentPrimary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.email, 'Email', _googleEmail ?? _emailController.text),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.cake, 'Birthdate', 
                    _birthdate != null 
                        ? '${_birthdate!.month}/${_birthdate!.day}/${_birthdate!.year}'
                        : ''),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.psychology, 'Study Technique', _studyTechnique ?? ''),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'You\'re now ready to start building better study habits!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _previousPage,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.textSecondary),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'GO BACK & EDIT',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirement(String requirement, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet ? Colors.green : AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            requirement,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isMet ? Colors.green : AppTheme.textSecondary,
              decoration: isMet ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
