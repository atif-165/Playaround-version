import 'app_regex.dart';

/// Utility class containing reusable form validation functions.
/// 
/// This class provides consistent validation logic across the app
/// and centralizes validation rules for easier maintenance.
class FormValidators {
  /// Validates an email address.
  /// 
  /// Returns null if valid, error message string if invalid.
  static String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    
    if (email.isEmpty) {
      return 'Please enter an email address';
    }
    
    if (!AppRegex.isEmailValid(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validates a password.
  /// 
  /// Returns null if valid, error message string if invalid.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    
    if (!AppRegex.isPasswordValid(value)) {
      return AppRegex.getPasswordValidationMessage(value);
    }
    
    return null;
  }
  
  /// Validates password confirmation.
  /// 
  /// [value] - The confirmation password
  /// [originalPassword] - The original password to match against
  /// 
  /// Returns null if valid, error message string if invalid.
  static String? validatePasswordConfirmation(String? value, String originalPassword) {
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return validatePassword(value);
  }
  
  /// Validates a name field.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateName(String? value) {
    final name = (value ?? '').trim();

    if (name.isEmpty) {
      return 'Please enter a valid name';
    }

    if (name.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (name.length > 50) {
      return 'Name must be 50 characters or less';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validates an age field.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }

    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }

    if (age < 13 || age > 100) {
      return 'Age must be between 13 and 100';
    }

    return null;
  }

  /// Validates a location/city field.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateLocation(String? value) {
    final location = (value ?? '').trim();

    if (location.isEmpty) {
      return 'Please enter your location';
    }

    if (location.length < 2) {
      return 'Location must be at least 2 characters long';
    }

    if (location.length > 100) {
      return 'Location must be 100 characters or less';
    }

    return null;
  }

  /// Validates experience years field.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateExperienceYears(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter years of experience';
    }

    final years = int.tryParse(value);
    if (years == null) {
      return 'Please enter a valid number';
    }

    if (years < 0 || years > 50) {
      return 'Experience must be between 0 and 50 years';
    }

    return null;
  }

  /// Validates hourly rate field.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateHourlyRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your hourly rate';
    }

    final rate = double.tryParse(value);
    if (rate == null) {
      return 'Please enter a valid rate';
    }

    if (rate < 0 || rate > 1000) {
      return 'Rate must be between \$0 and \$1000';
    }

    return null;
  }

  /// Validates bio field with character limit.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateBio(String? value, {int maxLength = 500}) {
    if (value != null && value.length > maxLength) {
      return 'Bio must be $maxLength characters or less';
    }
    return null;
  }

  /// Validates certifications field.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateCertifications(String? value, {int maxLength = 1000}) {
    if (value != null && value.length > maxLength) {
      return 'Certifications must be $maxLength characters or less';
    }
    return null;
  }

  /// Validates that at least one item is selected from a list.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateListSelection(List<String>? values, String fieldName) {
    if (values == null || values.isEmpty) {
      return 'Please select at least one $fieldName';
    }
    return null;
  }

  /// Validates that at least one time slot is selected.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateTimeSlots(List<dynamic>? timeSlots) {
    if (timeSlots == null || timeSlots.isEmpty) {
      return 'Please add at least one time slot';
    }
    return null;
  }

  /// Validates a required dropdown selection.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateDropdownSelection(dynamic value, String fieldName) {
    if (value == null) {
      return 'Please select $fieldName';
    }
    return null;
  }

  /// Generic required field validator.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateRequired(String? value, [String? fieldName]) {
    final trimmedValue = (value ?? '').trim();
    if (trimmedValue.isEmpty) {
      return fieldName != null ? 'Please enter $fieldName' : 'This field is required';
    }
    return null;
  }

  /// Validates minimum length requirement.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    final trimmedValue = (value ?? '').trim();
    if (trimmedValue.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    return null;
  }

  /// Validates maximum length requirement.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be $maxLength characters or less';
    }
    return null;
  }
}
