String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  final trimmed = value.trim();
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(trimmed)) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePassword(
  String? value, {
  bool requireStrong = false,
}) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  if (requireStrong) {
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one capital letter and number';
    }
  }
  return null;
}

String? validateConfirmedPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Confirm your password';
  }
  if (value != password) {
    return 'Passwords do not match';
  }
  return null;
}
