import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'animated_success_dialog.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  bool _isChecking = true;
  bool _canResend = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
    // Enable resend button after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _startVerificationCheck() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Check every 3 seconds for 5 minutes
    final isVerified = await authService.waitForEmailVerification(
      timeout: const Duration(minutes: 5),
      checkInterval: const Duration(seconds: 3),
    );

    if (!mounted) return;

    if (isVerified) {
      // Close this dialog
      Navigator.of(context).pop();
      
      // Show success dialog with "Login now" message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AnimatedSuccessDialog(
          title: 'Email Verified!',
          message: 'Your email has been successfully verified.\n\nPlease login now to continue.',
          onClose: () {
            widget.onVerified();
          },
        ),
      );
    } else {
      // Timeout - show timeout message but keep checking
      setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerification() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.resendVerificationEmail();
    
    if (!mounted) return;
    
    if (success) {
      setState(() {
        _canResend = false;
        _resendCooldown = 30;
      });
      
      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Please check your inbox.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Countdown for resend button
      for (int i = 30; i > 0; i--) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() => _resendCooldown = i - 1);
        }
      }
      
      if (mounted) {
        setState(() => _canResend = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing by back button
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1), // Indigo
                Color(0xFF8B5CF6), // Purple
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animation
              Lottie.asset(
                'assets/animations/Book loading.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                _isChecking
                    ? 'We sent a verification link to:\n${widget.email}\n\nPlease check your email and click the verification link.\n\nWaiting for verification...'
                    : 'Still waiting for verification...\n\nPlease check your email (including spam folder) and click the verification link.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Status indicator
              if (_isChecking)
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              const SizedBox(height: 24),
              
              // Resend button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canResend ? _resendVerification : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6366F1),
                    disabledBackgroundColor: Colors.white30,
                    disabledForegroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _resendCooldown > 0
                        ? 'Resend in ${_resendCooldown}s'
                        : _canResend
                            ? 'Resend Verification Email'
                            : 'Please wait...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Cancel button - Navigate to login
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onVerified(); // Navigate to login
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'I\'ll verify later',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
