import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theming/colors.dart';

/// Utility class for safe image loading and validation
class ImageUtils {
  /// Validates if a URL is a valid image URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    // Check if it's a valid URL format
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme ||
          (!uri.scheme.startsWith('http') && !uri.scheme.startsWith('https'))) {
        return false;
      }

      // Check if it has a valid image extension or is from known image services
      final path = uri.path.toLowerCase();
      final validExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.bmp'
      ];
      final isValidExtension = validExtensions.any((ext) => path.endsWith(ext));

      // Check for known image hosting services
      final knownImageHosts = [
        'cloudinary.com',
        'firebase.com',
        'firebasestorage.googleapis.com',
        'googleusercontent.com',
        'imgur.com',
        'unsplash.com',
      ];
      final isKnownHost =
          knownImageHosts.any((host) => uri.host.contains(host));

      return isValidExtension || isKnownHost;
    } catch (e) {
      return false;
    }
  }

  /// Creates a safe CachedNetworkImage widget with proper error handling
  static Widget buildSafeCachedImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
    IconData fallbackIcon = Icons.image,
    Color? fallbackIconColor,
    double? fallbackIconSize,
    Color? backgroundColor,
  }) {
    // If URL is invalid, return fallback immediately
    if (!isValidImageUrl(imageUrl)) {
      return _buildFallbackWidget(
        width: width,
        height: height,
        borderRadius: borderRadius,
        fallbackIcon: fallbackIcon,
        fallbackIconColor: fallbackIconColor,
        fallbackIconSize: fallbackIconSize,
        backgroundColor: backgroundColor,
      );
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder:
          placeholder ?? (context, url) => _buildPlaceholder(width, height),
      errorWidget: errorWidget ??
          (context, url, error) => _buildFallbackWidget(
                width: width,
                height: height,
                borderRadius: borderRadius,
                fallbackIcon: fallbackIcon,
                fallbackIconColor: fallbackIconColor,
                fallbackIconSize: fallbackIconSize,
                backgroundColor: backgroundColor,
              ),
    );

    // Apply border radius if provided
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Creates a safe CircleAvatar with proper image validation
  static Widget buildSafeCircleAvatar({
    required String? imageUrl,
    required double radius,
    Color? backgroundColor,
    Widget? child,
    String? fallbackText,
    Color? fallbackTextColor,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? ColorsManager.gray93Color,
      backgroundImage: isValidImageUrl(imageUrl)
          ? CachedNetworkImageProvider(imageUrl!)
          : null,
      child: !isValidImageUrl(imageUrl)
          ? (child ??
              _buildAvatarFallback(fallbackText, fallbackTextColor, radius))
          : null,
    );
  }

  /// Builds a placeholder widget for loading state
  static Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: ColorsManager.gray93Color,
      child: Center(
        child: CircularProgressIndicator(
          color: ColorsManager.mainBlue,
          strokeWidth: 2.w,
        ),
      ),
    );
  }

  /// Builds a fallback widget for error/invalid URL state
  static Widget _buildFallbackWidget({
    double? width,
    double? height,
    BorderRadius? borderRadius,
    IconData fallbackIcon = Icons.image,
    Color? fallbackIconColor,
    double? fallbackIconSize,
    Color? backgroundColor,
  }) {
    Widget fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? ColorsManager.gray93Color,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: fallbackIconColor ?? ColorsManager.gray,
          size: fallbackIconSize ?? (width != null ? width * 0.3 : 24.w),
        ),
      ),
    );

    return fallback;
  }

  /// Builds a fallback for avatar (initials or icon)
  static Widget _buildAvatarFallback(
      String? fallbackText, Color? textColor, double radius) {
    if (fallbackText != null && fallbackText.isNotEmpty) {
      return Text(
        fallbackText.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: textColor ?? ColorsManager.mainBlue,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Icon(
      Icons.person,
      color: textColor ?? ColorsManager.mainBlue,
      size: radius * 0.8,
    );
  }

  /// Gets initials from a full name
  static String getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '';

    final names = fullName.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    } else {
      return '${names[0].substring(0, 1)}${names[names.length - 1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  /// Sanitizes image URL to prevent empty string issues
  static String? sanitizeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    return url.trim();
  }
}
