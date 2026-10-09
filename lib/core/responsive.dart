import 'package:flutter/material.dart';

/// Centralized responsive layout constants and helper utilities.
class Responsive {
  static const double mobileBreakpoint = 960.0;
  static const double largeDesktopBreakpoint = 1360.0;
  static const double maxContentWidth = 1440.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < largeDesktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= largeDesktopBreakpoint;

  /// Returns one value on mobile and another on desktop.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    required T desktop,
    T? tablet,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeDesktopBreakpoint) return desktop;
    if (width >= mobileBreakpoint) return tablet ?? desktop;
    return mobile;
  }
}

/// Extension on [BuildContext] for quick access to responsive flags.
extension ResponsiveContext on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isLargeDesktop => Responsive.isLargeDesktop(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}

/// Reusable widget builder that automatically adapts between mobile and desktop trees.
class ResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder desktop;
  final WidgetBuilder? tablet;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      if (Responsive.isTablet(context) && tablet != null) {
        return tablet!(context);
      }
      return desktop(context);
    }
    return mobile(context);
  }
}

/// Container that limits max width for widescreen desktop displays and centers content.
class DesktopMaxContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const DesktopMaxContainer({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
