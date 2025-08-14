import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive layout system for PlayAround app
/// Provides breakpoints and responsive widgets for different screen sizes

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = getDeviceType(constraints.maxWidth);
        
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
          case DeviceType.largeDesktop:
            return largeDesktop ?? desktop ?? tablet ?? mobile;
        }
      },
    );
  }

  static DeviceType getDeviceType(double width) {
    if (width >= ResponsiveBreakpoints.largeDesktop) {
      return DeviceType.largeDesktop;
    } else if (width >= ResponsiveBreakpoints.desktop) {
      return DeviceType.desktop;
    } else if (width >= ResponsiveBreakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }
}

/// Responsive helper methods
class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile && 
           width < ResponsiveBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  }

  static DeviceType getDeviceType(BuildContext context) {
    return ResponsiveLayout.getDeviceType(MediaQuery.of(context).size.width);
  }

  /// Get responsive value based on device type
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: EdgeInsets.all(16.w),
      tablet: EdgeInsets.all(24.w),
      desktop: EdgeInsets.all(32.w),
    );
  }

  /// Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: EdgeInsets.all(8.w),
      tablet: EdgeInsets.all(12.w),
      desktop: EdgeInsets.all(16.w),
    );
  }

  /// Get responsive grid columns
  static int getGridColumns(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
      largeDesktop: 5,
    );
  }

  /// Get responsive card width
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return getResponsiveValue(
      context: context,
      mobile: screenWidth * 0.9,
      tablet: 300.w,
      desktop: 280.w,
    );
  }

  /// Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
  }
}

/// Responsive grid widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveLayout.getDeviceType(constraints.maxWidth);
        
        int columns;
        switch (deviceType) {
          case DeviceType.mobile:
            columns = mobileColumns ?? 1;
            break;
          case DeviceType.tablet:
            columns = tabletColumns ?? 2;
            break;
          case DeviceType.desktop:
          case DeviceType.largeDesktop:
            columns = desktopColumns ?? 3;
            break;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 1.0,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Responsive wrap widget
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSpacing = ResponsiveHelper.getResponsiveValue(
      context: context,
      mobile: spacing,
      tablet: spacing * 1.2,
      desktop: spacing * 1.5,
    );

    final responsiveRunSpacing = ResponsiveHelper.getResponsiveValue(
      context: context,
      mobile: runSpacing,
      tablet: runSpacing * 1.2,
      desktop: runSpacing * 1.5,
    );

    return Wrap(
      spacing: responsiveSpacing,
      runSpacing: responsiveRunSpacing,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

/// Responsive container with max width
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveMaxWidth = maxWidth ?? ResponsiveHelper.getResponsiveValue<double>(
      context: context,
      mobile: double.infinity,
      tablet: 600.w,
      desktop: 800.w,
      largeDesktop: 1000.w,
    );

    final responsivePadding = padding ?? ResponsiveHelper.getResponsivePadding(context);
    final responsiveMargin = margin ?? ResponsiveHelper.getResponsiveMargin(context);

    return Container(
      width: double.infinity,
      margin: responsiveMargin,
      padding: responsivePadding,
      constraints: BoxConstraints(maxWidth: responsiveMaxWidth),
      child: child,
    );
  }
}

/// Responsive text widget that scales with screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final multiplier = ResponsiveHelper.getFontSizeMultiplier(context);
    final responsiveStyle = style?.copyWith(
      fontSize: (style?.fontSize ?? 14.0) * multiplier,
    );

    return Text(
      text,
      style: responsiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
