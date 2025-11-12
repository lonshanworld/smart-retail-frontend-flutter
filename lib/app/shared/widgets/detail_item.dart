// lib/app/shared/widgets/detail_item.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Using Get for theme access convenience

class DetailItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color? valueColor;
  final int valueMaxLines;
  final bool isSelectable;

  const DetailItem({
    Key? key,
    this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueMaxLines = 2,
    this.isSelectable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...[
            Icon(icon, size: 20.0, color: Get.theme.colorScheme.primary),
            const SizedBox(width: 12.0),
          ] else ...[
            const SizedBox(width: 32.0), // Placeholder for alignment if no icon
          ],
          Expanded(
            flex: 2, // Give more space to label
            child: Text(
              '$label:',
              style: Get.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Get.textTheme.bodySmall?.color?.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            flex: 3, // Give more space to value
            child: isSelectable
                ? SelectableText(
                    value,
                    style: Get.textTheme.bodyMedium?.copyWith(color: valueColor),
                    maxLines: valueMaxLines,
                  )
                : Text(
                    value,
                    style: Get.textTheme.bodyMedium?.copyWith(color: valueColor),
                    maxLines: valueMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}
