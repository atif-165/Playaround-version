import 'package:flutter_test/flutter_test.dart';
import 'package:playaround/presentation/auth/utils/validators.dart';

void main() {
  group('Email validation', () {
    test('returns error when email empty', () {
      expect(validateEmail(''), 'Email is required');
    });

    test('returns error when email invalid', () {
      expect(validateEmail('invalid-email'), 'Enter a valid email');
    });

    test('returns null when email valid', () {
      expect(validateEmail('user@example.com'), isNull);
    });
  });

  group('Password validation', () {
    test('requires minimum length', () {
      expect(
          validatePassword('12345'), 'Password must be at least 8 characters');
    });

    test('enforces strong password when requested', () {
      expect(
        validatePassword('password', requireStrong: true),
        'Include at least one capital letter and number',
      );
    });

    test('accepts strong password', () {
      expect(
        validatePassword('Sample123', requireStrong: true),
        isNull,
      );
    });
  });

  group('Confirm password validation', () {
    test('requires confirmation', () {
      expect(validateConfirmedPassword('', 'Password123'),
          'Confirm your password');
    });

    test('requires matching passwords', () {
      expect(
        validateConfirmedPassword('Password321', 'Password123'),
        'Passwords do not match',
      );
    });

    test('accepts matching passwords', () {
      expect(
        validateConfirmedPassword('Password123', 'Password123'),
        isNull,
      );
    });
  });
}
