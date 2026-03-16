import 'package:flutter/material.dart';

/// Modern card widget with consistent styling
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.onTap,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: elevation != null ? elevation! * 0.02 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: content,
        ),
      );
    }

    return Container(margin: margin, child: content);
  }
}
