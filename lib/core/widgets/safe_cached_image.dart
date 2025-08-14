import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

/// A safe wrapper around CachedNetworkImage that handles null and empty URLs
class SafeCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;
  final double? fallbackIconSize;
  final Color? backgroundColor;

  const SafeCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fallbackIcon = Icons.image,
    this.fallbackIconColor,
    this.fallbackIconSize,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ImageUtils.buildSafeCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fallbackIcon: fallbackIcon,
      fallbackIconColor: fallbackIconColor,
      fallbackIconSize: fallbackIconSize,
      backgroundColor: backgroundColor,
    );
  }
}
