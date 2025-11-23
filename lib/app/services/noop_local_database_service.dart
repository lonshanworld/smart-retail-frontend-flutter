import 'local_database_service.dart';

/// Minimal no-op LocalDatabaseService for web builds.
/// Extends `LocalDatabaseService` and overrides methods to return
/// safe defaults. This allows registering the noop implementation
/// under the `LocalDatabaseService` type so existing `Get.find` calls
/// keep working on web.
class NoopLocalDatabaseService extends LocalDatabaseService {
  @override
  Future<void> queueSale(Map<String, dynamic> saleData) async => null;

  @override
  Future<List<Map<String, dynamic>>> getPendingSales() async => [];

  @override
  Future<List<Map<String, dynamic>>> getFailedSales() async => [];

  @override
  Future<void> markSaleAsSynced(String saleId, String serverSaleId) async => null;

  @override
  Future<void> markSaleFailed(String saleId, String? errorMsg) async => null;

  @override
  Future<int> getPendingSalesCount() async => 0;

  @override
  Future<void> cacheProducts(List<Map<String, dynamic>> products, String merchantId) async => null;

  @override
  Future<List<Map<String, dynamic>>?> getCachedProducts(String merchantId) async => null;

  @override
  Future<void> cachePromotions(List<Map<String, dynamic>> promotions, String merchantId) async => null;

  @override
  Future<List<Map<String, dynamic>>?> getCachedPromotions(String merchantId) async => null;

  @override
  Future<void> cacheShopInfo(Map<String, dynamic> shopInfo, String merchantId) async => null;

  @override
  Future<Map<String, dynamic>?> getCachedShopInfo(String shopId) async => null;

  @override
  Future<bool> isCacheExpired(String cacheType) async => true;

  @override
  Future<void> clearExpiredCache() async => null;

  @override
  Future<void> clearAllCache() async => null;

  @override
  Future<String> calculateCacheSize() async => '0 MB';

  @override
  Future<void> logSyncAttempt(Map<String, dynamic> log) async => null;

  @override
  Future<List<Map<String, dynamic>>> getSyncHistory({int limit = 50}) async => [];

  @override
  Future<int> getSyncSuccessCount() async => 0;

  @override
  Future<void> setSetting(String key, String value) async => null;

  @override
  Future<String?> getSetting(String key) async => null;

  @override
  Future<void> setLastSyncTime(DateTime time) async => null;

  @override
  Future<DateTime?> getLastSyncTime() async => null;

  @override
  Future<void> closeDatabase() async => null;
}
