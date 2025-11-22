import 'package:get/get.dart';
import 'local_database_service.dart';

class CacheManagerService extends GetxService {
  late LocalDatabaseService _localDatabaseService;

  @override
  void onInit() {
    super.onInit();
    _localDatabaseService = Get.find<LocalDatabaseService>();
  }

  // ============ PRODUCTS CACHE ============

  Future<void> cacheProducts(
    List<Map<String, dynamic>> products,
    String merchantId,
  ) async {
    try {
      await _localDatabaseService.cacheProducts(products, merchantId);
      print('[CacheManager] Cached ${products.length} products for merchant $merchantId');
    } catch (e) {
      print('[CacheManager] Error caching products: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedProducts(String merchantId) async {
    try {
      final products = await _localDatabaseService.getCachedProducts(merchantId);
      if (products != null) {
        print('[CacheManager] Retrieved ${products.length} cached products for merchant $merchantId');
      }
      return products;
    } catch (e) {
      print('[CacheManager] Error retrieving cached products: $e');
      return null;
    }
  }

  // ============ PROMOTIONS CACHE ============

  Future<void> cachePromotions(
    List<Map<String, dynamic>> promotions,
    String merchantId,
  ) async {
    try {
      await _localDatabaseService.cachePromotions(promotions, merchantId);
      print('[CacheManager] Cached ${promotions.length} promotions for merchant $merchantId');
    } catch (e) {
      print('[CacheManager] Error caching promotions: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedPromotions(String merchantId) async {
    try {
      final promotions = await _localDatabaseService.getCachedPromotions(merchantId);
      if (promotions != null) {
        print('[CacheManager] Retrieved ${promotions.length} cached promotions for merchant $merchantId');
      }
      return promotions;
    } catch (e) {
      print('[CacheManager] Error retrieving cached promotions: $e');
      return null;
    }
  }

  // ============ SHOP INFO CACHE ============

  Future<void> cacheShopInfo(
    Map<String, dynamic> shopInfo,
    String merchantId,
  ) async {
    try {
      await _localDatabaseService.cacheShopInfo(shopInfo, merchantId);
      print('[CacheManager] Cached shop info for shop ${shopInfo['id']}');
    } catch (e) {
      print('[CacheManager] Error caching shop info: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedShopInfo(String shopId) async {
    try {
      final shopInfo = await _localDatabaseService.getCachedShopInfo(shopId);
      if (shopInfo != null) {
        print('[CacheManager] Retrieved cached shop info for shop $shopId');
      }
      return shopInfo;
    } catch (e) {
      print('[CacheManager] Error retrieving cached shop info: $e');
      return null;
    }
  }

  // ============ CACHE MANAGEMENT ============

  Future<bool> isProductsCacheExpired() async {
    try {
      return await _localDatabaseService.isCacheExpired('products');
    } catch (e) {
      print('[CacheManager] Error checking if products cache expired: $e');
      return true;
    }
  }

  Future<bool> isPromotionsCacheExpired() async {
    try {
      return await _localDatabaseService.isCacheExpired('promotions');
    } catch (e) {
      print('[CacheManager] Error checking if promotions cache expired: $e');
      return true;
    }
  }

  Future<bool> isShopInfoCacheExpired() async {
    try {
      return await _localDatabaseService.isCacheExpired('shop_info');
    } catch (e) {
      print('[CacheManager] Error checking if shop info cache expired: $e');
      return true;
    }
  }

  Future<void> clearExpiredCache() async {
    try {
      await _localDatabaseService.clearExpiredCache();
      print('[CacheManager] Cleared expired cache entries');
    } catch (e) {
      print('[CacheManager] Error clearing expired cache: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      await _localDatabaseService.clearAllCache();
      print('[CacheManager] Cleared all cache');
    } catch (e) {
      print('[CacheManager] Error clearing all cache: $e');
    }
  }

  // ============ CACHE INFO ============

  Future<String> getCacheSize() async {
    try {
      return await _localDatabaseService.calculateCacheSize();
    } catch (e) {
      print('[CacheManager] Error calculating cache size: $e');
      return '0 MB';
    }
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final size = await getCacheSize();
      return {
        'size': size,
        'lastCleared': await _localDatabaseService.getSetting('last_cache_clear'),
        'lastUpdated': await _localDatabaseService.getSetting('last_cache_update'),
      };
    } catch (e) {
      print('[CacheManager] Error getting cache info: $e');
      return {'size': '0 MB', 'lastCleared': null, 'lastUpdated': null};
    }
  }

  // ============ UTILITY METHODS ============

  Future<void> refreshCache(
    String type,
    String merchantId,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      if (type == 'products') {
        await cacheProducts(data, merchantId);
      } else if (type == 'promotions') {
        await cachePromotions(data, merchantId);
      }
      print('[CacheManager] Refreshed $type cache');
    } catch (e) {
      print('[CacheManager] Error refreshing $type cache: $e');
    }
  }

  Future<void> setLastCacheClear() async {
    try {
      await _localDatabaseService.setSetting(
        'last_cache_clear',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('[CacheManager] Error setting last cache clear: $e');
    }
  }

  Future<void> setLastCacheUpdate() async {
    try {
      await _localDatabaseService.setSetting(
        'last_cache_update',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('[CacheManager] Error setting last cache update: $e');
    }
  }
}
