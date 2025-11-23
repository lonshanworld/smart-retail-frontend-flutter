import 'package:flutter/material.dart';
// import 'package:get/get.dart'; // No longer needed for GetBuilder here

class GlobalThemeToggleWrapper extends StatelessWidget {
  final Widget? child;

  const GlobalThemeToggleWrapper({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    // If a child is provided, return it, otherwise return an empty widget.
    // The Stack and Positioned FAB are removed.
    return child ?? const SizedBox.shrink();
  }
}
