import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:smart_retail/app/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

class MerchantShopsApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

  // Manages the mock list locally to ensure data persists across hot reloads.
  final List<Shop> _mockShops = [];

  String get _baseUrl => '${ApiConstants.baseUrl}/merchant/shops';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
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
      'entity_type': 'shop',
      'action': action,
      'method': action == 'delete' ? 'DELETE' : (action == 'update' ? 'PUT' : 'POST'),
      'endpoint': endpoint,
      'payload': payload,
      'headers': {'X-Client-Operation-Id': clientOperationId},
    });
  }

  /// Fetches a list of shops for the current merchant.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "status": "success",
  ///     "data": [
  ///       {
  ///         "id": "uuid-shop-1",
  ///         "name": "Main Street Branch",
  ///         "address": "123 Main St",
  ///         "merchantId": "uuid-merchant-1",
  ///         "createdAt": "2023-01-01T12:00:00Z",
  ///         "updatedAt": "2023-01-01T12:00:00Z"
  ///       }
  ///     ]
  ///   }
  ///   ```
  Future<List<Shop>> listShops() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      // Start with generated mock shops
      if (_mockShops.isEmpty) {
        _mockShops.addAll(
          List.generate(
            5,
            (index) => Shop(
              id: 'shop-$index',
              name: 'Shop Branch $index',
              address: '$index Branch Street, City',
              merchantId: 'mock-merchant-id',
              createdAt: DateTime.now().subtract(Duration(days: index * 10)),
              updatedAt: DateTime.now().subtract(Duration(days: index * 10)),
            ),
          ),
        );
      }
      // Also include any shops persisted in the local DB for the current merchant
      try {
        final merchantId = _authService.user.value?.merchantId ?? '';
        final localRows = await _localDatabaseService.listShopsForMerchant(merchantId);
        final localShops = localRows.map((r) => Shop.fromJson({
              'id': r['id'],
              'name': r['name'],
              'address': r['address'],
              'merchantId': r['merchantId'] ?? r['merchant_id'],
            'taxRate': r['taxRate'] ?? r['tax_rate'],
            'deliveryCharge': r['deliveryCharge'] ?? r['delivery_charge'],
            'isActive': r['isActive'] ?? r['is_active'],
            'isPrimary': r['isPrimary'] ?? r['is_primary'],
              'createdAt': r['createdAt'] ?? r['created_at'],
              'updatedAt': r['updatedAt'] ?? r['updated_at'],
            })).toList();
        return [..._mockShops, ...localShops];
      } catch (_) {
        return _mockShops;
      }
    }

    // Local-only: fetch from local DB
    if (_appConfig.localStorageOnly) {
      try {
          // Determine merchantId robustly: prefer populated user.merchantId, else fall back to stored userId
          String merchantId = _authService.user.value?.merchantId ?? '';
          if ((merchantId.isEmpty)) {
            merchantId = _authService.userId.value ?? '';
          }
          if ((merchantId.isEmpty)) {
            // As a last resort, call getUserId() which may read persisted storage
            merchantId = await _authService.getUserId() ?? '';
          }
          final rows = await _localDatabaseService.listShopsForMerchant(merchantId);
        try { getLogger('app').info('[MerchantShopsApiService] Local listShops for merchantId=$merchantId returned ${rows.length} rows'); } catch (_) {}
        try { getLogger('app').info('[MerchantShopsApiService] Local rows: $rows'); } catch (_) {}
        return rows.map((r) => Shop.fromJson({
          'id': r['id'],
          'name': r['name'],
          'address': r['address'],
          'merchantId': r['merchantId'] ?? r['merchant_id'],
          'taxRate': r['taxRate'] ?? r['tax_rate'],
          'deliveryCharge': r['deliveryCharge'] ?? r['delivery_charge'],
          'isActive': r['isActive'] ?? r['is_active'],
          'isPrimary': r['isPrimary'] ?? r['is_primary'],
          'createdAt': r['createdAt'] ?? r['created_at'],
          'updatedAt': r['updatedAt'] ?? r['updated_at'],
        })).toList();
      } catch (e) {
        throw Exception('Local fetch shops failed: $e');
      }
    }

    final response = await _connect.get(_baseUrl, headers: await _getHeaders());

    if (response.isOk && response.body['data'] != null) {
      final rawList = asList(response.body['data']);
      return rawList
          .map((i) => Shop.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } else {
      throw Exception(response.body?['message'] ?? 'Failed to load shops');
    }
  }
  
  Future<Shop?> getShopById(String shopId) async {
    if (shopId.isEmpty) return null;

    if (_appConfig.localStorageOnly) {
      try {
        final row = await _localDatabaseService.getShopById(shopId);
        if (row == null) return null;
        return Shop.fromJson({
          'id': row['id'],
          'name': row['name'],
          'address': row['address'],
          'merchantId': row['merchantId'] ?? row['merchant_id'],
          'taxRate': row['taxRate'] ?? row['tax_rate'],
          'deliveryCharge': row['deliveryCharge'] ?? row['delivery_charge'],
          'isActive': row['isActive'] ?? row['is_active'],
          'isPrimary': row['isPrimary'] ?? row['is_primary'],
          'createdAt': row['createdAt'] ?? row['created_at'],
          'updatedAt': row['updatedAt'] ?? row['updated_at'],
        });
      } catch (e) {
        throw Exception('Local getShopById failed: $e');
      }
    }

    final response = await _connect.get(
      '$_baseUrl/$shopId',
      headers: await _getHeaders(),
    );

    if (response.isOk && response.body['data'] != null) {
      return Shop.fromJson(asMap(response.body['data']));
    }

    throw Exception(response.body?['message'] ?? 'Failed to load shop');
  }

  /// Creates a new shop for the current merchant.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/shops`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "name": "New Outlet",
  ///     "address": "456 Market St"
  ///   }
  ///   ```
  Future<Shop> createShop(String name, String address) async {
    final clientOperationId = const Uuid().v4();
    final payload = {'name': name, 'address': address, 'clientOperationId': clientOperationId};
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final newShop = Shop(
        id: 'shop-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        address: address,
        merchantId: 'mock-merchant-id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockShops.add(newShop);
      return newShop;
    }

    // Local-only
    if (_appConfig.localStorageOnly) {
      final id = clientOperationId;
      final merchantId = _authService.user.value?.merchantId;
      if (merchantId == null || merchantId.isEmpty) {
        throw Exception('Merchant ID not available in local mode');
      }
      final payloadLocal = {
        'id': id,
        'merchant_id': merchantId,
        'name': name,
        'address': address,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      try {
        getLogger('app').info('[MerchantShopsApiService] Local createShop payload: $payloadLocal');
      } catch (_) {}
      await _localDatabaseService.upsertShop(payloadLocal);
      try { getLogger('app').info('[MerchantShopsApiService] Local createShop persisted id=$id'); } catch (_) {}
      return Shop(
        id: id,
        name: name,
        address: address,
        merchantId: merchantId,
        taxRate: 5.0,
        deliveryCharge: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    try {
      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.post(_baseUrl, payload, headers: headers);

      if (response.isOk && response.body['data'] != null) {
        return Shop.fromJson(asMap(response.body['data']));
      }
      throw Exception(response.body?['message'] ?? 'Failed to create shop');
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'create',
          endpoint: _baseUrl,
          payload: payload,
        );
        return Shop(
          id: clientOperationId,
          name: name,
          address: address,
          merchantId: 'pending',
          taxRate: 5.0,
          deliveryCharge: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      throw Exception(e.toString());
    }
  }

  /// Updates an existing shop.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "name": "Updated Outlet Name",
  ///     "address": "789 Commerce Ave"
  ///   }
  ///   ```
  Future<Shop> updateShop(String shopId, String name, String address) async {
    final clientOperationId = const Uuid().v4();
    final payload = {'name': name, 'address': address, 'clientOperationId': clientOperationId};
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final index = _mockShops.indexWhere((s) => s.id == shopId);
      if (index != -1) {
        final updatedShop = Shop(
          id: shopId,
          name: name,
          address: address,
          merchantId: _mockShops[index].merchantId,
          createdAt: _mockShops[index].createdAt,
          updatedAt: DateTime.now(),
        );
        _mockShops[index] = updatedShop;
        return updatedShop;
      }
      throw Exception('Mock shop not found');
    }

    // Local-only
    if (_appConfig.localStorageOnly) {
      final merchantId = _authService.user.value?.merchantId;
      if (merchantId == null || merchantId.isEmpty) {
        throw Exception('Merchant ID not available in local mode');
      }
      final payloadLocal = {
        'id': shopId,
        'merchant_id': merchantId,
        'name': name,
        'address': address,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _localDatabaseService.upsertShop(payloadLocal);
      return Shop(
        id: shopId,
        name: name,
        address: address,
        merchantId: payloadLocal['merchant_id'] as String,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    try {
      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.put('$_baseUrl/$shopId', payload, headers: headers);

      if (response.isOk && response.body['data'] != null) {
        return Shop.fromJson(asMap(response.body['data']));
      }
      throw Exception(response.body?['message'] ?? 'Failed to update shop');
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'update',
          endpoint: '$_baseUrl/$shopId',
          payload: payload,
        );
        return Shop(
          id: shopId,
          name: name,
          address: address,
          merchantId: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      throw Exception(e.toString());
    }
  }

  /// Deletes a shop by its ID.
  ///
  /// __Request:__
  /// - __Method:__ DELETE
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}`
  Future<void> deleteShop(String shopId) async {
    final clientOperationId = const Uuid().v4();
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));
      _mockShops.removeWhere((s) => s.id == shopId);
      return;
    }
    // Local-only
    if (_appConfig.localStorageOnly) {
      await _localDatabaseService.deleteShop(shopId);
      return;
    }

    try {
      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.delete(
        '$_baseUrl/$shopId',
        headers: headers,
      );

      if (!response.isOk) {
        throw Exception(response.body?['message'] ?? 'Failed to delete shop');
      }
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'delete',
          endpoint: '$_baseUrl/$shopId',
          payload: {'shopId': shopId},
        );
        return;
      }
      throw Exception(e.toString());
    }
  }
}
