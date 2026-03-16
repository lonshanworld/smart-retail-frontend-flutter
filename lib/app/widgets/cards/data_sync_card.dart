import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/services/sync_service.dart';
import 'package:smart_retail/app/services/offline_sales_service.dart';
import 'package:smart_retail/app/services/connectivity_service.dart';
import 'package:smart_retail/app/services/cache_manager_service.dart';
import 'package:smart_retail/app/widgets/dialogs/sync_progress_dialog.dart';
import 'package:smart_retail/app/widgets/dialogs/sync_history_dialog.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class DataSyncCard extends StatelessWidget {
  const DataSyncCard({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = Get.find<SyncService>();
    final offlineSalesService = Get.find<OfflineSalesService>();
    final connectivityService = Get.find<ConnectivityService>();
    final cacheManagerService = Get.find<CacheManagerService>();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cloud_sync,
                    color: Colors.deepPurple,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data & Sync',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Obx(() {
                        return Text(
                          connectivityService.isOnline.value
                              ? 'Online • Ready to sync'
                              : 'Offline • Changes saved locally',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: connectivityService.isOnline.value
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Pending Sales Status
            Obx(() {
              final pending = offlineSalesService.pendingSalesCount.value;
              final hasOfflineSales = pending > 0;

              return Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasOfflineSales
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasOfflineSales
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasOfflineSales ? Icons.schedule : Icons.check_circle,
                      color: hasOfflineSales
                          ? Colors.orange[600]
                          : Colors.green[600],
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasOfflineSales
                                ? '$pending sale${pending != 1 ? 's' : ''} waiting to sync'
                                : 'All data synced',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (hasOfflineSales)
                            Text(
                              'Will sync automatically when connected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                // Manual Sync Button
                Expanded(
                  child: Obx(() {
                    final isOnline = connectivityService.isOnline.value;
                    final isSyncing =
                        syncService.syncStatus.value.toString() ==
                        'SyncStatus.syncing';

                    return ElevatedButton.icon(
                      onPressed: isSyncing || !isOnline
                          ? null
                          : () {
                              _showSyncProgressDialog(context, syncService);
                              syncService.manualSync();
                            },
                      icon: Icon(
                        isSyncing ? Icons.hourglass_empty : Icons.cloud_upload,
                        size: 18,
                      ),
                      label: Text(
                        isSyncing ? 'Syncing...' : 'Sync Now',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  }),
                ),
                SizedBox(width: 8),
                // History Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showSyncHistoryDialog(context, syncService);
                    },
                    icon: Icon(Icons.history, size: 18),
                    label: Text(
                      'History',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: BorderSide(color: Colors.deepPurple),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Cache Status
            FutureBuilder<String>(
              future: cacheManagerService.getCacheSize(),
              builder: (context, snapshot) {
                final cacheSize = snapshot.data ?? '0 MB';

                return Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cache Storage',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            cacheSize,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Clear Cache?'),
                              content: Text(
                                'This will delete cached products and promotions. They will be redownloaded when you next sync.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmed ?? false) {
                            await cacheManagerService.clearAllCache();
                            DialogUtils.showInfo('Cache has been cleared successfully');
                          }
                        },
                        icon: Icon(Icons.delete_outline, size: 16),
                        label: Text('Clear', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 16),

            // Info Section
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'When offline, all sales are saved locally and will sync automatically once you reconnect.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncProgressDialog(BuildContext context, SyncService syncService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SyncProgressDialog(syncService: syncService),
    );
  }

  void _showSyncHistoryDialog(BuildContext context, SyncService syncService) {
    showDialog(
      context: context,
      builder: (context) => SyncHistoryDialog(syncService: syncService),
    );
  }
}
