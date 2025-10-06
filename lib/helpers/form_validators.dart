import 'app_regex.dart';

class FormValidators {
  /// Validate email field
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    if (!AppRegex.isEmailValid(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate password field
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (!AppRegex.hasMinLength(value)) {
      return 'Password must be at least 8 characters';
    }
    
    if (!AppRegex.hasUppercase(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!AppRegex.hasLowercase(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!AppRegex.hasNumber(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validate name field
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (!AppRegex.isNameValid(value.trim())) {
      return 'Please enter a valid name';
    }
    
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    if (!AppRegex.isPhoneValid(value.trim())) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }
    
    return null;
  }

  /// Validate age
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    
    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    
    if (age > 120) {
      return 'Please enter a valid age';
    }
    
    return null;
  }

  /// Validate dropdown selection
  static String? validateDropdownSelection(dynamic value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate list selection
  static String? validateListSelection(List<dynamic>? values, String fieldName) {
    if (values == null || values.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate location
  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location is required';
    }
    return null;
  }

  /// Validate time slots
  static String? validateTimeSlots(List<dynamic>? value) {
    if (value == null || value.isEmpty) {
      return 'Time slots are required';
    }
    return null;
  }

  /// Validate experience years
  static String? validateExperienceYears(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Experience years is required';
    }
    
    final years = int.tryParse(value.trim());
    if (years == null || years < 0) {
      return 'Please enter valid experience years';
    }
    
    return null;
  }

  /// Validate certifications
  static String? validateCertifications(String? value) {
    // Optional field, so return null if empty
    return null;
  }

  /// Validate hourly rate
  static String? validateHourlyRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Hourly rate is required';
    }
    
    final rate = double.tryParse(value.trim());
    if (rate == null || rate <= 0) {
      return 'Please enter a valid hourly rate';
    }
    
    return null;
  }

  /// Validate bio
  static String? validateBio(String? value) {
    if (value != null && value.length > 500) {
      return 'Bio must not exceed 500 characters';
    }
    return null;
  }
}