// lib/app/widgets/responsive_layout_builder.dart
import 'package:flutter/material.dart';

class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context) desktop;

  // Define your breakpoints
  // These are common values but can be adjusted to your needs.
  static const double _kTabletBreakpoint = 600.0;
  static const double _kDesktopBreakpoint =
      900.0; // Adjusted from 1200 for more general use

  const ResponsiveLayoutBuilder({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _kTabletBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= _kTabletBreakpoint &&
      MediaQuery.of(context).size.width < _kDesktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _kDesktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= _kDesktopBreakpoint) {
          return desktop(context);
        } else if (constraints.maxWidth >= _kTabletBreakpoint) {
          // If tablet builder is not provided, fallback to mobile or desktop.
          // Common practice is to fallback to mobile if tablet is null,
          // or desktop if you prefer larger layouts on tablet.
          // Here, we'll fallback to mobile if tablet is not provided.
          return tablet != null ? tablet!(context) : mobile(context);
        } else {
          return mobile(context);
        }
      },
    );
  }
}
