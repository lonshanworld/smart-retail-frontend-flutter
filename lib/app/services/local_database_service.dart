// Public interface for local database operations.
// This file defines the `LocalDatabaseService` API surface so
// other modules can depend on the type. Concrete implementations
// are provided per-platform (e.g., a full sqlite-backed
// implementation under `local_database/` and a noop for web).
abstract class LocalDatabaseService {
	// Generic access to the DB instance (platform implementation may
	// return an `sqflite` Database or a web-specific object). Use
	// `await database` in callers and treat the returned value as
	// dynamic when performing raw DB operations.
	Future<dynamic> get database;

	// Generic helper to fetch all rows from a table. Implementations may store
	// structured rows or JSON-encoded `data` fields; callers expect a list of
	// map objects representing rows.
	Future<List<Map<String, dynamic>>> getAll(String table);

	// User management
	Future<List<Map<String, dynamic>>> listAllUsers({String? role});
	Future<List<Map<String, dynamic>>> listUsersForMerchant(String merchantId);
	Future<dynamic> createUserLocal(Map<String, dynamic> user);
	Future<void> upsertUser(Map<String, dynamic> user);
	Future<Map<String, dynamic>?> getUserById(String userId);
	Future<Map<String, dynamic>?> findUserByEmail(String email, {String? role});

	// Shop / merchant
	Future<List<Map<String, dynamic>>> listShopsForMerchant(String merchantId);
	Future<void> upsertShop(Map<String, dynamic> shop);
	Future<void> deleteShop(String shopId);
	Future<Map<String, dynamic>?> getShopById(String shopId);

	// Customers
	Future<List<Map<String, dynamic>>> listCustomersForShop(String shopId);
	Future<dynamic> createCustomerLocal(Map<String, dynamic> customer);

	// Inventory / products
	Future<void> cacheProducts(List<Map<String, dynamic>> products, String merchantId);
	Future<List<Map<String, dynamic>>?> getCachedProducts(String merchantId);
	Future<void> cachePromotions(List<Map<String, dynamic>> promotions, String merchantId);
	Future<List<Map<String, dynamic>>?> getCachedPromotions(String merchantId);
	Future<void> cacheShopInfo(Map<String, dynamic> shopInfo, String merchantId);
	Future<Map<String, dynamic>?> getCachedShopInfo(String shopId);
	Future<bool> isCacheExpired(String cacheType);
	Future<void> clearExpiredCache();
	Future<void> clearAllCache();
	Future<int> calculateCacheSize();

	Future<void> upsertCategory(Map<String, dynamic> category);
	Future<void> upsertBrand(Map<String, dynamic> brand);
	Future<void> upsertSupplier(Map<String, dynamic> supplier);
	Future<Map<String, dynamic>?> getSupplierById(String supplierId);
	Future<void> insertInventoryItem(Map<String, dynamic> item);
	Future<List<Map<String, dynamic>>> getInventoryForShopLocal(String shopId);
	// Adjust stock for a single item. Call sites use named parameters.
	Future<void> adjustStockLocal({
		required String shopId,
		required String itemId,
		required num quantity,
		String? actorId,
		String? reason,
		String? clientOperationId,
	});

	// Additional inventory helpers used by services.
	Future<bool> addStockToShopLocal({required String shopId, String? inventoryItemId, String? productId, required num quantity, String? actorId, String? clientOperationId});
	Future<void> bulkStockInLocal({required String shopId, required List<Map<String, dynamic>> items, String? actorId, String? clientOperationId});
	Future<List<Map<String, dynamic>>> getMovementHistoryLocal(String shopId, [String? itemId, int page = 1, int pageSize = 50]);
	Future<void> upsertInventoryItem(Map<String, dynamic> item);
	Future<List<Map<String, dynamic>>> listActivePromotionsForShop(String shopId);

	// Promotions
	Future<void> upsertPromotion(Map<String, dynamic> promotion);
	Future<List<Map<String, dynamic>>> listPromotionsForMerchant(String merchantId, {bool onlyActive = true});

	// Invoices
	Future<List<Map<String, dynamic>>> listInvoicesForMerchantLocal(
			String merchantId, {int page = 1, int pageSize = 10, String? shopId});
	Future<Map<String, dynamic>?> getInvoiceByIdLocal(String invoiceId);
	Future<Map<String, dynamic>?> getInvoiceBySaleIdLocal(String saleId);
	Future<void> createInvoiceLocal(Map<String, dynamic> invoice);

	// Sales / offline
	Future<dynamic> createSaleLocal(Map<String, dynamic> sale);
	Future<void> createSaleItemLocal(Map<String, dynamic> saleItem);
	Future<Map<String, dynamic>?> getSaleById(String saleId);
	Future<List<Map<String, dynamic>>> getSaleItemsForSale(String saleId);
	Future<List<Map<String, dynamic>>> listSalesForShop(String shopId, {int? limit});

	Future<void> queueSale(Map<String, dynamic> saleData);
	Future<List<Map<String, dynamic>>> getPendingSales();
	Future<List<Map<String, dynamic>>> getFailedSales();
	Future<void> markSaleAsSynced(String saleId, dynamic serverSaleId);
	Future<void> markSaleFailed(String saleId, String? errorMsg);
	Future<int> getPendingSalesCount();
	Future<void> deleteSale(String saleId);
	Future<void> clearAllSales();

	// Generic queued operations
	Future<void> queueOperation(Map<String, dynamic> operation);
	Future<List<Map<String, dynamic>>> getPendingOperations();
	Future<void> markOperationAsSynced(String operationId);
	Future<void> markOperationFailed(String operationId, String? errorMsg);
	Future<int> getPendingOperationsCount();

	// Sync / history
	Future<void> logSyncAttempt(Map<String, dynamic> log);
	Future<List<Map<String, dynamic>>> getSyncHistory({int limit = 50});
	Future<int> getSyncSuccessCount();
	Future<void> setLastSyncTime(DateTime time);
	Future<DateTime?> getLastSyncTime();

	// Settings
	Future<void> setSetting(String key, dynamic value);
	Future<dynamic> getSetting(String key);

	// Misc
	Future<void> closeDatabase();
}

