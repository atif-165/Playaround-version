/// Cloudinary configuration constants
class CloudinaryConfig {
  // Your Cloudinary credentials - CORRECTED CLOUD NAME
  static const String cloudName = 'dlt281zr0'; // Your Cloud Name (corrected)
  static const String apiKey = '318776545529666'; // Your API Key
  static const String apiSecret = 'KYgrithib67nTQ67oYBYbZw2upU'; // Your API Secret
  
  // Upload settings
  static const String profileImagesFolder = 'profile_images';
  static const String uploadPreset = 'profile_images_preset'; // Add this when you create the preset
  static const int maxImageWidth = 512;
  static const int maxImageHeight = 512;
  static const String cropMode = 'fill';
  static const String quality = 'auto';
  static const String format = 'auto';
  
  // Thumbnail settings
  static const int defaultThumbnailSize = 150;
  static const int profilePictureSize = 116;
}
