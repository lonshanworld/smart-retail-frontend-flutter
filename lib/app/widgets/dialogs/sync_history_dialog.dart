import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/models/sync_models.dart';
import 'package:smart_retail/app/services/sync_service.dart';
import 'package:intl/intl.dart';

class SyncHistoryDialog extends StatelessWidget {
  final SyncService syncService;

  const SyncHistoryDialog({Key? key, required this.syncService})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Obx(() {
                        final lastSync = syncService.lastSyncTime.value;
                        if (lastSync != null) {
                          final formatter = DateFormat(
                            'MMM dd, yyyy - hh:mm a',
                          );
                          return Text(
                            'Last sync: ${formatter.format(lastSync)}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          );
                        }
                        return Text(
                          'No sync history',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        );
                      }),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: Obx(() {
              final history = syncService.syncHistory.value;

              if (history.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text(
                          'No sync history yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final log = history[index];
                  final formatter = DateFormat('hh:mm a');
                  final isSuccess = log.status == 'success';
                  final statusColor = isSuccess ? Colors.green : Colors.red;
                  final statusIcon = isSuccess
                      ? Icons.check_circle
                      : Icons.error;

                  return ListTile(
                    leading: Icon(statusIcon, color: statusColor),
                    title: Text(
                      isSuccess ? 'Synced successfully' : 'Sync failed',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          '${log.entityType} - ${log.action}',
                          style: TextStyle(fontSize: 12),
                        ),
                        if (log.errorMessage != null &&
                            log.errorMessage!.isNotEmpty)
                          Text(
                            log.errorMessage!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red[400],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing: Text(
                      formatter.format(log.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  );
                },
              );
            }),
          ),

          // Footer with Close Button
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
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
            ),
          ),
        ],
      ),
    );
  }
}
