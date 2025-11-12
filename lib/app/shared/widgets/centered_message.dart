// lib/app/shared/widgets/centered_message.dart
import 'package:flutter/material.dart';

class CenteredMessage extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String retryText;

  const CenteredMessage({
    Key? key,
    required this.message,
    this.icon,
    this.onRetry,
    this.retryText = 'Try Again',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...[
              Icon(
                icon,
                size: 60,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
