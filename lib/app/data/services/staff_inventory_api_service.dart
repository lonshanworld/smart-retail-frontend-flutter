import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/data/models/shop_inventory_item.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

// This service handles inventory operations from the STAFF'S perspective for their assigned shop.
class StaffInventoryApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDb = Get.find<LocalDatabaseService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/shop/inventory';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication token not found');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches a list of inventory items for the staff's current shop.
  /// The backend uses the token to identify the shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/shop/inventory`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ A list of `ShopInventoryItem` objects.
  Future<List<ShopInventoryItem>> getInventoryItems() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return List.generate(
        15,
        (i) => ShopInventoryItem(
          id: 'shop-item-$i',
          productId: 'prod-$i',
          name: 'Product for Staff $i',
          sku: 'SKU-STAFF-$i',
          quantity: 30 + i * 2,
          sellingPrice: 12.0 + i,
        ),
      );
    }

    // Local-only mode: return cached/local inventory from the local DB
    if (_appConfig.localStorageOnly) {
      final shopId = await _authService.getShopId();
      if (shopId == null) throw Exception('No shop selected for staff user');
      final rows = await _localDb.getInventoryForShopLocal(shopId);
      return rows.map((r) {
        final stockInfo = r['stockInfo'] as List<dynamic>? ?? [];
        final qty = stockInfo.isNotEmpty ? (stockInfo.first['quantity'] as int?) ?? 0 : 0;
        return ShopInventoryItem(
          id: r['id'] as String,
          productId: r['id'] as String,
          name: r['name'] as String,
          sku: r['sku'] as String?,
          quantity: qty,
          sellingPrice: (r['selling_price'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    }

    final response = await _connect.get(_baseUrl, headers: await _getHeaders());
    if (response.isOk && response.body['data'] != null) {
      final rawList = asList(response.body['data']);
      return rawList
          .map((i) => ShopInventoryItem.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } else {
      throw Exception(
        response.body?['message'] ?? 'Failed to load shop inventory',
      );
    }
  }

  /// Updates the quantities of items in the shop's inventory (Stock In).
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/shop/inventory/stock-in`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "items": [
  ///       { "productId": "uuid-product-1", "quantity": 50 },
  ///       { "productId": "uuid-product-2", "quantity": 30 }
  ///     ]
  ///   }
  ///   ```
  Future<void> updateStock(
    List<Map<String, dynamic>> items, {
    String? clientOperationId,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 2));
      getLogger('app').info('Mock Staff Stock Update for ${items.length} items.');
      return;
    }

    // Local-only mode: apply stock changes to local DB and queue if needed.
    if (_appConfig.localStorageOnly) {
      final shopId = await _authService.getShopId();
      if (shopId == null) throw Exception('No shop selected for staff user');
      final actorId = await _authService.getUserId() ?? 'local_actor';
      final opId = clientOperationId ?? const Uuid().v4();
      await _localDb.bulkStockInLocal(
        shopId: shopId,
        items: items,
        actorId: actorId,
        clientOperationId: opId,
      );
      return;
    }

    final response = await _connect.post(
      '$_baseUrl/stock-in',
      {
        'clientOperationId': clientOperationId ?? const Uuid().v4(),
        'items': items,
      },
      headers: await _getHeaders(),
    );
    if (!response.isOk) {
      throw Exception(response.body?['message'] ?? 'Failed to update stock');
    }
  }
}

