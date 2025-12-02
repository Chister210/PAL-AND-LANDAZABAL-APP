import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

enum AnimationType {
  success,
  error,
  congratulations,
  loading,
  question,
  education,
  timeManagement,
  welcome,
}

class AnimatedFeedbackDialog {
  static void show(
    BuildContext context, {
    required AnimationType type,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onButtonPressed,
    bool autoDismiss = true,
    Duration? autoDismissDuration,
  }) {
    final animationPath = _getAnimationPath(type);
    final color = _getColor(type);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie Animation
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  animationPath,
                  fit: BoxFit.contain,
                  repeat: type == AnimationType.loading,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Button (if provided)
              if (buttonText != null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onButtonPressed?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Auto dismiss if enabled
    if (autoDismiss && type != AnimationType.loading) {
      Future.delayed(
        autoDismissDuration ?? const Duration(seconds: 3),
        () {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      );
    }
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Success!',
    VoidCallback? onComplete,
  }) {
    show(
      context,
      type: AnimationType.success,
      title: title,
      message: message,
      buttonText: 'Continue',
      onButtonPressed: onComplete,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String title = 'Oops!',
    String buttonText = 'Try Again',
    VoidCallback? onRetry,
  }) {
    show(
      context,
      type: AnimationType.error,
      title: title,
      message: message,
      buttonText: buttonText,
      autoDismiss: false,
      onButtonPressed: onRetry,
    );
  }

  static void showCongratulations(
    BuildContext context, {
    required String message,
    String title = 'Congratulations!',
    String buttonText = 'Continue',
    VoidCallback? onContinue,
  }) {
    show(
      context,
      type: AnimationType.congratulations,
      title: title,
      message: message,
      buttonText: buttonText,
      autoDismiss: false,
      onButtonPressed: onContinue,
    );
  }

  static void showLoading(
    BuildContext context, {
    String title = 'Please wait...',
    String message = 'Processing your request',
  }) {
    show(
      context,
      type: AnimationType.loading,
      title: title,
      message: message,
      autoDismiss: false,
    );
  }

  static void dismissLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static void showQuestion(
    BuildContext context, {
    required String message,
    String title = 'Need Help?',
    String buttonText = 'Got it',
    VoidCallback? onConfirm,
  }) {
    show(
      context,
      type: AnimationType.question,
      title: title,
      message: message,
      buttonText: buttonText,
      autoDismiss: false,
      onButtonPressed: onConfirm,
    );
  }

  static String _getAnimationPath(AnimationType type) {
    switch (type) {
      case AnimationType.success:
        return 'assets/animations/Done _ Correct _ Tick.json';
      case AnimationType.error:
        return 'assets/animations/Error Animation.json';
      case AnimationType.congratulations:
        return 'assets/animations/Congratulation _ Success batch.json';
      case AnimationType.loading:
        return 'assets/animations/Book loading.json';
      case AnimationType.question:
        return 'assets/animations/Purple Question Mark.json';
      case AnimationType.education:
        return 'assets/animations/Educatin.json';
      case AnimationType.timeManagement:
        return 'assets/animations/Master Time Management_ Dynamic Animation for Efficient Scheduling.json';
      case AnimationType.welcome:
        return 'assets/animations/welcome.json';
    }
  }

  static Color _getColor(AnimationType type) {
    switch (type) {
      case AnimationType.success:
      case AnimationType.congratulations:
        return AppTheme.accentSuccess;
      case AnimationType.error:
        return AppTheme.accentAlert;
      case AnimationType.loading:
      case AnimationType.question:
      case AnimationType.education:
      case AnimationType.timeManagement:
      case AnimationType.welcome:
        return AppTheme.accentPrimary;
    }
  }
}
