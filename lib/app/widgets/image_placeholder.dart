import 'package:flutter/material.dart';

class ImagePlaceholder extends StatelessWidget {
  final IconData iconData;
  final double? size;
  final Color? color;

  const ImagePlaceholder({
    super.key,
    this.iconData = Icons.image_not_supported, // Default icon
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
    
      width: size ?? 60, // Match ListTile leading size or allow override
      height: size ?? 60,
      child: Center(
        child: Icon(
          iconData,
          size: (size ?? 60) * 0.6, // Icon size relative to placeholder size
          color:
              color ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
