import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/foundation.dart';

import '../config/cloudinary_config.dart';

/// Service class for handling image uploads to Cloudinary
class CloudinaryService {
  late final Cloudinary _cloudinary;

  CloudinaryService() {
    // Use signed config - required by the Flutter package even for unsigned presets
    _cloudinary = Cloudinary.signedConfig(
      apiKey: CloudinaryConfig.apiKey,
      apiSecret: CloudinaryConfig.apiSecret,
      cloudName: CloudinaryConfig.cloudName,
    );
  }

  /// Upload image to Cloudinary
  ///
  /// [imageFile] - The image file to upload
  /// [folder] - The folder to upload to (optional)
  ///
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting Cloudinary upload');
        debugPrint('📁 Image file path: ${imageFile.path}');
        debugPrint('📏 Image file size: ${imageFile.lengthSync()} bytes');
      }

      // Verify file exists and is readable
      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }

      // Use upload preset approach (unsigned upload with preset)
      final response = await _cloudinary.upload(
        file: imageFile.path,
        fileBytes: imageFile.readAsBytesSync(),
        resourceType: CloudinaryResourceType.image,
        optParams: {
          'upload_preset': CloudinaryConfig.uploadPreset,
          if (folder != null) 'folder': folder,
        },
      );

      if (response.isSuccessful) {
        final imageUrl = response.secureUrl!;

        if (kDebugMode) {
          debugPrint('✅ Cloudinary upload successful!');
          debugPrint('🔗 Image URL: $imageUrl');
        }

        return imageUrl;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Cloudinary upload failed!');
          debugPrint('🚫 Error: ${response.error}');
        }
        throw Exception('Failed to upload image: ${response.error}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Exception during Cloudinary upload: $e');
      }
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Upload profile image to Cloudinary
  ///
  /// [imageFile] - The image file to upload
  /// [userId] - The user ID to use in the public ID for organization
  ///
  /// Returns the secure URL of the uploaded image
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting Cloudinary upload for user: $userId');
        debugPrint('📁 Image file path: ${imageFile.path}');
        debugPrint('📏 Image file size: ${imageFile.lengthSync()} bytes');
      }

      // Verify file exists and is readable
      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }

      if (kDebugMode) {
        debugPrint('🔧 Upload parameters (SIGNED CONFIG + UNSIGNED PRESET):');
        debugPrint('   - Cloud Name: ${CloudinaryConfig.cloudName}');
        debugPrint('   - API Key: ${CloudinaryConfig.apiKey}');
        debugPrint('   - API Secret: ${CloudinaryConfig.apiSecret.substring(0, 5)}...');
        debugPrint('   - Upload Preset: ${CloudinaryConfig.uploadPreset} (unsigned preset)');
        debugPrint('   - File path: ${imageFile.path}');
        debugPrint('   - File size: ${imageFile.lengthSync()} bytes');
        debugPrint('   - Target Folder: ${CloudinaryConfig.profileImagesFolder}');
      }

      // Use upload preset approach (unsigned upload with preset)
      final response = await _cloudinary.upload(
        file: imageFile.path,
        fileBytes: imageFile.readAsBytesSync(),
        resourceType: CloudinaryResourceType.image,
        optParams: {
          'upload_preset': CloudinaryConfig.uploadPreset,
        },
      );

      if (response.isSuccessful) {
        final imageUrl = response.secureUrl!;

        if (kDebugMode) {
          debugPrint('✅ Cloudinary upload successful!');
          debugPrint('🔗 Image URL: $imageUrl');
          debugPrint('📊 Response successful: ${response.isSuccessful}');
        }

        return imageUrl;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Cloudinary upload failed!');
          debugPrint('🚫 Error: ${response.error}');
          debugPrint('📊 Response successful: ${response.isSuccessful}');
          debugPrint('📋 Full response: ${response.toString()}');
          // Remove .data as it's not available on CloudinaryResponse
        }
        throw Exception('Failed to upload image: ${response.error}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Exception during Cloudinary upload: $e');
        debugPrint('📍 Exception type: ${e.runtimeType}');
        debugPrint('📍 Stack trace: ${StackTrace.current}');

        // Check for specific error types
        if (e.toString().contains('401')) {
          debugPrint('');
          debugPrint('🔍 401 UNAUTHORIZED ERROR DETECTED');
          debugPrint('Possible causes:');
          debugPrint('1. Invalid API credentials');
          debugPrint('2. Account restrictions or limits exceeded');
          debugPrint('3. Unsigned upload not allowed');
          debugPrint('4. Invalid transformation parameters');
          debugPrint('');
          debugPrint('Current credentials:');
          debugPrint('- Cloud Name: ${CloudinaryConfig.cloudName}');
          debugPrint('- API Key: ${CloudinaryConfig.apiKey}');
          debugPrint('- API Secret: ${CloudinaryConfig.apiSecret.substring(0, 5)}...');
        }
      }
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Delete profile image from Cloudinary
  /// 
  /// [imageUrl] - The URL of the image to delete
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract public ID from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the public ID (usually after 'upload' and version)
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex + 2 < pathSegments.length) {
        // Skip version if present (starts with 'v')
        int publicIdIndex = uploadIndex + 1;
        if (pathSegments[publicIdIndex].startsWith('v')) {
          publicIdIndex++;
        }
        
        // Reconstruct public ID from remaining segments
        final publicIdParts = pathSegments.sublist(publicIdIndex);
        final publicId = publicIdParts.join('/').replaceAll(RegExp(r'\.[^.]+$'), ''); // Remove file extension
        
        if (kDebugMode) {
          debugPrint('Attempting to delete Cloudinary image with public ID: $publicId');
        }

        final response = await _cloudinary.destroy(publicId);
        
        if (response.isSuccessful) {
          if (kDebugMode) {
            debugPrint('Cloudinary image deleted successfully');
          }
        } else {
          if (kDebugMode) {
            debugPrint('Failed to delete Cloudinary image: ${response.error}');
          }
          // Don't throw error for deletion failures as it's not critical
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting Cloudinary image: $e');
      }
      // Don't throw error for deletion failures as it's not critical
    }
  }

  /// Generate a transformation URL for displaying images with specific dimensions
  /// 
  /// [imageUrl] - The original Cloudinary URL
  /// [width] - Desired width
  /// [height] - Desired height
  /// [crop] - Crop mode (default: 'fill')
  /// 
  /// Returns the transformed URL
  String getTransformedImageUrl(
    String imageUrl, {
    int? width,
    int? height,
    String crop = 'fill',
    String quality = 'auto',
    String format = 'auto',
  }) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments.toList();
      
      // Find upload segment
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return imageUrl;
      
      // Build transformation string
      List<String> transformations = [];
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      transformations.add('c_$crop');
      transformations.add('q_$quality');
      transformations.add('f_$format');
      
      final transformationString = transformations.join(',');
      
      // Insert transformation after 'upload'
      pathSegments.insert(uploadIndex + 1, transformationString);
      
      // Rebuild URL
      final newUri = uri.replace(pathSegments: pathSegments);
      return newUri.toString();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating transformed URL: $e');
      }
      return imageUrl; // Return original URL if transformation fails
    }
  }

  /// Get optimized thumbnail URL for profile pictures
  ///
  /// [imageUrl] - The original Cloudinary URL
  /// [size] - The desired size (width and height will be the same)
  ///
  /// Returns the optimized thumbnail URL
  String getProfileThumbnail(String imageUrl, {int? size}) {
    final thumbnailSize = size ?? CloudinaryConfig.defaultThumbnailSize;
    return getTransformedImageUrl(
      imageUrl,
      width: thumbnailSize,
      height: thumbnailSize,
      crop: CloudinaryConfig.cropMode,
      quality: CloudinaryConfig.quality,
      format: CloudinaryConfig.format,
    );
  }
}
