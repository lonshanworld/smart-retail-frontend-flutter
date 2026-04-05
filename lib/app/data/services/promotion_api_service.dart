import 'dart:convert';

import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:uuid/uuid.dart';

class PromotionApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

  String get _promotionsUrl => '${ApiConstants.baseUrl}/merchant/promotions';
  String get _shopsUrl => '${ApiConstants.baseUrl}/merchant/shops';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<String?> _resolveMerchantIdForLocal() async {
    final user = _authService.user.value;
    if (user == null) return null;

    String? merchantId = user.merchantId;

    if (merchantId != null && merchantId.isNotEmpty) {
      return merchantId;
    }

    if (user.role == 'merchant' && user.id.isNotEmpty) {
      return user.id;
    }

    if (user.assignedShopId != null && user.assignedShopId!.isNotEmpty) {
      final shop = await _localDatabaseService.getShopById(user.assignedShopId!);
      if (shop != null) {
        merchantId = (shop['merchantId'] ?? shop['merchant_id'])?.toString();
        if (merchantId != null && merchantId.isNotEmpty) {
          return merchantId;
        }
      }
    }

    return null;
  }

  bool _shouldQueue(dynamic error) {
    final text = error.toString().toLowerCase();
    return _appConfig.localStorageOnly ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection') ||
        text.contains('timeout');
  }

  Future<void> _queueMutation({
    required String clientOperationId,
    required String action,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    await _localDatabaseService.queueOperation({
      'id': clientOperationId,
      'client_operation_id': clientOperationId,
      'entity_type': 'promotion',
      'action': action,
      'method': action == 'delete' ? 'DELETE' : (action == 'update' ? 'PUT' : 'POST'),
      'endpoint': endpoint,
      'payload': payload,
      'headers': {'X-Client-Operation-Id': clientOperationId},
    });
  }

  /// Fetches shops for the merchant.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops`
  Future<List<Shop>> getShops() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 400));
      return List.generate(
        3,
        (i) => Shop(
          id: 'shop-$i',
          name: 'Shop Branch $i',
          merchantId: 'merch-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
    if (_appConfig.localStorageOnly) {
      final merchantId = await _resolveMerchantIdForLocal();
      final rows = merchantId == null || merchantId.isEmpty
        ? await _localDatabaseService.getAll('shops')
        : await _localDatabaseService.listShopsForMerchant(merchantId);
      return rows
          .map((r) => Shop.fromJson(r))
          .toList();
    }

    final response = await _connect.get(
      _shopsUrl,
      headers: await _getHeaders(),
    );
    if (response.isOk && response.body['data'] != null) {
      final raw = response.body['data'];
      final normalized = _normalizeData(raw);
      return (normalized as List)
          .map((json) => Shop.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } else {
      throw Exception(response.body?['message'] ?? 'Failed to load shops');
    }
  }

  /// Fetches inventory items for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/products`
  Future<List<InventoryItem>> getProductsForShop(String shopId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 600));
      return List.generate(
        10,
        (i) => InventoryItem(
          id: 'prod-$i',
          name: 'Product $i from Shop $shopId',
          sku: 'SKU$i',
          merchantId: 'merch-1',
          sellingPrice: 10.0 + i,
          originalPrice: 7.0 + i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
    if (_appConfig.localStorageOnly) {
      final rows = await _localDatabaseService.getInventoryForShopLocal(shopId);
      return rows.map((r) => InventoryItem.fromJson(r)).toList();
    }

    final response = await _connect.get(
      '$_shopsUrl/$shopId/products',
      headers: await _getHeaders(),
    );
    if (response.isOk && response.body['data'] != null) {
      final raw = response.body['data'];
      final normalized = _normalizeData(raw);
      return (normalized as List)
          .map(
            (json) => InventoryItem.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } else {
      throw Exception(
        response.body?['message'] ?? 'Failed to load products for shop',
      );
    }
  }

  /// Fetches a paginated list of promotions.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/promotions`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `page`: `int`
  ///   - `pageSize`: `int`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A paginated response of promotion objects)
  Future<PaginatedPromotionsResponse> getPromotions({
    int page = 1,
    int pageSize = 10,
  }) async {
    print('[PromotionApiService] getPromotions page=$page pageSize=$pageSize');
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final items = [
        Promotion(
          id: 'promo-1',
          name: '20% Off Laptops',
          description: 'Discount on all laptops',
          type: 'percentage',
          value: 20,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 10)),
          shopId: 'shop-0',
          merchantId: 'merch-1',
          minSpend: 0,
          conditions: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Promotion(
          id: 'promo-2',
          name: 'Buy One Get One Free',
          description: 'On select T-shirts',
          type: 'bogo',
          value: 1,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 5)),
          shopId: 'shop-1',
          merchantId: 'merch-1',
          minSpend: 0,
          conditions: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      return PaginatedPromotionsResponse(
        items: items,
        totalItems: items.length,
        currentPage: 1,
        totalPages: 1,
      );
    }
    if (_appConfig.localStorageOnly) {
      final merchantId = await _resolveMerchantIdForLocal();
      if (merchantId == null || merchantId.isEmpty) {
        throw Exception('Merchant ID not available in local mode');
      }
      print('[PromotionApiService] getPromotions localStorageOnly for merchantId=$merchantId');
      final rows = await _localDatabaseService.listPromotionsForMerchant(merchantId, onlyActive: false);
      print('[PromotionApiService] getPromotions local rows=${rows.length}');
      final promotions = rows.map((r) => Promotion.fromJson(r)).toList();
      final total = promotions.length;
      final start = (page - 1) * pageSize;
      final end = (start + pageSize) > total ? total : (start + pageSize);
      final pageItems = start < total ? promotions.sublist(start, end) : <Promotion>[];
      print('[PromotionApiService] getPromotions local pageItems=${pageItems.length} total=$total');
      return PaginatedPromotionsResponse(
        items: pageItems,
        totalItems: total,
        currentPage: page,
        totalPages: (total / pageSize).ceil(),
      );
    }

    final response = await _connect.get(
      _promotionsUrl,
      headers: await _getHeaders(),
      query: {'page': page.toString(), 'pageSize': pageSize.toString()},
    );

    if (response.statusCode == 200 && response.body['success'] == true) {
      final raw = response.body['data'];
      final normalized = _normalizeData(raw);
      return PaginatedPromotionsResponse.fromJson(normalized);
    } else {
      throw Exception(response.body?['message'] ?? 'Failed to load promotions');
    }
  }

  /// Creates a new promotion.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/promotions`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "name": "10% Off",
  ///     "description": "10% off on all items",
  ///     "type": "percentage",
  ///     "value": 10,
  ///     "startDate": "2023-11-01T00:00:00Z",
  ///     "endDate": "2023-11-30T23:59:59Z",
  ///     "shopId": "uuid-shop-1",
  ///     "productId": "uuid-product-1"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created promotion object)
  Future<Promotion> createPromotion(Map<String, dynamic> data) async {
    final clientOperationId = data['clientOperationId']?.toString() ?? const Uuid().v4();
    final payload = Map<String, dynamic>.from(data)..['clientOperationId'] = clientOperationId;
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Promotion.fromJson(
        data
          ..['id'] = 'new-promo-id'
          ..['merchantId'] = '1'
          ..['createdAt'] = DateTime.now().toIso8601String()
          ..['updatedAt'] = DateTime.now().toIso8601String(),
      );
    }
    try {
      if (_appConfig.localStorageOnly) {
        final merchantId = _authService.user.value?.merchantId;
        if (merchantId == null || merchantId.isEmpty) {
          throw Exception('Merchant ID not available in local mode');
        }
        payload['merchantId'] = payload['merchantId'] ?? payload['merchant_id'] ?? merchantId;
        payload['merchant_id'] = payload['merchant_id'] ?? payload['merchantId'];
        payload['isActive'] = payload['isActive'] ?? true;
        payload['active'] = payload['active'] ?? payload['isActive'];
        payload['is_active'] = payload['is_active'] ?? payload['active'];

        print('[PromotionApiService] local createPromotion payload: $payload');
        await _localDatabaseService.upsertPromotion(payload);

        final createdPromotion = Promotion.fromJson({
          ...payload,
          'id': payload['id'] ?? clientOperationId,
          'merchantId': payload['merchantId'],
          'merchant_id': payload['merchant_id'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
        print('[PromotionApiService] local createPromotion stored: ${createdPromotion.id}, merchantId: ${createdPromotion.merchantId}, isActive: ${createdPromotion.isActive}');
        return createdPromotion;
      }

      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.post(_promotionsUrl, payload, headers: headers);

      if (response.statusCode == 201 && response.body['success'] == true) {
        final raw = response.body['data'];
        final normalized = _normalizeData(raw);
        return Promotion.fromJson(Map<String, dynamic>.from(normalized));
      }
      throw Exception(
        response.body?['message'] ?? 'Failed to create promotion',
      );
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'create',
          endpoint: _promotionsUrl,
          payload: payload,
        );
        return Promotion.fromJson({
          ...payload,
          'id': clientOperationId,
          'merchantId': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      throw Exception(e.toString());
    }
  }

  /// Updates an existing promotion.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/merchant/promotions/{id}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (Fields to be updated)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated promotion object)
  Future<Promotion> updatePromotion(
    String id,
    Map<String, dynamic> data,
  ) async {
    final clientOperationId = data['clientOperationId']?.toString() ?? const Uuid().v4();
    final payload = Map<String, dynamic>.from(data)..['clientOperationId'] = clientOperationId;
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Promotion.fromJson(
        data
          ..['id'] = id
          ..['merchantId'] = '1'
          ..['createdAt'] = DateTime.now().toIso8601String()
          ..['updatedAt'] = DateTime.now().toIso8601String(),
      );
    }
    try {
      if (_appConfig.localStorageOnly) {
        final merchantId = _authService.user.value?.merchantId;
        if (merchantId == null || merchantId.isEmpty) {
          throw Exception('Merchant ID not available in local mode');
        }
        await _localDatabaseService.upsertPromotion({...payload, 'id': id});
        return Promotion.fromJson({
          ...payload,
          'id': id,
          'merchantId': payload['merchantId'] ?? payload['merchant_id'] ?? merchantId,
          'merchant_id': payload['merchant_id'] ?? payload['merchantId'] ?? merchantId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.put('$_promotionsUrl/$id', payload, headers: headers);

      if (response.statusCode == 200 && response.body['success'] == true) {
        return Promotion.fromJson(asMap(response.body['data']));
      }
      throw Exception(
        response.body?['message'] ?? 'Failed to update promotion',
      );
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'update',
          endpoint: '$_promotionsUrl/$id',
          payload: payload,
        );
        return Promotion.fromJson({
          ...payload,
          'id': id,
          'merchantId': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      throw Exception(e.toString());
    }
  }

  /// Normalize raw response data (handles JSArray/JSObject on web) into pure
  /// Dart List/Map structures by encoding->decoding JSON when necessary.
  dynamic _normalizeData(dynamic raw) {
    if (raw == null) return null;
    try {
      // jsonEncode/jsonDecode will convert JS interop objects into normal Dart
      // maps/lists on web (JSArray, JSObject) and is safe for already-Dart
      // collections as well.
      final encoded = jsonEncode(raw);
      return jsonDecode(encoded);
    } catch (e) {
      // Fallback: if encoding fails, return as-is (caller should handle types)
      return raw;
    }
  }

  /// Deletes a promotion.
  ///
  /// __Request:__
  /// - __Method:__ DELETE
  /// - __Endpoint:__ `/api/v1/merchant/promotions/{id}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ Success message
  Future<void> deletePromotion(String id) async {
    final clientOperationId = const Uuid().v4();
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    try {
      if (_appConfig.localStorageOnly) {
        await _localDatabaseService.database.then((db) => db.delete('promotions', where: 'id = ?', whereArgs: [id]));
        await _localDatabaseService.database.then((db) => db.delete('promotion_products', where: 'promotion_id = ?', whereArgs: [id]));
        return;
      }

      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.delete('$_promotionsUrl/$id', headers: headers);

      if (response.statusCode != 200 || response.body['success'] != true) {
        throw Exception(
          response.body?['message'] ?? 'Failed to delete promotion',
        );
      }
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'delete',
          endpoint: '$_promotionsUrl/$id',
          payload: {'promotionId': id},
        );
        return;
      }
      throw Exception(e.toString());
    }
  }

  /// Toggles the active status of a promotion.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/merchant/promotions/{id}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ `{ "isActive": true/false }`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated promotion object)
  Future<Promotion> togglePromotionStatus(String id, bool isActive) async {
    final clientOperationId = const Uuid().v4();
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));
      return Promotion(
        id: id,
        name: 'Mock Promotion',
        description: 'Mock description',
        type: 'percentage',
        value: 10,
        minSpend: 0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        merchantId: 'merch-1',
        conditions: {},
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    final payload = {'isActive': isActive, 'clientOperationId': clientOperationId};
    try {
      if (_appConfig.localStorageOnly) {
        final merchantId = _authService.user.value?.merchantId;
        if (merchantId == null || merchantId.isEmpty) {
          throw Exception('Merchant ID not available in local mode');
        }
        await _localDatabaseService.upsertPromotion({'id': id, 'is_active': isActive ? 1 : 0});
        return Promotion(
          id: id,
          name: 'Local Promotion',
          description: '',
          type: 'percentage',
          value: 0,
          minSpend: 0,
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          merchantId: merchantId,
          conditions: {},
          isActive: isActive,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.put('$_promotionsUrl/$id', payload, headers: headers);

      if (response.statusCode == 200 && response.body['success'] == true) {
        return Promotion.fromJson(asMap(response.body['data']));
      }
      throw Exception(
        response.body?['message'] ?? 'Failed to toggle promotion status',
      );
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'update',
          endpoint: '$_promotionsUrl/$id',
          payload: payload,
        );
        return Promotion(
          id: id,
          name: 'Pending Promotion',
          description: '',
          type: 'percentage',
          value: 0,
          minSpend: 0,
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          merchantId: 'pending',
          conditions: {},
          isActive: isActive,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      throw Exception(e.toString());
    }
  }
}
