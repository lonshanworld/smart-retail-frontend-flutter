import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/shop_inventory_item.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/stock_movement_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class ShopInventoryApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  /// Base URL for merchant-specific shop operations (e.g., get list of shops)
  String get _merchantBaseUrl => '${ApiConstants.baseUrl}/merchant/shops';

  /// Base URL for shop-level operations accessible by both merchant and staff
  String get _shopBaseUrl => '${ApiConstants.baseUrl}/shop';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches a list of inventory items for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/shop/items?shopId={shopId}`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ A list of `ShopInventoryItem` objects.
  Future<List<ShopInventoryItem>> getShopInventory(String shopId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return List.generate(
        5,
        (i) => ShopInventoryItem(
          id: 'si-item-$i',
          productId: 'prod-$i',
          name: 'Product $i in Shop $shopId',
          sku: 'SKU-$i',
          quantity: 10 + i,
          sellingPrice: 15.0 + i,
        ),
      );
    }

    // Staff inventory page uses the /shop/items endpoint.
    getLogger('app').info('ðŸ” [SHOP INVENTORY API] Fetching inventory for shopId: $shopId');
    getLogger('app').info(
      'ðŸŒ [SHOP INVENTORY API] Using endpoint: $_shopBaseUrl/items?shopId=$shopId',
    );
    if (_appConfig.localStorageOnly) {
      final db = Get.find<LocalDatabaseService>();
      final rows = await db.getInventoryForShopLocal(shopId);
      return rows.map((r) => ShopInventoryItem.fromJson(r)).toList();
    }

    final response = await _connect.get(
      '$_shopBaseUrl/items?shopId=$shopId',
      headers: await _getHeaders(),
    );

    getLogger('app').info('ðŸ“¥ [SHOP INVENTORY API] Response status: ${response.statusCode}');

    if (response.isOk && response.body['data'] != null) {
      final rawList = asList(response.body['data']);
      getLogger('app').info(
        'âœ… [SHOP INVENTORY API] Successfully fetched ${rawList.length} items',
      );
      return rawList
          .map((i) => ShopInventoryItem.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } else {
      getLogger('app').info('âŒ [SHOP INVENTORY API] Error: ${response.body?['message']}');
      throw Exception(
        response.body?['message'] ?? 'Failed to load shop inventory',
      );
    }
  }

  /// Adds an existing master inventory item to a shop's stock.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/stock-in`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "items": [
  ///       {
  ///         "productId": "uuid-master-product-1",
  ///         "quantity": 50
  ///       }
  ///     ]
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200/201
  /// - __Body (JSON):__ Success confirmation
  Future<bool> addStockToShop(
    String shopId,
    String productId,
    int quantity,
    {String? clientOperationId}
  ) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    final opId = clientOperationId ?? const Uuid().v4();

    if (_appConfig.localStorageOnly) {
      final db = Get.find<LocalDatabaseService>();
      final actorId = await _authService.getUserId() ?? 'unknown';
      final ok = await db.addStockToShopLocal(
        shopId: shopId,
        productId: productId,
        quantity: quantity,
        actorId: actorId,
        clientOperationId: opId,
      );
      return ok;
    }

    final payload = {
      'clientOperationId': opId,
      'items': [
        {'productId': productId, 'quantity': quantity},
      ],
    };
    final response = await _connect.post(
      '$_merchantBaseUrl/$shopId/stock-in',
      payload,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception(
        response.body?['message'] ?? 'Failed to add stock to shop',
      );
    }
  }

  /// Fetches a list of shops for the merchant.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ A list of `Shop` objects.
  Future<List<Shop>> getShops() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        Shop(
          id: 'shop-1',
          merchantId: 'merchant-1',
          name: 'Downtown Store',
          address: '123 Main St',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Shop(
          id: 'shop-2',
          merchantId: 'merchant-1',
          name: 'Uptown Mall',
          address: '456 Market Ave',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }
    // Local-only mode: return shops from the local database
    if (_appConfig.localStorageOnly) {
      try {
        final db = Get.find<LocalDatabaseService>();
        // Prefer merchant-scoped shops when available; otherwise return all local shops
        final merchantId = _authService.user.value?.merchantId;
        List<Map<String, dynamic>> rows;
        if (merchantId != null && merchantId.isNotEmpty) {
          rows = await db.listShopsForMerchant(merchantId);
        } else {
          rows = await db.getAll('shops');
        }
        return rows.map((r) => Shop.fromJson(r)).toList();
      } catch (e) {
        throw Exception('Failed to load shops from local DB: $e');
      }
    }

    try {
      final response = await _connect.get(
        _merchantBaseUrl,
        headers: await _getHeaders(),
      );
      getLogger('app').info('getShops response: ${response.body}');
      if (response.isOk &&
          response.body != null &&
          response.body['data'] != null) {
        final data = response.body['data'];
        if (data is List) {
          return data.map((item) {
            if (item is Map<String, dynamic>) {
              return Shop.fromJson(item);
            } else {
              throw Exception('Invalid shop data format');
            }
          }).toList();
        } else {
          throw Exception('Expected list of shops but got ${data.runtimeType}');
        }
      } else {
        throw Exception(response.body?['message'] ?? 'Failed to load shops');
      }
    } catch (e) {
      throw Exception('Failed to load shops: $e');
    }
  }

  /// Fetches inventory items for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/products`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ A list of `InventoryItem` objects with stock info.
  Future<List<InventoryItem>> getInventoryForShop(String shopId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 800));
      return List.generate(
        10,
        (i) => InventoryItem(
          id: 'item-$i',
          merchantId: 'merchant-1',
          name: 'Product $i',
          sku: 'SKU-$i',
          sellingPrice: 15.0 + i,
          originalPrice: 10.0 + i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          stockInfo: [
            StockInfo(quantity: 20 + i * 5, shopId: shopId, shopName: 'Shop'),
          ],
        ),
      );
    }

    try {
      if (_appConfig.localStorageOnly) {
        final db = Get.find<LocalDatabaseService>();
        final rows = await db.getInventoryForShopLocal(shopId);
        return rows.map((r) => InventoryItem.fromJson(r)).toList();
      }

      final response = await _connect.get(
        '$_merchantBaseUrl/$shopId/products',
        headers: await _getHeaders(),
      );
      getLogger('app').info('getInventoryForShop response: ${response.body}');
      if (response.isOk &&
          response.body != null &&
          response.body['data'] != null) {
        final data = response.body['data'];
        if (data is List) {
          return data.map((item) {
            if (item is Map<String, dynamic>) {
              return InventoryItem.fromJson(item);
            } else {
              throw Exception('Invalid inventory item data format');
            }
          }).toList();
        } else {
          throw Exception(
            'Expected list of inventory items but got ${data.runtimeType}',
          );
        }
      } else {
        throw Exception(
          response.body?['message'] ?? 'Failed to load inventory for shop',
        );
      }
    } catch (e) {
      throw Exception('Failed to load inventory for shop: $e');
    }
  }

  /// Fetches stock movement history for a specific item in a shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/inventory/{itemId}/movements`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ A list of `StockMovement` objects.
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/inventory/{itemId}/history`
  Future<List<StockMovement>> getMovementHistory(
    String shopId,
    String itemId,
  ) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 600));
      return List.generate(
        5,
        (i) => StockMovement(
          id: 'movement-$i',
          itemId: itemId,
          shopId: shopId,
          movementType: i % 2 == 0 ? 'stock_in' : 'sale',
          quantityChanged: i % 2 == 0 ? 10 : -5,
          newQuantity: 50 - i * 5,
          userId: 'user-1',
          movementDate: DateTime.now().subtract(Duration(days: i)),
          reason: 'Test movement $i',
        ),
      );
    }

    if (_appConfig.localStorageOnly) {
      final db = Get.find<LocalDatabaseService>();
      final rows = await db.getMovementHistoryLocal(shopId, itemId);
      getLogger('app').info('[ShopInventoryApiService] Local movement history for shop:$shopId item:$itemId rows=${rows.length}');
      for(int a = 0; a < rows.length; a++) {
        getLogger('app').info('Row $a: ${rows[a]}');
      }

      final enrichedRows = await Future.wait(rows.map((r) async {
        final userId = r['userId'] ?? r['user_id'] ?? r['actorId'] ?? r['actor_id'];
        if (userId != null) {
          final user = await db.getUserById(userId.toString());
          if (user != null) {
            r['userName'] = user['name'] ?? user['displayName'] ?? user['username'];
            r['user_name'] = r['userName'];
          }
        }
        return r;
      }));

      return enrichedRows.map((r) => StockMovement.fromJson(r)).toList();
    }

    final response = await _connect.get(
      '$_merchantBaseUrl/$shopId/inventory/$itemId/history',
      headers: await _getHeaders(),
    );

    if (response.isOk && response.body['data'] != null) {
      final rawList = asList(response.body['data']);
      return rawList
          .map((i) => StockMovement.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } else {
      throw Exception(
        response.body?['message'] ?? 'Failed to load movement history',
      );
    }
  }

  /// Adjusts stock for a specific item in a shop.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/inventory/{itemId}/adjust`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "quantity": 10,
  ///     "reason": "inventory_correction"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  Future<void> adjustStock({
    required String shopId,
    required String itemId,
    required int quantity,
    String? reason,
    String? clientOperationId,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    final payload = {
      'clientOperationId': clientOperationId ?? const Uuid().v4(),
      'quantity': quantity,
      if (reason != null) 'reason': reason,
    };

    final opId = payload['clientOperationId'] as String;
    if (_appConfig.localStorageOnly) {
      final db = Get.find<LocalDatabaseService>();
      final actorId = await _authService.getUserId() ?? 'unknown';
      await db.adjustStockLocal(
        shopId: shopId,
        itemId: itemId,
        quantity: quantity,
        actorId: actorId,
        reason: reason,
        clientOperationId: opId,
      );
      return;
    }

    final response = await _connect.post(
      '$_merchantBaseUrl/$shopId/inventory/$itemId/adjust',
      payload,
      headers: await _getHeaders(),
    );

    if (!response.isOk) {
      throw Exception(response.body?['message'] ?? 'Failed to adjust stock');
    }
  }

  /// Bulk stock-in for multiple items (can add new items or update existing)
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/stock-in`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "items": [
  ///       {"productId": "item-1", "quantity": 10},
  ///       {"productId": "item-2", "quantity": 5}
  ///     ]
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  Future<void> bulkStockIn({
    required String shopId,
    required List<Map<String, dynamic>> items,
    String? clientOperationId,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    final payload = {
      'clientOperationId': clientOperationId ?? const Uuid().v4(),
      'items': items,
    };

    getLogger('app').info('bulkStockIn calling: $_merchantBaseUrl/$shopId/stock-in');
    getLogger('app').info('bulkStockIn payload: $payload');
    getLogger('app').info('bulkStockIn localStorageOnly: ${_appConfig.localStorageOnly}');

    final opId = payload['clientOperationId'] as String;
    if (_appConfig.localStorageOnly) {
      final db = Get.find<LocalDatabaseService>();
      final actorId = await _authService.getUserId() ?? 'unknown';

      // Ensure our local inventory catalog has metadata for bulk stock-in items.
      for (final it in items) {
        final itemId = it['productId'] as String? ?? it['product_id'] as String? ?? it['id'] as String?;
        if (itemId == null) continue;

        // Preserve existing inventory metadata; apply data when available from UI.
        final upsert = <String, dynamic>{'id': itemId};
        if (it.containsKey('merchantId')) upsert['merchant_id'] = it['merchantId'];
        if (it.containsKey('name')) upsert['name'] = it['name'];
        if (it.containsKey('description')) upsert['description'] = it['description'];
        if (it.containsKey('sku')) upsert['sku'] = it['sku'];
        if (it.containsKey('sellingPrice')) upsert['selling_price'] = it['sellingPrice'];
        if (it.containsKey('originalPrice')) upsert['original_price'] = it['originalPrice'];
        if (it.containsKey('lowStockThreshold')) upsert['low_stock_threshold'] = it['lowStockThreshold'];
        if (it.containsKey('category')) upsert['category'] = it['category'];
        if (it.containsKey('categoryId')) upsert['category_id'] = it['categoryId'];
        if (it.containsKey('subcategoryId')) upsert['subcategory_id'] = it['subcategoryId'];
        if (it.containsKey('brandId')) upsert['brand_id'] = it['brandId'];
        if (it.containsKey('supplier')) upsert['supplier_id'] = it['supplier'];

        if (upsert.length > 1) {
          await db.upsertInventoryItem(upsert);
        }
      }

      await db.bulkStockInLocal(
        shopId: shopId,
        items: items,
        actorId: actorId,
        clientOperationId: opId,
      );
      return;
    }

    final response = await _connect.post(
      '$_merchantBaseUrl/$shopId/stock-in',
      payload,
      headers: await _getHeaders(),
    );

    getLogger('app').info('bulkStockIn response: ${response.body}');

    if (!response.isOk) {
      throw Exception(response.body?['message'] ?? 'Failed to stock-in items');
    }
  }
}


