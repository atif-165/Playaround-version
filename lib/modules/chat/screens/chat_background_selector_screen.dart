import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../services/cloudinary_service.dart';
import '../models/chat_background.dart';
import '../services/chat_background_service.dart';

class ChatAppearanceSelection {
  final ChatBackground background;
  final ChatBubbleColors bubbleColors;

  const ChatAppearanceSelection({
    required this.background,
    required this.bubbleColors,
  });
}

/// Screen for selecting chat background
class ChatBackgroundSelectorScreen extends StatefulWidget {
  final ChatBackground currentBackground;
  final ChatBubbleColors bubbleColors;
  final String chatId;

  const ChatBackgroundSelectorScreen({
    super.key,
    required this.currentBackground,
    required this.bubbleColors,
    required this.chatId,
  });

  @override
  State<ChatBackgroundSelectorScreen> createState() =>
      _ChatBackgroundSelectorScreenState();
}

class _ChatBackgroundSelectorScreenState
    extends State<ChatBackgroundSelectorScreen> {
  final ChatBackgroundService _backgroundService = ChatBackgroundService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();
  late ChatBackground _selectedBackground;
  late ChatBubbleColors _selectedBubbleColors;
  bool _isSaving = false;
  bool _isUploading = false;

  static const LinearGradient _pageBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1B1848),
      Color(0xFF080612),
    ],
  );

  static const List<Color> _bubblePalette = [
    Color(0xFFFFC56F),
    Color(0xFFFF6B6B),
    Color(0xFFFF8A65),
    Color(0xFFFFC107),
    Color(0xFF4DD0E1),
    Color(0xFF64B5F6),
    Color(0xFF9575CD),
    Color(0xFF81C784),
    Color(0xFF4DB6AC),
    Color(0xFFBA68C8),
    Color(0xFF212121),
    Color(0xFF37474F),
    Color(0xFF1C1A3C),
    Color(0xFF607D8B),
    Color(0xFFFAF3DD),
    Color(0xFFF4F1DE),
  ];

  @override
  void initState() {
    super.initState();
    _selectedBackground = widget.currentBackground;
    _selectedBubbleColors = widget.bubbleColors;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: _pageBackgroundGradient,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Gap(12.h),
                  _buildPreviewSection(),
                  Gap(24.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildSectionHeading(
                      title: 'Pick a style',
                      subtitle:
                          'Choose from curated gradients, solid colors, or patterns.',
                    ),
                  ),
                  Gap(12.h),
                  _buildBackgroundGrid(),
                Gap(24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildBubbleColorSection(),
                ),
                  Gap(24.h),
                  _buildSaveButton(),
                  Gap(20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 12.w, top: 4.h),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'Live preview',
            subtitle: 'See how your chat looks with this background.',
          ),
          Gap(12.h),
          AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.r),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildBackgroundPreview(_selectedBackground),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.15),
                            Colors.black.withOpacity(0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedBackground.name,
                                  style:
                                      TextStyles.font12Grey400Weight.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            _buildPreviewBubble(
                              alignment: Alignment.centerLeft,
                              isOutgoing: false,
                              text: 'Looks great! ⚡️',
                            ),
                            Gap(10.h),
                            _buildPreviewBubble(
                              alignment: Alignment.centerRight,
                              isOutgoing: true,
                              text: 'Let’s lock this background in.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(6.h),
        Text(
          subtitle,
          style: TextStyles.font12Grey400Weight.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewBubble({
    required Alignment alignment,
    required bool isOutgoing,
    required String text,
  }) {
    final bubbleColor = isOutgoing
        ? _selectedBubbleColors.outgoing
        : _selectedBubbleColors.incoming;
    final brightness =
        ThemeData.estimateBrightnessForColor(bubbleColor);
    final textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black87;
    final secondaryColor =
        brightness == Brightness.dark ? Colors.white70 : Colors.black45;

    return Align(
      alignment: alignment,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: bubbleColor,
          border: Border.all(color: secondaryColor.withOpacity(0.25)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomLeft: Radius.circular(isOutgoing ? 18.r : 4.r),
            bottomRight: Radius.circular(isOutgoing ? 4.r : 18.r),
          ),
        ),
        child: Text(
          text,
          style: TextStyles.font12DarkBlue400Weight.copyWith(
            color: textColor,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.82,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
        ),
        itemCount:
            ChatBackgrounds.all.length + 1, // +1 for custom upload option
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCustomUploadCard();
          }

          final background = ChatBackgrounds.all[index - 1];
          final isSelected = _selectedBackground.id == background.id;

          return _buildBackgroundCard(background, isSelected);
        },
      ),
    );
  }

  Widget _buildBubbleColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          title: 'Message bubbles',
          subtitle: 'Set colours for your sent and received messages.',
        ),
        Gap(16.h),
        _buildColorPickerRow(
          label: 'Sent messages',
          selectedColor: _selectedBubbleColors.outgoing,
          onSelected: (color) => setState(() {
            _selectedBubbleColors =
                _selectedBubbleColors.copyWith(outgoing: color);
          }),
        ),
        Gap(20.h),
        _buildColorPickerRow(
          label: 'Received messages',
          selectedColor: _selectedBubbleColors.incoming,
          onSelected: (color) => setState(() {
            _selectedBubbleColors =
                _selectedBubbleColors.copyWith(incoming: color);
          }),
        ),
        Gap(16.h),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _isUsingDefaultBubbleColors
                ? null
                : () => setState(
                      () => _selectedBubbleColors =
                          ChatBubbleColors.defaults,
                    ),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset to defaults'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPickerRow({
    required String label,
    required Color selectedColor,
    required ValueChanged<Color> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.font14DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(10.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: _bubblePalette
              .map(
                (color) => _buildColorChip(
                  color: color,
                  isSelected: color.value == selectedColor.value,
                  onSelected: () => onSelected(color),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildColorChip({
    required Color color,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.25),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: isSelected ? 10 : 6,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              )
            : null,
      ),
    );
  }

  bool get _isUsingDefaultBubbleColors =>
      _selectedBubbleColors.outgoing.value ==
          ChatBubbleColors.defaults.outgoing.value &&
      _selectedBubbleColors.incoming.value ==
          ChatBubbleColors.defaults.incoming.value;

  Widget _buildSaveButton() {
    final backgroundChanged =
        _selectedBackground.id != widget.currentBackground.id ||
            _selectedBackground.imageUrl !=
                widget.currentBackground.imageUrl;
    final bubbleChanged = _selectedBubbleColors.outgoing.value !=
            widget.bubbleColors.outgoing.value ||
        _selectedBubbleColors.incoming.value !=
            widget.bubbleColors.incoming.value;
    final canSave = backgroundChanged || bubbleChanged;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: ElevatedButton(
          onPressed: (!_isSaving && canSave) ? _saveBackground : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            backgroundColor: ColorsManager.primary,
            disabledBackgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: ColorsManager.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSaving
                ? SizedBox(
                    key: const ValueKey('saving'),
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    key: const ValueKey('save'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 18.sp),
                      Gap(8.w),
                      Text(
                        canSave ? 'Apply changes' : 'No changes yet',
                        style: TextStyles.font14DarkBlue600Weight.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomUploadCard() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadImage,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: ColorsManager.primary,
            width: 2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorsManager.primary.withValues(alpha: 0.2),
              ColorsManager.primary.withValues(alpha: 0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.primary.withValues(alpha: 0.3),
              blurRadius: 12.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            children: [
              // Background
              Positioned.fill(
                child: Container(
                  color: ColorsManager.surface,
                ),
              ),

              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isUploading)
                      Column(
                        children: [
                          SizedBox(
                            width: 40.w,
                            height: 40.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: ColorsManager.primary,
                            ),
                          ),
                          Gap(12.h),
                          Text(
                            'Uploading...',
                            style: TextStyles.font14DarkBlue600Weight.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              gradient: ColorsManager.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_photo_alternate,
                              color: Colors.white,
                              size: 36.sp,
                            ),
                          ),
                          Gap(12.h),
                          Text(
                            'Upload Custom',
                            style: TextStyles.font14DarkBlue600Weight.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Gap(4.h),
                          Text(
                            'From Gallery',
                            style: TextStyles.font12Grey400Weight.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Premium badge
              if (!_isUploading)
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: ColorsManager.primaryGradient,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'CUSTOM',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundCard(ChatBackground background, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBackground = background;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? ColorsManager.primary
                : Colors.white.withOpacity(0.15),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ColorsManager.primary.withValues(alpha: 0.35)
                  : Colors.black.withOpacity(0.15),
              blurRadius: isSelected ? 12.r : 8.r,
              offset: Offset(0, isSelected ? 6.h : 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            children: [
              // Background preview
              Positioned.fill(
                child: _buildBackgroundPreview(background),
              ),

              // Label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        background.name,
                        style: TextStyles.font14DarkBlue600Weight.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Gap(4.h),
                      Text(
                        _getBackgroundTypeLabel(background.type),
                        style: TextStyles.font12Grey400Weight.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Selected indicator
              if (isSelected)
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColorsManager.primary.withValues(alpha: 0.5),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundPreview(ChatBackground background) {
    Widget baseWidget;

    switch (background.type) {
      case ChatBackgroundType.solid:
        baseWidget = Container(
          color: background.solidColor,
        );
        break;

      case ChatBackgroundType.gradient:
        baseWidget = Container(
          decoration: BoxDecoration(
            gradient: background.gradient,
          ),
        );
        break;

      case ChatBackgroundType.pattern:
        baseWidget = Container(
          color: background.solidColor,
          child: _buildPattern(background.id),
        );
        break;

      case ChatBackgroundType.customImage:
        if (background.imageUrl != null && background.imageUrl!.isNotEmpty) {
          baseWidget = Image.network(
            background.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: ColorsManager.surface,
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 32.sp,
                ),
              ),
            ),
          );
        } else {
          baseWidget = Container(color: ColorsManager.surface);
        }
        break;
    }

    // Add sample message bubbles for preview
    return Stack(
      children: [
        baseWidget,
        // Sample messages for preview
        Positioned(
          top: 40.h,
          left: 12.w,
          right: 60.w,
          child: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: ColorsManager.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Hey!',
              style: TextStyles.font12Grey400Weight.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          top: 85.h,
          right: 12.w,
          left: 60.w,
          child: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: ColorsManager.primaryGradient,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Hello!',
              style: TextStyles.font12Grey400Weight.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPattern(String patternId) {
    if (patternId == 'dots') {
      return CustomPaint(
        painter: DotPatternPainter(),
        child: Container(),
      );
    } else if (patternId == 'grid') {
      return CustomPaint(
        painter: GridPatternPainter(),
        child: Container(),
      );
    }
    return Container();
  }

  String _getBackgroundTypeLabel(ChatBackgroundType type) {
    switch (type) {
      case ChatBackgroundType.solid:
        return 'Solid Color';
      case ChatBackgroundType.gradient:
        return 'Gradient';
      case ChatBackgroundType.pattern:
        return 'Pattern';
      case ChatBackgroundType.customImage:
        return 'Custom Image';
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload to Cloudinary
      final imageUrl = await _cloudinaryService.uploadImage(
        File(image.path),
        folder: 'chat_backgrounds',
      );

      if (mounted) {
        // Create custom background
        final customBackground = ChatBackground(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Custom Wallpaper',
          type: ChatBackgroundType.customImage,
          imageUrl: imageUrl,
          textColor: Colors.white,
        );

        setState(() {
          _selectedBackground = customBackground;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Custom wallpaper added. Tap "Apply changes" to confirm.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: ColorsManager.coralRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveBackground() async {
    setState(() {
      _isSaving = true;
    });

    final backgroundSuccess = await _backgroundService.saveBackgroundForChat(
      widget.chatId,
      _selectedBackground,
    );
    final bubbleSuccess = await _backgroundService.saveBubbleColors(
      widget.chatId,
      _selectedBubbleColors,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (backgroundSuccess && bubbleSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Chat appearance updated for ${_selectedBackground.name}.'),
            backgroundColor: ColorsManager.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(
          ChatAppearanceSelection(
            background: _selectedBackground,
            bubbleColors: _selectedBubbleColors,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save chat appearance. Please try again.'),
            backgroundColor: ColorsManager.coralRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Custom painter for dot pattern
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const dotRadius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for grid pattern
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
