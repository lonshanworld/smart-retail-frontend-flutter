import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/services/connectivity_service.dart';
import 'package:smart_retail/app/services/offline_sales_service.dart';

/// A badge widget that displays the current online/offline status
/// and the number of pending sales waiting to sync
class OfflineStatusBadge extends StatelessWidget {
  final bool showPendingCount;
  final double size;

  const OfflineStatusBadge({
    super.key,
    this.showPendingCount = true,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();
    final offlineSalesService = Get.find<OfflineSalesService>();

    return Obx(() {
      final isOnline = connectivityService.isOnline.value;
      final pendingCount = offlineSalesService.totalPendingCount.value;

      if (isOnline && pendingCount == 0) {
        // All synced, no badge needed
        return const SizedBox.shrink();
      }

      return Tooltip(
        message: isOnline
            ? '$pendingCount sale${pendingCount != 1 ? 's' : ''} syncing...'
            : '$pendingCount sale${pendingCount != 1 ? 's' : ''} offline',
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.orange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isOnline ? Colors.green : Colors.orange).withValues(
                  alpha: 0.3,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: size * 0.6,
              ),
              if (showPendingCount && pendingCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: BoxConstraints(
                      minWidth: size * 0.35,
                      minHeight: size * 0.35,
                    ),
                    child: Center(
                      child: Text(
                        pendingCount > 99 ? '99+' : '$pendingCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.25,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// A banner widget showing offline status that appears at the top/bottom of the screen
class OfflineStatusBanner extends StatelessWidget {
  final bool showAtTop;

  const OfflineStatusBanner({super.key, this.showAtTop = true});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();
    final offlineSalesService = Get.find<OfflineSalesService>();

    return Obx(() {
      final isOnline = connectivityService.isOnline.value;
      final pendingCount = offlineSalesService.totalPendingCount.value;

      if (isOnline && pendingCount == 0) {
        return const SizedBox.shrink();
      }

      final message = offlineSalesService.getOfflineStatusMessage();
      final isDegraded = offlineSalesService.isDegradedMode();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDegraded ? Colors.red[50] : Colors.orange[50],
          border: Border(
            bottom: showAtTop
                ? BorderSide(
                    color: isDegraded ? Colors.red[200]! : Colors.orange[200]!,
                  )
                : BorderSide.none,
            top: !showAtTop
                ? BorderSide(
                    color: isDegraded ? Colors.red[200]! : Colors.orange[200]!,
                  )
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isOnline ? Icons.cloud_queue : Icons.cloud_off,
              color: isDegraded ? Colors.red[600] : Colors.orange[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isDegraded ? Colors.red[700] : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  if (isDegraded)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Sync queue is at ${offlineSalesService.getQueuePressure().toStringAsFixed(0)}% capacity',
                        style: TextStyle(color: Colors.red[600], fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// A simple chip widget for displaying offline status
class OfflineStatusChip extends StatelessWidget {
  final bool compact;

  const OfflineStatusChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();

    return Obx(() {
      final isOnline = connectivityService.isOnline.value;

      return Chip(
        avatar: Icon(
          isOnline ? Icons.cloud_done : Icons.cloud_off,
          size: compact ? 16 : 18,
          color: isOnline ? Colors.green : Colors.orange,
        ),
        label: Text(
          isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: isOnline ? Colors.green[700] : Colors.orange[700],
          ),
        ),
        backgroundColor: isOnline
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        side: BorderSide(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      );
    });
  }
}
