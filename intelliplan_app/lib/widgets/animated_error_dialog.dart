import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimatedErrorDialog extends StatelessWidget {
  final String errorCode;
  final VoidCallback? onClose;

  const AnimatedErrorDialog({
    Key? key,
    required this.errorCode,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorInfo = _getErrorInfo(errorCode);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation
            Lottie.asset(
              errorInfo.animationPath,
              height: 150,
              fit: BoxFit.contain,
              repeat: true,
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              errorInfo.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              errorInfo.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onClose?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ErrorInfo _getErrorInfo(String code) {
    switch (code) {
      // Login errors
      case 'USER_NOT_FOUND':
        return ErrorInfo(
          title: 'Account Not Found',
          message: 'No account exists with this email address. Please check your email or create a new account.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      case 'WRONG_PASSWORD':
        return ErrorInfo(
          title: 'Incorrect Password',
          message: 'The password you entered is incorrect. Please try again or reset your password.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      case 'INVALID_EMAIL':
        return ErrorInfo(
          title: 'Invalid Email',
          message: 'The email address format is invalid. Please enter a valid email address.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      case 'EMAIL_NOT_VERIFIED':
        return ErrorInfo(
          title: 'Email Not Verified',
          message: 'Please verify your email before logging in. Check your inbox for the verification link.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      case 'USER_DISABLED':
        return ErrorInfo(
          title: 'Account Disabled',
          message: 'This account has been disabled. Please contact support for assistance.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      // Registration errors
      case 'EMAIL_ALREADY_EXISTS':
        return ErrorInfo(
          title: 'Email Already Registered',
          message: 'An account with this email already exists. Please log in or use a different email address.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      case 'WEAK_PASSWORD':
        return ErrorInfo(
          title: 'Weak Password',
          message: 'Your password is too weak. Please use a stronger password with at least 8 characters.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      // Google Sign-In errors
      case 'GOOGLE_SIGNIN_FAILED':
        return ErrorInfo(
          title: 'Google Sign-In Not Configured',
          message: 'Google Sign-In needs to be configured in Firebase Console. Please contact the administrator or try signing up with email/password instead.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      case 'EMAIL_EXISTS_DIFFERENT_METHOD':
        return ErrorInfo(
          title: 'Email Already Used',
          message: 'This email is already registered using email/password. Please log in with your password instead.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      case 'EMAIL_EXISTS_PASSWORD_METHOD':
        return ErrorInfo(
          title: 'Email Already Registered',
          message: 'This email is already registered with email/password. Please sign in using your email and password instead of Google Sign-In.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      case 'EMAIL_EXISTS_GOOGLE_METHOD':
        return ErrorInfo(
          title: 'Account Already Exists',
          message: 'This email is already registered with Google Sign-In. Please use the Login screen to sign in with your Google account.',
          animationPath: 'assets/animations/Error Animation.json',
        );
      
      default:
        return ErrorInfo(
          title: 'Error',
          message: code,
          animationPath: 'assets/animations/Error Animation.json',
        );
    }
  }

  static void show(BuildContext context, String errorCode, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedErrorDialog(
        errorCode: errorCode,
        onClose: onClose,
      ),
    );
  }
}

class ErrorInfo {
  final String title;
  final String message;
  final String animationPath;

  ErrorInfo({
    required this.title,
    required this.message,
    required this.animationPath,
  });
}
