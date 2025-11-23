import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/models/sync_models.dart';
import 'package:smart_retail/app/services/sync_service.dart';

class SyncProgressDialog extends StatelessWidget {
  final SyncService syncService;

  const SyncProgressDialog({Key? key, required this.syncService})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.deepPurple,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Syncing Data',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Status Message
            Obx(() {
              final widgets = <Widget>[];
              if (syncService.syncStatus.value == SyncStatus.syncing) {
                widgets.add(
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ),
                  ),
                );
              } else if (syncService.syncStatus.value == SyncStatus.success) {
                widgets.add(
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                );
              } else if (syncService.syncStatus.value == SyncStatus.error) {
                widgets.add(
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error, color: Colors.red, size: 40),
                  ),
                );
              }

              widgets.addAll([
                SizedBox(height: 16),
                Text(
                  syncService.lastSyncMessage.value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ]);

              return Column(children: widgets);
            }),

            SizedBox(height: 24),

            // Progress Details
            Obx(() {
              if (syncService.syncStatus.value == SyncStatus.syncing) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Syncing...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${syncService.syncedCount.value}/${syncService.pendingSalesCount.value}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: syncService.pendingSalesCount.value > 0
                            ? syncService.syncedCount.value /
                                  syncService.pendingSalesCount.value
                            : 0,
                        minHeight: 6,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                );
              } else if (syncService.syncStatus.value == SyncStatus.success) {
                return Column(
                  children: [
                    Text(
                      '✓ ${syncService.syncedCount.value} sales synced successfully',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (syncService.failedCount.value > 0) ...[
                      SizedBox(height: 8),
                      Text(
                        '✗ ${syncService.failedCount.value} sales failed (will retry later)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                );
              } else if (syncService.syncStatus.value == SyncStatus.error) {
                return Text(
                  '✗ Sync failed - will retry when connection improves',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return SizedBox.shrink();
            }),

            SizedBox(height: 24),

            // Close Button
            Obx(() {
              if (syncService.syncStatus.value != SyncStatus.syncing) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}
