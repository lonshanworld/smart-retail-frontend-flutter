import 'package:get/get.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import '../models/sync_models.dart';
import 'local_database_service.dart';
import 'connectivity_service.dart';
import 'offline_mode_manager.dart';

class OfflineSalesService extends GetxService {
  late LocalDatabaseService _localDatabaseService;
  late ConnectivityService _connectivityService;
  late OfflineModeManager _offlineModeManager;
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
      // Check if device can process sales
      if (!_offlineModeManager.canProcessSales()) {
        print('[OfflineSales] Cannot process sales at the moment');
        return false;
      }

      // If online, attempt to send immediately
      if (_connectivityService.isOnline.value) {
        return await _processSaleOnline(saleData);
      } else {
        // Queue for offline processing
        return await _queueSaleOffline(saleData);
      }
    } catch (e) {
      print('[OfflineSales] Error processing sale: $e');
      return false;
    }
  }

  /// Process sale immediately when online
  Future<bool> _processSaleOnline(Map<String, dynamic> saleData) async {
    try {
      print('[OfflineSales] Processing sale online...');

      final token = _authService.authToken.value;
      if (token == null || token.isEmpty) {
        print(
          '[OfflineSales] Missing auth token, queueing sale for offline sync',
        );
        return await _queueSaleOffline(saleData);
      }

      final shopId = saleData['shopId']?.toString();
      if (shopId == null || shopId.isEmpty) {
        print(
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
        print('[OfflineSales] Sale processed online successfully');
        return true;
      }

      final backendMessage = response.body?['message'] ?? 'Checkout failed';
      print('[OfflineSales] Backend rejected sale: $backendMessage');
      return await _queueSaleOffline(saleData);
    } catch (e) {
      print('[OfflineSales] Error processing sale online: $e');
      // On error, queue for offline processing
      return await _queueSaleOffline(saleData);
    }
  }

  /// Queue sale for offline processing
  Future<bool> _queueSaleOffline(Map<String, dynamic> saleData) async {
    try {
      print('[OfflineSales] Queuing sale for offline processing...');

      saleData['timestamp'] = DateTime.now().toIso8601String();
      saleData['status'] = 'pending';
      saleData['syncAttempts'] = 0;

      await _localDatabaseService.queueSale(saleData);
      await _loadPendingSales();

      print(
        '[OfflineSales] Sale queued successfully. Total pending: ${totalPendingCount.value}',
      );
      return true;
    } catch (e) {
      print('[OfflineSales] Error queuing sale: $e');
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

      print('[OfflineSales] Loaded ${sales.length} pending sales');
    } catch (e) {
      print('[OfflineSales] Error loading pending sales: $e');
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
      print('[OfflineSales] Marked sale $saleId as synced');
    } catch (e) {
      print('[OfflineSales] Error marking sale as synced: $e');
    }
  }

  /// Mark a sale as failed
  Future<void> markSaleFailed(String saleId, String error) async {
    try {
      await _localDatabaseService.markSaleFailed(saleId, error);
      await _loadPendingSales();
      print('[OfflineSales] Marked sale $saleId as failed: $error');
    } catch (e) {
      print('[OfflineSales] Error marking sale as failed: $e');
    }
  }

  // ============ BATCH OPERATIONS ============

  /// Get sales for syncing as batch
  Future<List<Map<String, dynamic>>> getSalesForSync(int limit) async {
    try {
      final sales = await _localDatabaseService.getPendingSales();
      return sales.take(limit).toList();
    } catch (e) {
      print('[OfflineSales] Error getting sales for sync: $e');
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
      print('[OfflineSales] Updated sync status for ${results.length} sales');
    } catch (e) {
      print('[OfflineSales] Error updating batch sync status: $e');
    }
  }

  // ============ SALES MANAGEMENT ============

  /// Get sales by status
  Future<List<Map<String, dynamic>>> getSalesByStatus(String status) async {
    try {
      final sales = await _localDatabaseService.getPendingSales();
      return sales.where((s) => s['status'] == status).toList();
    } catch (e) {
      print('[OfflineSales] Error getting sales by status: $e');
      return [];
    }
  }

  /// Delete a sale
  Future<void> deleteSale(String saleId) async {
    try {
      await _localDatabaseService.deleteSale(saleId);
      await _loadPendingSales();
      print('[OfflineSales] Deleted sale $saleId');
    } catch (e) {
      print('[OfflineSales] Error deleting sale: $e');
    }
  }

  /// Clear all pending sales (use with caution!)
  Future<void> clearAllPendingSales() async {
    try {
      await _localDatabaseService.clearAllSales();
      await _loadPendingSales();
      print('[OfflineSales] Cleared all pending sales');
    } catch (e) {
      print('[OfflineSales] Error clearing pending sales: $e');
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
      print('[OfflineSales] Error getting sales statistics: $e');
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
        return 'All data synced ✓';
      }
      return 'Syncing ${totalPendingCount.value} pending sales...';
    } else {
      return 'Offline: ${totalPendingCount.value} sales waiting to sync';
    }
  }
}
