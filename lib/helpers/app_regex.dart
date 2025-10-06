class AppRegex {
  /// Email validation regex
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Password validation regex (at least 8 characters, 1 uppercase, 1 lowercase, 1 number)
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
  );

  /// Phone number regex
  static final RegExp phoneRegex = RegExp(
    r'^\+?[\d\s\-\(\)]{10,}$',
  );

  /// Name validation regex (letters, spaces, hyphens, apostrophes)
  static final RegExp nameRegex = RegExp(
    r"^[a-zA-Z\s\-']+$",
  );

  /// Check if email is valid
  static bool isEmailValid(String email) {
    return emailRegex.hasMatch(email);
  }

  /// Check if password is valid
  static bool isPasswordValid(String password) {
    return passwordRegex.hasMatch(password);
  }

  /// Check if phone number is valid
  static bool isPhoneValid(String phone) {
    return phoneRegex.hasMatch(phone);
  }

  /// Check if name is valid
  static bool isNameValid(String name) {
    return nameRegex.hasMatch(name) && name.trim().isNotEmpty;
  }

  /// Validate team name
  static String? validateTeamName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Team name is required';
    }
    if (value.trim().length < 2) {
      return 'Team name must be at least 2 characters';
    }
    return null;
  }

  /// Check if password has minimum length
  static bool hasMinLength(String password, {int minLength = 8}) {
    return password.length >= minLength;
  }

  /// Check if password has uppercase letter
  static bool hasUppercase(String password) {
    return RegExp(r'[A-Z]').hasMatch(password);
  }

  /// Check if password has lowercase letter
  static bool hasLowercase(String password) {
    return RegExp(r'[a-z]').hasMatch(password);
  }

  /// Check if password has number
  static bool hasNumber(String password) {
    return RegExp(r'\d').hasMatch(password);
  }

  /// Check if password has special character
  static bool hasSpecialChar(String password) {
    return RegExp(r'[@$!%*?&]').hasMatch(password);
  }
}