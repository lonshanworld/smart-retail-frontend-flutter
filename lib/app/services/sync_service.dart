import 'package:get/get.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:uuid/uuid.dart';
import '../models/sync_models.dart';
import 'connectivity_service.dart';
import 'local_database_service.dart';
import 'offline_mode_manager.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class SyncService extends GetxService {
  final Rx<SyncStatus> syncStatus = SyncStatus.idle.obs;
  final Rx<int> pendingSalesCount = 0.obs;
  final Rx<int> pendingOperationsCount = 0.obs;
  final Rx<DateTime?> lastSyncTime = Rx<DateTime?>(null);
  final Rx<List<SyncLog>> syncHistory = Rx<List<SyncLog>>([]);
  final Rx<String> lastSyncMessage = 'Ready'.obs;
  final Rx<int> syncedCount = 0.obs;
  final Rx<int> failedCount = 0.obs;

  late ConnectivityService _connectivityService;
  late LocalDatabaseService _localDatabaseService;
  late OfflineModeManager _offlineModeManager;
  late AuthService _authService;

  @override
  void onInit() {
    super.onInit();
    _initServices();
  }

  void _initServices() {
    _connectivityService = Get.find<ConnectivityService>();
    _localDatabaseService = Get.find<LocalDatabaseService>();
    _offlineModeManager = Get.find<OfflineModeManager>();
    _authService = Get.find<AuthService>();

    // Listen to connectivity changes
    ever(_connectivityService.isOnline, (isOnline) async {
      if (isOnline) {
        // Automatically trigger sync when connection restored
        Future.delayed(Duration(seconds: 2), () async {
          final count = await _localDatabaseService.getPendingSalesCount();
          if (count > 0) {
            getLogger('app').info(
              '[SyncService] Connection restored. Pending sales: $count. Triggering auto-sync...',
            );
            // Don't auto-sync by default, let user manually trigger
            // await syncPendingSales();
          }
        });
      }
    });

    // Initialize pending sales count
    _updatePendingSalesCount();
    _updatePendingOperationsCount();
    _loadSyncHistory();
  }

  Future<void> _updatePendingSalesCount() async {
    final count = await _localDatabaseService.getPendingSalesCount();
    pendingSalesCount.value = count;
  }

  Future<void> _updatePendingOperationsCount() async {
    final count = await _localDatabaseService.getPendingOperationsCount();
    pendingOperationsCount.value = count;
  }

  Future<void> _loadSyncHistory({int limit = 10}) async {
    try {
      final history = await _localDatabaseService.getSyncHistory(limit: limit);
      syncHistory.value = history.map((h) => SyncLog.fromMap(h)).toList();
    } catch (e) {
      getLogger('app').info('[SyncService] Error loading sync history: $e');
    }
  }

  Future<bool> syncPendingSales() async {
    if (_offlineModeManager.isLocalStorageOnly) {
      syncStatus.value = SyncStatus.idle;
      lastSyncMessage.value = 'Local storage only mode: cloud sync disabled';
      return true;
    }

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
      final salesForSync = pendingSales
          .map((s) => SaleForSync.fromMap(s))
          .toList();

      final request = SyncRequest(
        syncBatchId: syncBatchId,
        syncTimestamp: DateTime.now(),
        sales: salesForSync,
      );

      getLogger('app').info('[SyncService] Starting sync for ${salesForSync.length} sales');
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

          lastSyncMessage.value =
              'Synced ${syncedCount.value} / ${salesForSync.length}';
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
        lastSyncMessage.value =
            'All ${syncedCount.value} sales synced successfully!';
        getLogger('app').info(
          '[SyncService] Sync completed successfully: ${syncedCount.value} synced',
        );
        return true;
      } else {
        syncStatus.value = SyncStatus.error;
        lastSyncMessage.value =
            'Sync completed with ${failedCount.value} errors';
        getLogger('app').info(
          '[SyncService] Sync completed with errors: ${failedCount.value} failed',
        );
        return false;
      }
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      lastSyncMessage.value = 'Sync error: $e';
      getLogger('app').info('[SyncService] Error during sync: $e');
      failedCount.value = pendingSales.length;
      return false;
    }
  }

  Future<bool> syncPendingOperations() async {
    if (_offlineModeManager.isLocalStorageOnly) {
      lastSyncMessage.value = 'Local storage only mode: cloud sync disabled';
      return true;
    }

    final pendingOperations = await _localDatabaseService.getPendingOperations();
    if (pendingOperations.isEmpty) {
      await _updatePendingOperationsCount();
      return true;
    }

    try {
      syncStatus.value = SyncStatus.syncing;
      lastSyncMessage.value = 'Preparing mutation sync...';

      for (final operation in pendingOperations) {
        final opId = operation['id']?.toString() ?? '';
        if (opId.isEmpty) {
          continue;
        }

        try {
          final success = await _sendOperationToBackend(operation);
          if (success) {
            await _localDatabaseService.markOperationAsSynced(opId);
            await _logSyncAttempt(
              entityId: opId,
              action: operation['action']?.toString() ?? 'mutation',
              status: 'success',
              syncBatchId: operation['client_operation_id']?.toString(),
              entityType: operation['entity_type']?.toString() ?? 'mutation',
            );
          } else {
            await _localDatabaseService.markOperationFailed(opId, 'Failed to sync mutation');
            await _logSyncAttempt(
              entityId: opId,
              action: operation['action']?.toString() ?? 'mutation',
              status: 'failed',
              errorMessage: 'Failed to sync mutation',
              syncBatchId: operation['client_operation_id']?.toString(),
              entityType: operation['entity_type']?.toString() ?? 'mutation',
            );
          }
        } catch (e) {
          await _localDatabaseService.markOperationFailed(opId, e.toString());
          await _logSyncAttempt(
            entityId: opId,
            action: operation['action']?.toString() ?? 'mutation',
            status: 'failed',
            errorMessage: e.toString(),
            syncBatchId: operation['client_operation_id']?.toString(),
            entityType: operation['entity_type']?.toString() ?? 'mutation',
          );
        }
      }

      await _updatePendingOperationsCount();
      lastSyncMessage.value = 'Queued mutations processed';
      syncStatus.value = SyncStatus.success;
      return true;
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      lastSyncMessage.value = 'Mutation sync error: $e';
      return false;
    }
  }

  Future<BatchSyncResponse?> _sendBatchToBackend(SyncRequest request) async {
    try {
      getLogger('app').info(
        '[SyncService] Sending batch ${request.syncBatchId} with ${request.sales.length} sales',
      );

      final connect = Get.find<GetConnect>();
      final token = _authService.authToken.value;
      final authenticatedUserId = _authService.userId.value;

      // Prepare sync request with all sale data
      final syncPayload = {
        'batchId': request.syncBatchId,
        'timestamp': DateTime.now().toIso8601String(),
        'sales': request.sales
            .map(
              (sale) => {
                'id': sale.localId,
                'shopId': sale.shopId,
                'totalAmount': sale.totalAmount,
                'items': sale.items
                    .map(
                      (item) => {
                        'productId': item['product_id'] ?? item['id'],
                        'quantity': item['quantity'] ?? item['quantity_sold'],
                        'sellingPriceAtSale':
                            item['selling_price'] ?? item['sellingPriceAtSale'],
                        'originalPriceAtSale': item['original_price'],
                        'discountAmount': item['discount_amount'],
                      },
                    )
                    .toList(),
                'paymentType': sale.paymentType,
                'timestamp': sale.createdAt.toIso8601String(),
                'notes': sale.notes,
              },
            )
            .toList(),
        'deviceId': 'flutter-app',
        if (authenticatedUserId != null && authenticatedUserId.isNotEmpty)
          'userId': authenticatedUserId,
      };

      getLogger('app').info(
        '[SyncService] Sync payload prepared: ${request.sales.length} sales',
      );

      // Send to backend
      final response = await connect.post(
        '${ApiConstants.baseUrl}/merchant/pos/sync',
        syncPayload,
        headers: token != null && token.isNotEmpty
            ? {'Authorization': 'Bearer $token'}
            : null,
      );

      getLogger('app').info('[SyncService] Backend response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.body['data'] != null) {
        final data = asMap(response.body['data']);

        // Parse results from backend response
        final results = <SyncResult>[];
        if (data['results'] is List) {
          for (var r in data['results']) {
            results.add(
              SyncResult(
                localId: r['saleId'] ?? '',
                serverId: r['serverId'],
                status: (r['success'] ?? false) ? 'synced' : 'failed',
                error: r['errorMessage'],
                serverTimestamp: DateTime.now(),
              ),
            );
          }
        }

        final successCount = results.where((r) => r.isSuccess).length;
        final failureCount = results.where((r) => r.isFailed).length;

        getLogger('app').info(
          '[SyncService] Backend sync response: $successCount success, $failureCount failed',
        );

        return BatchSyncResponse(
          status: failureCount == 0
              ? 'success'
              : (successCount > 0 ? 'partial' : 'failed'),
          syncBatchId: request.syncBatchId,
          results: results,
          syncedCount: successCount,
          failedCount: failureCount,
        );
      } else {
        final errorMsg = response.body?['message'] ?? 'Unknown backend error';
        getLogger('app').info('[SyncService] Backend error: $errorMsg');
        return null;
      }
    } catch (e) {
      getLogger('app').info('[SyncService] Error sending batch to backend: $e');
      return null;
    }
  }

  Future<void> retryFailedSync() async {
    final failedSales = await _localDatabaseService.getFailedSales();
    if (failedSales.isEmpty) {
      lastSyncMessage.value = 'No failed sales to retry';
      return;
    }

    getLogger('app').info('[SyncService] Retrying ${failedSales.length} failed sales');
    await syncPendingSales();
  }

  Future<BatchSyncResponse?> manualSync() async {
    if (_offlineModeManager.isLocalStorageOnly) {
      lastSyncMessage.value = 'Cloud sync is disabled in local storage only mode';
      syncStatus.value = SyncStatus.idle;
      return null;
    }

    if (!_connectivityService.isOnline.value) {
      lastSyncMessage.value = 'Cannot sync: No internet connection';
      syncStatus.value = SyncStatus.error;
      return null;
    }

    final salesSuccess = await syncPendingSales();
    final opsSuccess = await syncPendingOperations();

    if (salesSuccess || opsSuccess) {
      await _loadSyncHistory();
    }

    return null; // Return actual response if needed
  }

  void startAutoSync() {
    // Listen to connectivity changes and auto-sync
    getLogger('app').info('[SyncService] Auto-sync enabled');
  }

  void stopAutoSync() {
    getLogger('app').info('[SyncService] Auto-sync disabled');
  }

  Future<void> _logSyncAttempt({
    required String entityId,
    required String action,
    required String status,
    String? errorMessage,
    String? syncBatchId,
    String entityType = 'sale',
  }) async {
    final log = {
      'id': const Uuid().v4(),
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'status': status,
      'error_message': errorMessage,
      'sync_batch_id': syncBatchId,
    };

    try {
      await _localDatabaseService.logSyncAttempt(log);
    } catch (e) {
      getLogger('app').info('[SyncService] Error logging sync attempt: $e');
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
    pendingOperationsCount.value = 0;
  }

  Future<bool> _sendOperationToBackend(Map<String, dynamic> operation) async {
    // If running in local-storage-only mode, do not attempt to send mutations.
    try {
      if (_offlineModeManager.isLocalStorageOnly) {
        getLogger('app').info('[SyncService] Local storage only mode enabled - skipping sending operation to backend');
        return false;
      }
    } catch (e) {
      // If _offlineModeManager is not initialized for some reason, be conservative and skip network.
      getLogger('app').info('[SyncService] OfflineModeManager not available, skipping network operation: $e');
      return false;
    }
    final connect = Get.find<GetConnect>();
    final token = _authService.authToken.value;
    final endpoint = operation['endpoint']?.toString() ?? '';
    final method = operation['method']?.toString().toUpperCase() ?? 'POST';
    final payloadRaw = operation['payload'];
    final headersRaw = operation['headers'];

    if (endpoint.isEmpty) {
      return false;
    }

    final payload = payloadRaw is String && payloadRaw.isNotEmpty
        ? asMap(payloadRaw)
        : (payloadRaw is Map ? Map<String, dynamic>.from(payloadRaw) : <String, dynamic>{});
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (headersRaw is String && headersRaw.isNotEmpty) ...Map<String, String>.from(asMap(headersRaw).map((key, value) => MapEntry(key.toString(), value.toString()))),
      'Content-Type': 'application/json',
      'X-Client-Operation-Id': operation['client_operation_id']?.toString() ?? operation['clientOperationId']?.toString() ?? '',
    };

    final url = endpoint.startsWith('http') ? endpoint : '${ApiConstants.baseUrl}$endpoint';
    switch (method) {
      case 'POST':
        return (await connect.post(url, payload, headers: headers)).isOk;
      case 'PUT':
        return (await connect.put(url, payload, headers: headers)).isOk;
      case 'PATCH':
        return (await connect.patch(url, payload, headers: headers)).isOk;
      case 'DELETE':
        return (await connect.delete(url, headers: headers)).isOk;
      default:
        return false;
    }
  }
}

