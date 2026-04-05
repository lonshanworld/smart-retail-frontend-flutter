import 'local_database_service.dart';

/// Minimal no-op LocalDatabaseService for web builds.
/// Implements the full `LocalDatabaseService` API with safe defaults so
/// the app can run in environments without a sqlite backend.
class NoopLocalDatabaseService extends LocalDatabaseService {
  @override
  Future<dynamic> get database async => null;

  @override
  Future<List<Map<String, dynamic>>> getAll(String table) async => [];

  // User management
  @override
  Future<List<Map<String, dynamic>>> listAllUsers({String? role}) async => [];

  @override
  Future<List<Map<String, dynamic>>> listUsersForMerchant(
    String merchantId,
  ) async => [];

  @override
  Future<dynamic> createUserLocal(Map<String, dynamic> user) async => null;

  @override
  Future<void> upsertUser(Map<String, dynamic> user) async {}

  @override
  Future<Map<String, dynamic>?> getUserById(String userId) async => null;

  @override
  Future<Map<String, dynamic>?> findUserByEmail(
    String email, {
    String? role,
  }) async => null;

  // Shop / merchant
  @override
  Future<List<Map<String, dynamic>>> listShopsForMerchant(
    String merchantId,
  ) async => [];

  @override
  Future<void> upsertShop(Map<String, dynamic> shop) async {}

  @override
  Future<void> deleteShop(String shopId) async {}

  @override
  Future<Map<String, dynamic>?> getShopById(String shopId) async => null;

  // Customers
  @override
  Future<List<Map<String, dynamic>>> listCustomersForShop(
    String shopId,
  ) async => [];

  @override
  Future<dynamic> createCustomerLocal(Map<String, dynamic> customer) async =>
      null;

  // Inventory / products
  @override
  Future<void> cacheProducts(
    List<Map<String, dynamic>> products,
    String merchantId,
  ) async {}

  @override
  Future<List<Map<String, dynamic>>?> getCachedProducts(
    String merchantId,
  ) async => null;

  @override
  Future<void> cachePromotions(
    List<Map<String, dynamic>> promotions,
    String merchantId,
  ) async {}

  @override
  Future<List<Map<String, dynamic>>?> getCachedPromotions(
    String merchantId,
  ) async => null;

  @override
  Future<void> cacheShopInfo(
    Map<String, dynamic> shopInfo,
    String merchantId,
  ) async {}

  @override
  Future<Map<String, dynamic>?> getCachedShopInfo(String shopId) async => null;

  @override
  Future<bool> isCacheExpired(String cacheType) async => true;

  @override
  Future<void> clearExpiredCache() async {}

  @override
  Future<void> clearAllCache() async {}

  @override
  Future<int> calculateCacheSize() async => 0;

  @override
  Future<void> upsertCategory(Map<String, dynamic> category) async {}

  @override
  Future<void> upsertBrand(Map<String, dynamic> brand) async {}

  @override
  Future<void> upsertSupplier(Map<String, dynamic> supplier) async {}

  @override
  Future<Map<String, dynamic>?> getSupplierById(String supplierId) async =>
      null;

  @override
  Future<void> insertInventoryItem(Map<String, dynamic> item) async {}

  @override
  Future<List<Map<String, dynamic>>> getInventoryForShopLocal(
    String shopId,
  ) async => [];

  @override
  Future<void> adjustStockLocal({
    required String shopId,
    required String itemId,
    required num quantity,
    String? actorId,
    String? reason,
    String? clientOperationId,
  }) async {}

  @override
  Future<bool> addStockToShopLocal({
    required String shopId,
    String? inventoryItemId,
    String? productId,
    required num quantity,
    String? actorId,
    String? clientOperationId,
  }) async => true;

  @override
  Future<void> bulkStockInLocal({
    required String shopId,
    required List<Map<String, dynamic>> items,
    String? actorId,
    String? clientOperationId,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getMovementHistoryLocal(
    String shopId, [
    String? itemId,
    int page = 1,
    int pageSize = 50,
  ]) async => [];

  @override
  Future<void> upsertInventoryItem(Map<String, dynamic> item) async {}

  @override
  Future<List<Map<String, dynamic>>> listActivePromotionsForShop(
    String shopId,
  ) async => [];

  // Additional inventory helpers used in several services
  @override
  Future<void> upsertPromotion(Map<String, dynamic> promotion) async {}

  @override
  Future<List<Map<String, dynamic>>> listPromotionsForMerchant(
    String merchantId, {
    bool onlyActive = true,
  }) async => [];

  // Invoices
  @override
  Future<List<Map<String, dynamic>>> listInvoicesForMerchantLocal(
    String merchantId, {
    int page = 1,
    int pageSize = 10,
    String? shopId,
  }) async => [];

  @override
  Future<Map<String, dynamic>?> getInvoiceByIdLocal(String invoiceId) async =>
      null;

  @override
  Future<Map<String, dynamic>?> getInvoiceBySaleIdLocal(String saleId) async =>
      null;

  @override
  Future<void> createInvoiceLocal(Map<String, dynamic> invoice) async {}

  // Sales / offline
  @override
  Future<dynamic> createSaleLocal(Map<String, dynamic> sale) async => null;

  @override
  Future<void> createSaleItemLocal(Map<String, dynamic> saleItem) async {}

  @override
  Future<Map<String, dynamic>?> getSaleById(String saleId) async => null;

  @override
  Future<List<Map<String, dynamic>>> getSaleItemsForSale(String saleId) async =>
      [];

  @override
  Future<List<Map<String, dynamic>>> listSalesForShop(
    String shopId, {
    int? limit,
  }) async => [];

  @override
  Future<void> queueSale(Map<String, dynamic> saleData) async {}

  @override
  Future<List<Map<String, dynamic>>> getPendingSales() async => [];

  @override
  Future<List<Map<String, dynamic>>> getFailedSales() async => [];

  @override
  Future<void> markSaleAsSynced(String saleId, dynamic serverSaleId) async {}

  @override
  Future<void> markSaleFailed(String saleId, String? errorMsg) async {}

  @override
  Future<int> getPendingSalesCount() async => 0;

  @override
  Future<void> deleteSale(String saleId) async {}

  @override
  Future<void> clearAllSales() async {}

  // Generic queued operations
  @override
  Future<void> queueOperation(Map<String, dynamic> operation) async {}

  @override
  Future<List<Map<String, dynamic>>> getPendingOperations() async => [];

  @override
  Future<void> markOperationAsSynced(String operationId) async {}

  @override
  Future<void> markOperationFailed(
    String operationId,
    String? errorMsg,
  ) async {}

  @override
  Future<int> getPendingOperationsCount() async => 0;

  // Sync / history
  @override
  Future<void> logSyncAttempt(Map<String, dynamic> log) async {}

  @override
  Future<List<Map<String, dynamic>>> getSyncHistory({int limit = 50}) async =>
      [];

  @override
  Future<int> getSyncSuccessCount() async => 0;

  @override
  Future<void> setLastSyncTime(DateTime time) async {}

  @override
  Future<DateTime?> getLastSyncTime() async => null;

  // Settings
  @override
  Future<void> setSetting(String key, dynamic value) async {}

  @override
  Future<dynamic> getSetting(String key) async => null;

  // Misc
  @override
  Future<void> closeDatabase() async {}
}
