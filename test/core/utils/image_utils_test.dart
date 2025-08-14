import 'package:flutter_test/flutter_test.dart';
import 'package:playaround/core/utils/image_utils.dart';

void main() {
  group('ImageUtils', () {
    group('isValidImageUrl', () {
      test('should return false for null URL', () {
        expect(ImageUtils.isValidImageUrl(null), false);
      });

      test('should return false for empty URL', () {
        expect(ImageUtils.isValidImageUrl(''), false);
      });

      test('should return false for whitespace-only URL', () {
        expect(ImageUtils.isValidImageUrl('   '), false);
      });

      test('should return false for invalid URL format', () {
        expect(ImageUtils.isValidImageUrl('not-a-url'), false);
      });

      test('should return false for non-http(s) URLs', () {
        expect(ImageUtils.isValidImageUrl('ftp://example.com/image.jpg'), false);
      });

      test('should return true for valid image URLs with extensions', () {
        expect(ImageUtils.isValidImageUrl('https://example.com/image.jpg'), true);
        expect(ImageUtils.isValidImageUrl('https://example.com/image.png'), true);
        expect(ImageUtils.isValidImageUrl('http://example.com/image.gif'), true);
      });

      test('should return true for known image hosting services', () {
        expect(ImageUtils.isValidImageUrl('https://res.cloudinary.com/demo/image/upload/sample.jpg'), true);
        expect(ImageUtils.isValidImageUrl('https://firebasestorage.googleapis.com/v0/b/project/o/image'), true);
        expect(ImageUtils.isValidImageUrl('https://lh3.googleusercontent.com/profile-pic'), true);
      });
    });

    group('sanitizeImageUrl', () {
      test('should return null for null input', () {
        expect(ImageUtils.sanitizeImageUrl(null), null);
      });

      test('should return null for empty string', () {
        expect(ImageUtils.sanitizeImageUrl(''), null);
      });

      test('should return null for whitespace-only string', () {
        expect(ImageUtils.sanitizeImageUrl('   '), null);
      });

      test('should trim whitespace from valid URLs', () {
        expect(ImageUtils.sanitizeImageUrl('  https://example.com/image.jpg  '), 
               'https://example.com/image.jpg');
      });
    });

    group('getInitials', () {
      test('should return empty string for null input', () {
        expect(ImageUtils.getInitials(null), '');
      });

      test('should return empty string for empty input', () {
        expect(ImageUtils.getInitials(''), '');
      });

      test('should return first letter for single name', () {
        expect(ImageUtils.getInitials('John'), 'J');
      });

      test('should return first and last initials for multiple names', () {
        expect(ImageUtils.getInitials('John Doe'), 'JD');
        expect(ImageUtils.getInitials('John Michael Doe'), 'JD');
      });

      test('should handle names with extra whitespace', () {
        expect(ImageUtils.getInitials('  John   Doe  '), 'JD');
      });
    });
  });
}
