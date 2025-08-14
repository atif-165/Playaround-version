class AppRegex {
  static bool isEmailValid(String email) {
    return RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
        .hasMatch(email);
  }

  static bool isPasswordValid(String password) {
    // Password must be at least 8 characters long and contain:
    // - At least one uppercase letter
    // - At least one lowercase letter
    // - At least one digit
    // - At least one special character
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
        .hasMatch(password);
  }

  static String getPasswordValidationMessage(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'(?=.*\d)').hasMatch(password)) {
      return 'Password must contain at least one digit';
    }
    if (!RegExp(r'(?=.*[@$!%*?&])').hasMatch(password)) {
      return 'Password must contain at least one special character (@\$!%*?&)';
    }
    return '';
  }

  static String? validateTeamName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a team name';
    }
    if (value.trim().length < 3) {
      return 'Team name must be at least 3 characters long';
    }
    if (value.trim().length > 50) {
      return 'Team name must be less than 50 characters';
    }
    // Check for inappropriate characters
    if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(value.trim())) {
      return 'Team name can only contain letters, numbers, spaces, hyphens, and underscores';
    }
    return null;
  }
}
