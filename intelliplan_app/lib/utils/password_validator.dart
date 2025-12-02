class PasswordStrength {
  final int score; // 0-5
  final String label; // Weak, Medium, Strong, Very Strong
  final double progress; // 0.0-1.0
  final List<String> requirements;
  final bool isValid; // At least medium strength

  PasswordStrength({
    required this.score,
    required this.label,
    required this.progress,
    required this.requirements,
    required this.isValid,
  });
}

class PasswordValidator {
  static PasswordStrength validate(String password) {
    int score = 0;
    List<String> requirements = [];
    
    // Check length
    if (password.length >= 8) {
      score++;
    } else {
      requirements.add('At least 8 characters');
    }
    
    // Check for lowercase
    if (password.contains(RegExp(r'[a-z]'))) {
      score++;
    } else {
      requirements.add('At least one lowercase letter');
    }
    
    // Check for uppercase
    if (password.contains(RegExp(r'[A-Z]'))) {
      score++;
    } else {
      requirements.add('At least one uppercase letter');
    }
    
    // Check for digits
    if (password.contains(RegExp(r'[0-9]'))) {
      score++;
    } else {
      requirements.add('At least one number');
    }
    
    // Check for special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score++;
    } else {
      requirements.add('At least one special character (!@#\$%^&*...)');
    }
    
    // Bonus point for very long passwords
    if (password.length >= 12) {
      score++;
    }
    
    // Determine label and validity
    String label;
    bool isValid;
    
    if (score <= 1) {
      label = 'Very Weak';
      isValid = false;
    } else if (score == 2) {
      label = 'Weak';
      isValid = false;
    } else if (score == 3) {
      label = 'Medium';
      isValid = true;
    } else if (score == 4) {
      label = 'Strong';
      isValid = true;
    } else {
      label = 'Very Strong';
      isValid = true;
    }
    
    return PasswordStrength(
      score: score,
      label: label,
      progress: score / 5.0,
      requirements: requirements,
      isValid: isValid,
    );
  }
}
