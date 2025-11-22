import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/sync_models.dart';
import 'connectivity_service.dart';
import 'local_database_service.dart';

class SyncService extends GetxService {
  final Rx<SyncStatus> syncStatus = SyncStatus.idle.obs;
  final Rx<int> pendingSalesCount = 0.obs;
  final Rx<DateTime?> lastSyncTime = Rx<DateTime?>(null);
  final Rx<List<SyncLog>> syncHistory = Rx<List<SyncLog>>([]);
  final Rx<String> lastSyncMessage = 'Ready'.obs;
  final Rx<int> syncedCount = 0.obs;
  final Rx<int> failedCount = 0.obs;

  late ConnectivityService _connectivityService;
  late LocalDatabaseService _localDatabaseService;

  @override
  void onInit() {
    super.onInit();
    _initServices();
  }

  void _initServices() {
    _connectivityService = Get.find<ConnectivityService>();
    _localDatabaseService = Get.find<LocalDatabaseService>();

    // Listen to connectivity changes
    ever(_connectivityService.isOnline, (isOnline) async {
      if (isOnline) {
        // Automatically trigger sync when connection restored
        Future.delayed(Duration(seconds: 2), () async {
          final count = await _localDatabaseService.getPendingSalesCount();
          if (count > 0) {
            print('[SyncService] Connection restored. Pending sales: $count. Triggering auto-sync...');
            // Don't auto-sync by default, let user manually trigger
            // await syncPendingSales();
          }
        });
      }
    });

    // Initialize pending sales count
    _updatePendingSalesCount();
    _loadSyncHistory();
  }

  Future<void> _updatePendingSalesCount() async {
    final count = await _localDatabaseService.getPendingSalesCount();
    pendingSalesCount.value = count;
  }

  Future<void> _loadSyncHistory({int limit = 10}) async {
    try {
      final history = await _localDatabaseService.getSyncHistory(limit: limit);
      syncHistory.value = history.map((h) => SyncLog.fromMap(h)).toList();
    } catch (e) {
      print('[SyncService] Error loading sync history: $e');
    }
  }

  Future<bool> syncPendingSales() async {
    // Get pending sales
    final pendingSales = await _localDatabaseService.getPendingSales();
    if (pendingSales.isEmpty) {
      lastSyncMessage.value = 'No pending sales to sync';
      return true;
    }

    try {
      syncStatus.value = SyncStatus.syncing;
      lastSyncMessage.value = 'Preparing batch sync...';
      syncedCount.value = 0;
      failedCount.value = 0;

      // Create batch request
      final syncBatchId = const Uuid().v4();
      final salesForSync = pendingSales.map((s) => SaleForSync.fromMap(s)).toList();
      
      final request = SyncRequest(
        syncBatchId: syncBatchId,
        syncTimestamp: DateTime.now(),
        sales: salesForSync,
      );

      print('[SyncService] Starting sync for ${salesForSync.length} sales');
      lastSyncMessage.value = 'Connecting to server...';

      // Send to backend
      final response = await _sendBatchToBackend(request);

      if (response == null) {
        syncStatus.value = SyncStatus.error;
        lastSyncMessage.value = 'Failed to connect to server';
        failedCount.value = pendingSales.length;
        return false;
      }

      // Process results
      for (var result in response.results) {
        if (result.isSuccess) {
          await _localDatabaseService.markSaleAsSynced(
            result.localId,
            result.serverId ?? '',
          );
          syncedCount.value++;

          // Log sync success
          await _logSyncAttempt(
            entityId: result.localId,
            action: 'sync',
            status: 'success',
            syncBatchId: syncBatchId,
          );

          lastSyncMessage.value = 'Synced ${syncedCount.value} / ${salesForSync.length}';
        } else {
          await _localDatabaseService.markSaleFailed(
            result.localId,
            result.error,
          );
          failedCount.value++;

          // Log sync failure
          await _logSyncAttempt(
            entityId: result.localId,
            action: 'sync',
            status: 'failed',
            errorMessage: result.error,
            syncBatchId: syncBatchId,
          );

          lastSyncMessage.value = 'Failed: ${result.error}';
        }
      }

      // Update last sync time
      await _localDatabaseService.setLastSyncTime(DateTime.now());
      lastSyncTime.value = DateTime.now();

      // Reload pending count
      await _updatePendingSalesCount();

      if (response.isSuccess) {
        syncStatus.value = SyncStatus.success;
        lastSyncMessage.value = 'All ${syncedCount.value} sales synced successfully!';
        print('[SyncService] Sync completed successfully: ${syncedCount.value} synced');
        return true;
      } else {
        syncStatus.value = SyncStatus.error;
        lastSyncMessage.value = 'Sync completed with ${failedCount.value} errors';
        print('[SyncService] Sync completed with errors: ${failedCount.value} failed');
        return false;
      }
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      lastSyncMessage.value = 'Sync error: $e';
      print('[SyncService] Error during sync: $e');
      failedCount.value = pendingSales.length;
      return false;
    }
  }

  Future<BatchSyncResponse?> _sendBatchToBackend(SyncRequest request) async {
    try {
      print('[SyncService] Sending batch ${request.syncBatchId} with ${request.sales.length} sales');

      final connect = Get.find<GetConnect>();
      
      // Prepare sync request with all sale data
      final syncPayload = {
        'batchId': request.syncBatchId,
        'timestamp': DateTime.now().toIso8601String(),
        'sales': request.sales.map((sale) => {
          'id': sale.localId,
          'shopId': sale.shopId,
          'totalAmount': sale.totalAmount,
          'items': sale.items.map((item) => {
            'productId': item['product_id'] ?? item['id'],
            'quantity': item['quantity'] ?? item['quantity_sold'],
            'sellingPriceAtSale': item['selling_price'] ?? item['sellingPriceAtSale'],
            'originalPriceAtSale': item['original_price'],
            'discountAmount': item['discount_amount'],
          }).toList(),
          'paymentType': sale.paymentType,
          'timestamp': sale.createdAt.toIso8601String(),
          'notes': sale.notes,
        }).toList(),
        'deviceId': 'flutter-app',
        'userId': 'user-id-from-auth',  // This should come from AuthService
      };

      print('[SyncService] Sync payload prepared: ${request.sales.length} sales');

      // Send to backend
      final response = await connect.post(
        'http://localhost:3000/api/v1/merchant/pos/sync',
        syncPayload,
      );

      print('[SyncService] Backend response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.body['data'] != null) {
        final data = response.body['data'];
        
        // Parse results from backend response
        final results = <SyncResult>[];
        if (data['results'] is List) {
          for (var r in data['results']) {
            results.add(SyncResult(
              localId: r['saleId'] ?? '',
              serverId: r['serverId'],
              status: (r['success'] ?? false) ? 'synced' : 'failed',
              error: r['errorMessage'],
              serverTimestamp: DateTime.now(),
            ));
          }
        }

        final successCount = results.where((r) => r.isSuccess).length;
        final failureCount = results.where((r) => r.isFailed).length;

        print('[SyncService] Backend sync response: $successCount success, $failureCount failed');

        return BatchSyncResponse(
          status: failureCount == 0 ? 'success' : (successCount > 0 ? 'partial' : 'failed'),
          syncBatchId: request.syncBatchId,
          results: results,
          syncedCount: successCount,
          failedCount: failureCount,
        );
      } else {
        final errorMsg = response.body?['message'] ?? 'Unknown backend error';
        print('[SyncService] Backend error: $errorMsg');
        return null;
      }
    } catch (e) {
      print('[SyncService] Error sending batch to backend: $e');
      return null;
    }
  }

  Future<void> retryFailedSync() async {
    final failedSales = await _localDatabaseService.getFailedSales();
    if (failedSales.isEmpty) {
      lastSyncMessage.value = 'No failed sales to retry';
      return;
    }

    print('[SyncService] Retrying ${failedSales.length} failed sales');
    await syncPendingSales();
  }

  Future<BatchSyncResponse?> manualSync() async {
    if (!_connectivityService.isOnline.value) {
      lastSyncMessage.value = 'Cannot sync: No internet connection';
      syncStatus.value = SyncStatus.error;
      return null;
    }

    final success = await syncPendingSales();
    
    if (success) {
      await _loadSyncHistory();
    }

    return null; // Return actual response if needed
  }

  void startAutoSync() {
    // Listen to connectivity changes and auto-sync
    print('[SyncService] Auto-sync enabled');
  }

  void stopAutoSync() {
    print('[SyncService] Auto-sync disabled');
  }

  Future<void> _logSyncAttempt({
    required String entityId,
    required String action,
    required String status,
    String? errorMessage,
    String? syncBatchId,
  }) async {
    final log = {
      'id': const Uuid().v4(),
      'entity_type': 'sale',
      'entity_id': entityId,
      'action': action,
      'status': status,
      'error_message': errorMessage,
      'sync_batch_id': syncBatchId,
    };

    try {
      await _localDatabaseService.logSyncAttempt(log);
    } catch (e) {
      print('[SyncService] Error logging sync attempt: $e');
    }
  }

  Future<int> getSyncSuccessCount() async {
    return await _localDatabaseService.getSyncSuccessCount();
  }

  void resetSyncStatus() {
    syncStatus.value = SyncStatus.idle;
    lastSyncMessage.value = 'Ready';
    syncedCount.value = 0;
    failedCount.value = 0;
  }

  @override
  void onClose() {
    super.onClose();
  }
}
