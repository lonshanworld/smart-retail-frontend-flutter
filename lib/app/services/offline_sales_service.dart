import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import '../models/sync_models.dart';
import 'local_database_service.dart';
import 'connectivity_service.dart';
import 'offline_mode_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class OfflineSalesService extends GetxService {
  late LocalDatabaseService _localDatabaseService;
  late ConnectivityService _connectivityService;
  late OfflineModeManager _offlineModeManager;
  late AppConfig _appConfig;
  late GetConnect _connect;
  late AuthService _authService;

  // Observable sales data
  final Rx<List<Map<String, dynamic>>> pendingSales = Rx([]);
  final Rx<List<Map<String, dynamic>>> syncedSales = Rx([]);
  final Rx<int> totalPendingCount = Rx(0);

  // Alias for UI compatibility
  Rx<int> get pendingSalesCount => totalPendingCount;

  @override
  void onInit() {
    super.onInit();
    _localDatabaseService = Get.find<LocalDatabaseService>();
    _connectivityService = Get.find<ConnectivityService>();
    _offlineModeManager = Get.find<OfflineModeManager>();
    _appConfig = Get.find<AppConfig>();
    _connect = Get.find<GetConnect>();
    _authService = Get.find<AuthService>();

    // Load pending sales on init
    _loadPendingSales();

    // Listen to connectivity changes and reload sales
    _connectivityService.onConnectivityChanged.listen((_) {
      _loadPendingSales();
    });
  }

  // ============ PROCESS SALE ============

  /// Process a sale either online or offline based on connectivity
  /// Returns true if sale was processed successfully
  Future<bool> processSale(Map<String, dynamic> saleData) async {
    try {
      saleData['id'] ??= const Uuid().v4();

      // Check if device can process sales
      if (!_offlineModeManager.canProcessSales()) {
        getLogger('app').info('[OfflineSales] Cannot process sales at the moment');
        return false;
      }

      if (_appConfig.localStorageOnly) {
        return await _queueSaleOffline(saleData);
      }

      // If online, attempt to send immediately
      if (_connectivityService.isOnline.value) {
        return await _processSaleOnline(saleData);
      } else {
        // Queue for offline processing
        return await _queueSaleOffline(saleData);
      }
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error processing sale: $e');
      return false;
    }
  }

  /// Process sale immediately when online
  Future<bool> _processSaleOnline(Map<String, dynamic> saleData) async {
    try {
      if (_appConfig.localStorageOnly) {
        return await _queueSaleOffline(saleData);
      }

      getLogger('app').info('[OfflineSales] Processing sale online...');

      final token = _authService.authToken.value;
      if (token == null || token.isEmpty) {
        getLogger('app').info(
          '[OfflineSales] Missing auth token, queueing sale for offline sync',
        );
        return await _queueSaleOffline(saleData);
      }

      final shopId = saleData['shopId']?.toString();
      if (shopId == null || shopId.isEmpty) {
        getLogger('app').info(
          '[OfflineSales] Missing shopId in sale payload, queueing offline',
        );
        return await _queueSaleOffline(saleData);
      }

      final payload = Map<String, dynamic>.from(saleData);
      payload['timestamp'] = DateTime.now().toIso8601String();
      payload['status'] = 'syncing';
      payload['syncAttempts'] = (payload['syncAttempts'] as int?) ?? 1;

      final response = await _connect.post(
        '${ApiConstants.baseUrl}/merchant/pos/checkout',
        payload,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 201 && response.body?['data'] != null) {
        getLogger('app').info('[OfflineSales] Sale processed online successfully');
        return true;
      }

      final backendMessage = response.body?['message'] ?? 'Checkout failed';
      getLogger('app').info('[OfflineSales] Backend rejected sale: $backendMessage');
      return await _queueSaleOffline(saleData);
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error processing sale online: $e');
      // On error, queue for offline processing
      return await _queueSaleOffline(saleData);
    }
  }

  /// Queue sale for offline processing
  Future<bool> _queueSaleOffline(Map<String, dynamic> saleData) async {
    try {
      getLogger('app').info('[OfflineSales] Queuing sale for offline processing...');

      saleData['timestamp'] = DateTime.now().toIso8601String();
      saleData['status'] = 'pending';
      saleData['syncAttempts'] = 0;

      final shopId =
          saleData['shopId']?.toString() ??
          saleData['shop_id']?.toString() ??
          _authService.shopId.value ??
          _authService.user.value?.assignedShopId;

      if (shopId != null && shopId.isNotEmpty) {
        final items = (saleData['items'] as List<dynamic>?) ?? const [];
        for (final item in items) {
          if (item is! Map<String, dynamic>) continue;
          final itemId =
              item['productId']?.toString() ??
              item['product_id']?.toString() ??
              item['inventoryItemId']?.toString() ??
              item['inventory_item_id']?.toString();
          final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
          if (itemId == null || itemId.isEmpty || quantity <= 0) continue;

          await _localDatabaseService.adjustStockLocal(
            shopId: shopId,
            itemId: itemId,
            quantity: -quantity,
            actorId: _authService.user.value?.id,
            reason: 'sale',
          );
        }
      } else {
        getLogger('app').info(
          '[OfflineSales] No shopId available while queueing sale, stock was not decremented locally.',
        );
      }

      await _localDatabaseService.queueSale(saleData);
      await _loadPendingSales();

      getLogger('app').info(
        '[OfflineSales] Sale queued successfully. Total pending: ${totalPendingCount.value}',
      );
      return true;
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error queuing sale: $e');
      return false;
    }
  }

  // ============ LOAD PENDING SALES ============

  /// Load all pending sales from database
  Future<void> _loadPendingSales() async {
    try {
      final sales = await _localDatabaseService.getPendingSales();
      pendingSales.value = sales;
      totalPendingCount.value = sales.length;

      getLogger('app').info('[OfflineSales] Loaded ${sales.length} pending sales');
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error loading pending sales: $e');
    }
  }

  /// Get pending sales list
  List<Map<String, dynamic>> getPendingSales() {
    return pendingSales.value;
  }

  /// Get total pending sales count
  int getPendingSalesCount() {
    return totalPendingCount.value;
  }

  // ============ MARK SALES ============

  /// Mark a sale as successfully synced
  Future<void> markSaleAsSynced(String saleId, String serverId) async {
    try {
      await _localDatabaseService.markSaleAsSynced(saleId, serverId);
      await _loadPendingSales();
      getLogger('app').info('[OfflineSales] Marked sale $saleId as synced');
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error marking sale as synced: $e');
    }
  }

  /// Mark a sale as failed
  Future<void> markSaleFailed(String saleId, String error) async {
    try {
      await _localDatabaseService.markSaleFailed(saleId, error);
      await _loadPendingSales();
      getLogger('app').info('[OfflineSales] Marked sale $saleId as failed: $error');
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error marking sale as failed: $e');
    }
  }

  // ============ BATCH OPERATIONS ============

  /// Get sales for syncing as batch
  Future<List<Map<String, dynamic>>> getSalesForSync(int limit) async {
    try {
      final sales = await _localDatabaseService.getPendingSales();
      return sales.take(limit).toList();
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error getting sales for sync: $e');
      return [];
    }
  }

  /// Update multiple sales sync status
  Future<void> updateBatchSyncStatus(List<SyncResult> results) async {
    try {
      for (final result in results) {
        if (result.isSuccess) {
          await markSaleAsSynced(result.localId, result.serverId ?? '');
        } else {
          await markSaleFailed(result.localId, result.error ?? 'Unknown error');
        }
      }
      await _loadPendingSales();
      getLogger('app').info('[OfflineSales] Updated sync status for ${results.length} sales');
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error updating batch sync status: $e');
    }
  }

  // ============ SALES MANAGEMENT ============

  /// Get sales by status
  Future<List<Map<String, dynamic>>> getSalesByStatus(String status) async {
    try {
      final sales = await _localDatabaseService.getPendingSales();
      return sales.where((s) => s['status'] == status).toList();
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error getting sales by status: $e');
      return [];
    }
  }

  /// Delete a sale
  Future<void> deleteSale(String saleId) async {
    try {
      await _localDatabaseService.deleteSale(saleId);
      await _loadPendingSales();
      getLogger('app').info('[OfflineSales] Deleted sale $saleId');
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error deleting sale: $e');
    }
  }

  /// Clear all pending sales (use with caution!)
  Future<void> clearAllPendingSales() async {
    try {
      await _localDatabaseService.clearAllSales();
      await _loadPendingSales();
      getLogger('app').info('[OfflineSales] Cleared all pending sales');
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error clearing pending sales: $e');
    }
  }

  // ============ STATISTICS ============

  /// Get sales statistics
  Future<Map<String, dynamic>> getSalesStatistics() async {
    try {
      final pending = await getSalesByStatus('pending');
      final synced = await getSalesByStatus('synced');
      final failed = await getSalesByStatus('failed');

      double totalAmount = 0;
      for (final sale in pending) {
        totalAmount += (sale['totalAmount'] as num?)?.toDouble() ?? 0;
      }

      return {
        'totalPending': pending.length,
        'totalSynced': synced.length,
        'totalFailed': failed.length,
        'pendingAmount': totalAmount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      getLogger('app').info('[OfflineSales] Error getting sales statistics: $e');
      return {
        'totalPending': 0,
        'totalSynced': 0,
        'totalFailed': 0,
        'pendingAmount': 0,
      };
    }
  }

  /// Check if offline sales queue is growing
  bool isQueueGrowing() {
    return totalPendingCount.value > 50;
  }

  /// Get queue pressure percentage (0-100)
  double getQueuePressure() {
    const maxQueue = 1000;
    return (totalPendingCount.value / maxQueue * 100).clamp(0, 100);
  }

  // ============ OFFLINE STATUS ============

  /// Check if system is in degraded mode (high queue)
  bool isDegradedMode() {
    return getQueuePressure() > 80;
  }

  /// Get user-friendly offline status message
  String getOfflineStatusMessage() {
    if (_connectivityService.isOnline.value) {
      if (totalPendingCount.value == 0) {
        return 'All data synced âœ“';
      }
      return 'Syncing ${totalPendingCount.value} pending sales...';
    } else {
      return 'Offline: ${totalPendingCount.value} sales waiting to sync';
    }
  }
}

