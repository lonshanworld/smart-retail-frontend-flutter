import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:smart_retail/app/data/models/receipt_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/shop_stock_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/models/staff_dashboard_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/services/offline_sales_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class ShopApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();
  final OfflineSalesService? _offlineSalesService =
      Get.isRegistered<OfflineSalesService>()
      ? Get.find<OfflineSalesService>()
      : null;

  Future<String?> _getAuthToken() async {
    return await _authService.getToken();
  }

  final String _adminBaseUrl = "${ApiConstants.baseUrl}/admin";
  final String _staffBaseUrl = "${ApiConstants.baseUrl}/staff";

  final String _merchantShopsBaseUrl = "${ApiConstants.baseUrl}/merchant/shops";
  final String _merchantSalesBaseUrl = "${ApiConstants.baseUrl}/merchant/sales";

  void _handleError(Response response, String operation) {
    String errorMessage =
        response.body?['message'] ??
        "Unknown error occurred during $operation.";
    if (response.body?['data'] != null && response.body?['data'] is String) {
      errorMessage += " (${response.body?['data']})";
    }
    if (kDebugMode) {
      getLogger('app').info(
        'Error $operation: ${response.statusCode} - ${response.bodyString}',
      );
    }
    DialogUtils.showError(errorMessage);
  }

  bool _shouldQueue(dynamic error) {
    final text = error.toString().toLowerCase();
    return _appConfig.localStorageOnly ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection') ||
        text.contains('timeout');
  }

  Future<void> _queueOperation({
    required String clientOperationId,
    required String entityType,
    required String action,
    required String endpoint,
    required Map<String, dynamic> payload,
    String method = 'POST',
  }) async {
    await _localDatabaseService.queueOperation({
      'id': clientOperationId,
      'client_operation_id': clientOperationId,
      'entity_type': entityType,
      'action': action,
      'method': method,
      'endpoint': endpoint,
      'payload': payload,
      'headers': {'X-Client-Operation-Id': clientOperationId},
    });
  }

  // --- Shop Management (Merchant) ---

  /// Creates a new shop for the merchant.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/shops`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "name": "New Branch",
  ///     "address": "456 Market St"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created shop object)
  Future<Shop?> createShop(Shop shop) async {
    // Local-only: persist shop locally and return a local copy
    if (_appConfig.localStorageOnly) {
      final clientOperationId = const Uuid().v4();
      final now = DateTime.now();
      final merchantId =
          _authService.user.value?.merchantId ?? _authService.userId.value ??
          await _authService.getUserId() ??
          '';
      if (merchantId.isEmpty) {
        throw Exception('Merchant ID not available for shop creation.');
      }
      final toSave = {
        ...shop.toJsonForCreate(merchantId),
        'id': clientOperationId,
        'merchant_id': merchantId,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      await _localDatabaseService.upsertShop(toSave);
      return shop.copyWith(
        id: clientOperationId,
        merchantId: merchantId,
        createdAt: now,
        updatedAt: now,
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final clientOperationId = const Uuid().v4();
    final merchantId =
        _authService.user.value?.merchantId ?? _authService.userId.value ??
        await _authService.getUserId() ??
        '';
    final payload = {
      ...shop.toJsonForCreate(merchantId),
      'clientOperationId': clientOperationId,
    };

    try {
      final response = await _connect.post(
        _merchantShopsBaseUrl,
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode! < 300) {
        return Shop.fromJson(asMap(response.body['data']));
      }
      _handleError(response, "shop creation");
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'shop',
          action: 'create',
          endpoint: _merchantShopsBaseUrl,
          payload: payload,
        );
        return Shop(
          id: clientOperationId,
          merchantId: merchantId,
          name: shop.name,
          address: shop.address,
          isPrimary: shop.isPrimary,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  /// Fetches a list of all shops for the merchant.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A list of shop objects)
  Future<List<Shop>> listShops() async {
    final token = await _getAuthToken();
    if (token == null) return [];
    // Local-only mode: return shops from local DB
    if (_appConfig.localStorageOnly) {
      try {
        String merchantId = _authService.user.value?.merchantId ?? '';
        if (merchantId.isEmpty) {
          merchantId = _authService.userId.value ?? '';
        }
        if (merchantId.isEmpty) {
          merchantId = await _authService.getUserId() ?? '';
        }
        final rows = await _localDatabaseService.listShopsForMerchant(
          merchantId,
        );
        return rows.map((r) => Shop.fromJson(r)).toList();
      } catch (e) {
        if (kDebugMode) {
          getLogger('app').info('[ShopApiService] Local listShops failed: $e');
        }
        return [];
      }
    }

    final response = await _connect.get(
      _merchantShopsBaseUrl,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (kDebugMode) {
      getLogger('app').info('check merchant shop list ${response.body}');
    }
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      List<dynamic> shopListJson = asList(response.body['data']);
      return shopListJson
          .map((json) => Shop.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } else {
      _handleError(response, "listing shops");
      return [];
    }
  }

  /// Fetches a single shop by its ID.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The full shop object)
  Future<Shop?> getShopById(String shopId) async {
    // Local-only: fetch from local DB
    if (_appConfig.localStorageOnly) {
      try {
        final row = await _localDatabaseService.getShopById(shopId);
        if (row == null) return null;
        return Shop.fromJson({
          'id': row['id'],
          'merchantId': row['merchant_id'],
          'name': row['name'],
          'address': row['address'],
          'taxRate': row['tax_rate'],
          'deliveryCharge': row['delivery_charge'],
          'isActive': row['is_active'] == 1,
          'isPrimary': row['is_primary'] == 1,
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
        });
      } catch (e) {
        if (kDebugMode) {
          getLogger(
            'app',
          ).info('[ShopApiService] Local getShopById failed: $e');
        }
        return null;
      }
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final response = await _connect.get(
      '$_merchantShopsBaseUrl/$shopId',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return Shop.fromJson(asMap(response.body['data']));
    } else {
      _handleError(response, "fetching shop $shopId");
      return null;
    }
  }

  /// Updates an existing shop.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (Fields to be updated)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated shop object)
  Future<Shop?> updateShop(String shopId, Map<String, dynamic> updates) async {
    // Local-only: persist update locally
    if (_appConfig.localStorageOnly) {
      try {
        final clientOperationId =
            updates['clientOperationId']?.toString() ?? const Uuid().v4();
        final existingRow = await _localDatabaseService.getShopById(shopId);
        final parsedTaxRate =
            (updates['taxRate'] as num?)?.toDouble() ??
            (updates['tax_rate'] as num?)?.toDouble() ??
            (existingRow?['tax_rate'] as num?)?.toDouble() ??
            (existingRow?['taxRate'] as num?)?.toDouble() ??
            5.0;
        final merchantId =
            updates['merchantId']?.toString() ??
            updates['merchant_id']?.toString() ??
            existingRow?['merchant_id']?.toString() ??
            existingRow?['merchantId']?.toString() ??
            _authService.user.value?.merchantId ??
            _authService.userId.value ??
            await _authService.getUserId() ??
            '';
        final toSave = <String, dynamic>{
          ...?existingRow,
          ...updates,
          'id': shopId,
          'merchant_id': merchantId,
          'merchantId': merchantId,
          'tax_rate': parsedTaxRate,
          'taxRate': parsedTaxRate,
          'updated_at': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        await _localDatabaseService.upsertShop(toSave);
        await _queueOperation(
          clientOperationId: clientOperationId,
          action: 'update',
          endpoint: '$_merchantShopsBaseUrl/$shopId',
          entityType: 'shop',
          payload: toSave,
        );
        final row = await _localDatabaseService.getShopById(shopId);
        if (row == null) return null;
        final updatedShop = Shop.fromJson({
          'id': row['id'],
          'merchantId': row['merchant_id'],
          'name': row['name'],
          'address': row['address'],
          'taxRate': row['tax_rate'],
          'deliveryCharge': row['delivery_charge'],
          'isActive': row['is_active'] == 1,
          'isPrimary': row['is_primary'] == 1,
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
        });
        if (!_appConfig.localStorageOnly &&
            _authService.shopId.value == updatedShop.id) {
          await _authService.updateCurrentShop(updatedShop);
        }
        return updatedShop;
      } catch (e) {
        if (kDebugMode) {
          getLogger('app').info('[ShopApiService] Local updateShop failed: $e');
        }
        return null;
      }
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final clientOperationId =
        updates['clientOperationId']?.toString() ?? const Uuid().v4();
    final payload = Map<String, dynamic>.from(updates)
      ..['clientOperationId'] = clientOperationId;

    try {
      final response = await _connect.put(
        '$_merchantShopsBaseUrl/$shopId',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 200 && response.body['status'] == 'success') {
        final updatedShop = Shop.fromJson(asMap(response.body['data']));
        if (!_appConfig.localStorageOnly &&
            _authService.shopId.value == updatedShop.id) {
          await _authService.updateCurrentShop(updatedShop);
        }
        return updatedShop;
      }
      _handleError(response, "updating shop $shopId");
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'shop',
          action: 'update',
          endpoint: '$_merchantShopsBaseUrl/$shopId',
          payload: payload,
          method: 'PUT',
        );
        return Shop(
          id: shopId,
          merchantId: '',
          name: payload['name']?.toString() ?? '',
          address: payload['address']?.toString() ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  /// Sets a shop as the primary shop for the merchant.
  ///
  /// __Request:__
  /// - __Method:__ PATCH
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/set-primary`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated shop object)
  Future<Shop?> setPrimaryShop(String shopId) async {
    final token = await _getAuthToken();
    if (token == null) return null;
    final clientOperationId = const Uuid().v4();
    if (_appConfig.localStorageOnly) {
      try {
        final now = DateTime.now().toIso8601String();
        await _localDatabaseService.upsertShop({
          'id': shopId,
          'is_primary': 1,
          'updated_at': now,
        });
        final row = await _localDatabaseService.getShopById(shopId);
        if (row == null) return null;
        return Shop.fromJson({
          'id': row['id'],
          'merchantId': row['merchant_id'],
          'name': row['name'],
          'address': row['address'],
          'taxRate': row['tax_rate'],
          'deliveryCharge': row['delivery_charge'],
          'isActive': row['is_active'] == 1,
          'isPrimary': row['is_primary'] == 1,
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
        });
      } catch (e) {
        if (kDebugMode) {
          getLogger(
            'app',
          ).info('[ShopApiService] Local setPrimaryShop failed: $e');
        }
        return null;
      }
    }
    try {
      final response = await _connect.patch(
        '$_merchantShopsBaseUrl/$shopId/set-primary',
        {'clientOperationId': clientOperationId},
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 200 && response.body['status'] == 'success') {
        final updatedShop = Shop.fromJson(asMap(response.body['data']));
        if (!_appConfig.localStorageOnly &&
            _authService.shopId.value == updatedShop.id) {
          await _authService.updateCurrentShop(updatedShop);
        }
        return updatedShop;
      }
      _handleError(response, "setting shop $shopId as primary");
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'shop',
          action: 'update',
          endpoint: '$_merchantShopsBaseUrl/$shopId/set-primary',
          payload: {'clientOperationId': clientOperationId},
          method: 'PATCH',
        );
        return Shop(
          id: shopId,
          merchantId: '',
          name: 'Primary Shop',
          address: 'Pending primary update',
          isPrimary: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  /// Deletes a shop.
  ///
  /// __Request:__
  /// - __Method:__ DELETE
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  Future<bool> deleteShop(String shopId) async {
    // Local-only: delete locally
    if (_appConfig.localStorageOnly) {
      try {
        await _localDatabaseService.deleteShop(shopId);
        return true;
      } catch (e) {
        if (kDebugMode) {
          getLogger('app').info('[ShopApiService] Local deleteShop failed: $e');
        }
        return false;
      }
    }
    final token = await _getAuthToken();
    if (token == null) return false;
    final clientOperationId = const Uuid().v4();
    try {
      final response = await _connect.delete(
        '$_merchantShopsBaseUrl/$shopId',
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 200 && response.body['status'] == 'success') {
        return true;
      }
      _handleError(response, "deleting shop $shopId");
      return false;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'shop',
          action: 'delete',
          endpoint: '$_merchantShopsBaseUrl/$shopId',
          payload: {'shopId': shopId},
          method: 'DELETE',
        );
        return true;
      }
      rethrow;
    }
  }

  /// Preflight check whether a shop can be safely deleted.
  /// Returns a map like: { 'deletable': true/false, 'blockers': { 'sales': 3, ... } }
  Future<Map<String, dynamic>?> checkShopDeletable(String shopId) async {
    final token = await _getAuthToken();
    if (token == null) return null;
    final response = await _connect.get(
      '$_merchantShopsBaseUrl/$shopId/delete-check',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return Map<String, dynamic>.from(asMap(response.body['data']));
    } else {
      _handleError(response, "checking deletable for shop $shopId");
      return null;
    }
  }

  // --- Admin Shop Management ---

  /// Fetches a paginated list of all shops for admins.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/admin/shops`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__ (all optional)
  ///   - `page`: `int`
  ///   - `pageSize`: `int`
  ///   - `name`: `string`
  ///   - `isActive`: `bool`
  ///   - `merchantId`: `string`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A paginated response of shop objects)
  Future<PaginatedAdminShopsResponse?> adminListShops({
    int page = 1,
    int pageSize = 10,
    String? nameFilter,
    bool? isActiveFilter,
    String? merchantIdFilter,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final shops = [
        Shop(
          id: '1',
          merchantId: '1',
          name: 'Mock Shop 1',
          address: '123 Mock St',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Shop(
          id: '2',
          merchantId: '2',
          name: 'Mock Shop 2',
          address: '456 Mock St',
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      return PaginatedAdminShopsResponse(
        shops: shops,
        pagination: PaginationInfo(
          totalItems: 2,
          currentPage: 1,
          pageSize: 10,
          totalPages: 1,
        ),
      );
    }

    final token = await _getAuthToken();
    if (token == null) return null;

    final queryParameters = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (nameFilter != null && nameFilter.isNotEmpty) {
      queryParameters['name'] = nameFilter;
    }
    if (isActiveFilter != null) {
      queryParameters['isActive'] = isActiveFilter.toString();
    }
    if (merchantIdFilter != null && merchantIdFilter.isNotEmpty) {
      queryParameters['merchantId'] = merchantIdFilter;
    }

    final response = await _connect.get(
      '$_adminBaseUrl/shops',
      headers: {'Authorization': 'Bearer $token'},
      query: queryParameters,
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      if (response.body['data'] is Map<String, dynamic> ||
          response.body['data'] != null) {
        return PaginatedAdminShopsResponse.fromJson(
          asMap(response.body['data']),
        );
      } else {
        if (kDebugMode) {
          getLogger('app').info(
            'Error admin listing shops: response.body[\'data\'] is not a Map.',
          );
        }
        _handleError(
          Response(
            statusCode: 500,
            statusText: 'Invalid response format from server',
            body: {'message': 'Invalid data structure in response.'},
          ),
          "admin listing shops",
        );
        return null;
      }
    } else {
      _handleError(response, "admin listing shops");
      return null;
    }
  }

  /// Creates a new shop as an admin.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/admin/shops`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (A shop object with merchantId)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created shop object)
  Future<Shop?> adminCreateShop(Shop shop) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return shop.copyWith(id: 'new-admin-shop-id');
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final clientOperationId = const Uuid().v4();
    final payload = {
      ...shop.toJsonForAdminCreate(),
      'clientOperationId': clientOperationId,
    };
    try {
      final response = await _connect.post(
        '$_adminBaseUrl/shops',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 201 && response.body['status'] == 'success') {
        return Shop.fromJson(asMap(response.body['data']));
      }
      _handleError(response, "admin creating shop");
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_shop',
          action: 'create',
          endpoint: '$_adminBaseUrl/shops',
          payload: payload,
        );
        return Shop(
          id: clientOperationId,
          merchantId: payload['merchantId']?.toString() ?? '',
          name: shop.name,
          address: shop.address,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  /// Fetches a single shop by its ID as an admin.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/admin/shops/{shopId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The full shop object)
  Future<Shop?> adminGetShopById(String shopId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Shop(
        id: shopId,
        merchantId: '1',
        name: 'Admin Shop $shopId',
        address: 'Admin Address $shopId',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final response = await _connect.get(
      '$_adminBaseUrl/shops/$shopId',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return Shop.fromJson(asMap(response.body['data']));
    } else {
      _handleError(response, "admin fetching shop $shopId");
      return null;
    }
  }

  /// Updates a shop as an admin.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/admin/shops/{shopId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (Fields to be updated)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated shop object)
  Future<Shop?> adminUpdateShop(
    String shopId,
    Map<String, dynamic> updates,
  ) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Shop(
        id: shopId,
        merchantId: '1',
        name: updates['name'],
        address: updates['address'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final clientOperationId =
        updates['clientOperationId']?.toString() ?? const Uuid().v4();
    final payload = Map<String, dynamic>.from(updates)
      ..['clientOperationId'] = clientOperationId;
    try {
      final response = await _connect.put(
        '$_adminBaseUrl/shops/$shopId',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 200 && response.body['status'] == 'success') {
        return Shop.fromJson(asMap(response.body['data']));
      }
      _handleError(response, "admin updating shop $shopId");
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_shop',
          action: 'update',
          endpoint: '$_adminBaseUrl/shops/$shopId',
          payload: payload,
          method: 'PUT',
        );
        return Shop(
          id: shopId,
          merchantId: '',
          name: payload['name']?.toString() ?? '',
          address: payload['address']?.toString() ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  /// Deletes a shop as an admin.
  ///
  /// __Request:__
  /// - __Method:__ DELETE
  /// - __Endpoint:__ `/api/v1/admin/shops/{shopId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  Future<bool> adminDeleteShop(String shopId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    final token = await _getAuthToken();
    if (token == null) return false;
    final clientOperationId = const Uuid().v4();
    try {
      final response = await _connect.delete(
        '$_adminBaseUrl/shops/$shopId',
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 200 && response.body['status'] == 'success') {
        return true;
      }
      _handleError(response, "admin deleting shop $shopId");
      return false;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_shop',
          action: 'delete',
          endpoint: '$_adminBaseUrl/shops/$shopId',
          payload: {'shopId': shopId},
          method: 'DELETE',
        );
        return true;
      }
      rethrow;
    }
  }

  /// Sets the active status of a shop as an admin.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/admin/shops/{shopId}/status`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "isActive": true
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  Future<bool> adminSetShopActiveStatus(String shopId, bool isActive) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    final token = await _getAuthToken();
    if (token == null) return false;
    final clientOperationId = const Uuid().v4();
    final payload = {
      'isActive': isActive,
      'clientOperationId': clientOperationId,
    };
    try {
      final response = await _connect.put(
        '$_adminBaseUrl/shops/$shopId/status',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 200 && response.body['status'] == 'success') {
        return true;
      }
      _handleError(response, "admin setting shop $shopId status to $isActive");
      return false;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_shop',
          action: 'update',
          endpoint: '$_adminBaseUrl/shops/$shopId/status',
          payload: payload,
          method: 'PUT',
        );
        return true;
      }
      rethrow;
    }
  }

  // --- Shop Stock Management (Merchant) ---

  /// Fetches the inventory for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/inventory`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `page`: `int`
  ///   - `pageSize`: `int`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A paginated response of shop stock items)
  Future<PaginatedShopStockResponse?> listInventoryForShop(
    String shopId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      // Corrected Mock data for shop stock with pagination
      if (page > 1) {
        // If the page is not the first one, return an empty list to stop pagination.
        return PaginatedShopStockResponse(
          items: [],
          totalItems: 15,
          currentPage: page,
          pageSize: pageSize,
          totalPages: 2,
        ); // Assuming 2 pages total
      }
      final items = [
        ShopStockItem(
          id: 'ss1',
          shopId: shopId,
          inventoryItemId: 'item1',
          itemName: 'Laptop',
          itemSku: 'LP123',
          itemUnitPrice: 1200.0,
          quantity: 15,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ShopStockItem(
          id: 'ss2',
          shopId: shopId,
          inventoryItemId: 'item2',
          itemName: 'Wireless Mouse',
          itemSku: 'MO456',
          itemUnitPrice: 25.0,
          quantity: 50,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ShopStockItem(
          id: 'ss3',
          shopId: shopId,
          inventoryItemId: 'item3',
          itemName: 'USB-C Hub',
          itemSku: 'HUB789',
          itemUnitPrice: 45.0,
          quantity: 30,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ShopStockItem(
          id: 'ss4',
          shopId: shopId,
          inventoryItemId: 'item4',
          itemName: 'Gaming Keyboard',
          itemSku: 'GK101',
          itemUnitPrice: 75.0,
          quantity: 20,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ShopStockItem(
          id: 'ss5',
          shopId: shopId,
          inventoryItemId: 'item5',
          itemName: '4K Webcam',
          itemSku: 'WC4K',
          itemUnitPrice: 99.0,
          quantity: 25,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ShopStockItem(
          id: 'ss6',
          shopId: shopId,
          inventoryItemId: 'item6',
          itemName: 'Bluetooth Speaker',
          itemSku: 'BS-500',
          itemUnitPrice: 60.0,
          quantity: 40,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ShopStockItem(
          id: 'ss7',
          shopId: shopId,
          inventoryItemId: 'item7',
          itemName: 'External SSD 1TB',
          itemSku: 'SSD1T',
          itemUnitPrice: 110.0,
          quantity: 18,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ShopStockItem(
          id: 'ss8',
          shopId: shopId,
          inventoryItemId: 'item8',
          itemName: 'Noise-Cancelling Headphones',
          itemSku: 'NCH-800',
          itemUnitPrice: 150.0,
          quantity: 22,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ShopStockItem(
          id: 'ss9',
          shopId: shopId,
          inventoryItemId: 'item9',
          itemName: 'Smartwatch',
          itemSku: 'SW-2023',
          itemUnitPrice: 250.0,
          quantity: 12,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ShopStockItem(
          id: 'ss10',
          shopId: shopId,
          inventoryItemId: 'item10',
          itemName: 'Tablet',
          itemSku: 'TB-10',
          itemUnitPrice: 450.0,
          quantity: 10,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      return PaginatedShopStockResponse(
        items: items,
        totalItems: 15,
        currentPage: 1,
        pageSize: 10,
        totalPages: 2,
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final queryParameters = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    final response = await _connect.get(
      '$_merchantShopsBaseUrl/$shopId/inventory',
      headers: {'Authorization': 'Bearer $token'},
      query: queryParameters,
    );
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return PaginatedShopStockResponse.fromJson(asMap(response.body['data']));
    } else {
      _handleError(response, "listing inventory for shop $shopId");
      return null;
    }
  }

  /// Adds stock for an item in a shop.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/inventory/{inventoryItemId}/stock-in`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "quantityAdded": 50
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated shop stock item)
  Future<ShopStockItem?> stockInItem(
    String shopId,
    String inventoryItemId,
    int quantityAdded, {
    String? clientOperationId,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return ShopStockItem(
        id: '1',
        shopId: shopId,
        inventoryItemId: inventoryItemId,
        quantity: quantityAdded,
        lastStockedInAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        itemName: 'Item Name',
        itemUnitPrice: 10.0,
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    clientOperationId ??= const Uuid().v4();
    final body = {
      'clientOperationId': clientOperationId,
      'quantityAdded': quantityAdded,
    };
    try {
      final response = await _connect.post(
        '$_merchantShopsBaseUrl/$shopId/inventory/$inventoryItemId/stock-in',
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 200 && response.body['status'] == 'success') {
        return ShopStockItem.fromJson(asMap(response.body['data']));
      }
      _handleError(
        response,
        "stocking in item $inventoryItemId for shop $shopId",
      );
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'shop_stock',
          action: 'create',
          endpoint:
              '$_merchantShopsBaseUrl/$shopId/inventory/$inventoryItemId/stock-in',
          payload: body,
        );
        return ShopStockItem(
          id: clientOperationId,
          shopId: shopId,
          inventoryItemId: inventoryItemId,
          quantity: quantityAdded,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          itemName: 'Pending item',
          itemUnitPrice: 0,
        );
      }
      rethrow;
    }
  }

  /// Adjusts the stock for an item in a shop.
  ///
  /// __Request:__
  /// - __Method:__ PATCH
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/inventory/{inventoryItemId}/adjust-stock`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "adjustmentType": "damage",
  ///     "quantityChange": 5,
  ///     "reason": "Damaged in transit"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated shop stock item)
  Future<ShopStockItem?> adjustStockItem({
    required String shopId,
    required String inventoryItemId,
    required String adjustmentType,
    required int quantityChange,
    String? reason,
    String? clientOperationId,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return ShopStockItem(
        id: '1',
        shopId: shopId,
        inventoryItemId: inventoryItemId,
        quantity: 100 - quantityChange,
        lastStockedInAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        itemName: 'Item Name',
        itemUnitPrice: 10.0,
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final resolvedClientOperationId = clientOperationId ?? const Uuid().v4();
    final Map<String, dynamic> body = {
      'clientOperationId': resolvedClientOperationId,
      'adjustmentType': adjustmentType,
      'quantityChange': quantityChange,
    };
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }
    try {
      final response = await _connect.patch(
        '$_merchantShopsBaseUrl/$shopId/inventory/$inventoryItemId/adjust-stock',
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': resolvedClientOperationId,
        },
      );
      if (response.statusCode == 200 && response.body['status'] == 'success') {
        return ShopStockItem.fromJson(asMap(response.body['data']));
      }
      _handleError(response, "adjusting stock for item $inventoryItemId");
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: resolvedClientOperationId,
          entityType: 'shop_stock',
          action: 'update',
          endpoint:
              '$_merchantShopsBaseUrl/$shopId/inventory/$inventoryItemId/adjust-stock',
          payload: body,
          method: 'PATCH',
        );
        return ShopStockItem(
          id: resolvedClientOperationId,
          shopId: shopId,
          inventoryItemId: inventoryItemId,
          quantity: quantityChange,
          lastStockedInAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          itemName: 'Pending item',
          itemUnitPrice: 0,
        );
      }
      rethrow;
    }
  }

  // --- Sales Management (Merchant) ---

  /// Creates a new sale.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/sales`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (A `CreateSaleInput` object)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created sale object)
  Future<Sale?> createSale(CreateSaleInput saleData) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Sale(
        id: 'new-sale-id',
        shopId: saleData.shopId,
        merchantId: '1',
        saleDate: DateTime.now(),
        totalAmount: 100.0,
        deliveryCharge: 0.0,
        paymentType: saleData.paymentType,
        paymentStatus: 'succeeded',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [],
      );
    }

    // Local-only mode: persist sale locally and return constructed Sale
    if (_appConfig.localStorageOnly) {
      try {
        final saleMap = saleData.toJson();
        final clientSaleId = saleMap['id'] ?? const Uuid().v4();
        final merchantId =
            saleMap['merchantId'] ?? saleMap['merchant_id'] ?? 'local-merchant';

        final safeSaleData = <String, dynamic>{
          'id': clientSaleId,
          'client_sale_id': clientSaleId,
          'shop_id': saleMap['shopId'] ?? saleMap['shop_id'],
          'merchant_id': merchantId,
          'sale_date': DateTime.now().toIso8601String(),
          'total_amount': (saleMap['totalAmount'] as num?)?.toDouble() ?? 0.0,
          'discount_amount':
              (saleMap['discountAmount'] as num?)?.toDouble() ?? 0.0,
          'applied_promotion_id':
              saleMap['appliedPromotionId'] ?? saleMap['applied_promotion_id'],
          'delivery_charge':
              (saleMap['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
          'payment_type':
              saleMap['paymentType'] ?? saleMap['payment_type'] ?? 'cash',
          'payment_status': 'succeeded',
          'customer_id': saleMap['customerId'] ?? saleMap['customer_id'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        getLogger('app').info(
          'DEBUG [ShopApiService] local createSale safeSaleData: $safeSaleData',
        );

        final createdSaleId = await _localDatabaseService.createSaleLocal(
          safeSaleData,
        );

        final itemRows = (saleMap['items'] as List<dynamic>?) ?? [];
        for (var i = 0; i < itemRows.length; i++) {
          final itemData = itemRows[i];
          if (itemData is Map<String, dynamic>) {
            final itemId =
                itemData['productId']?.toString() ??
                '${DateTime.now().microsecondsSinceEpoch}_$i';
            await _localDatabaseService.createSaleItemLocal({
              'id': 'sale_item_${itemId}_$createdSaleId',
              'sale_id': createdSaleId,
              'inventory_item_id': itemId,
              'item_name': itemData['itemName'] ?? '',
              'item_sku': itemData['itemSku'] ?? itemData['sku'] ?? '',
              'quantity_sold': (itemData['quantity'] as num?)?.toInt() ?? 0,
              'selling_price_at_sale':
                  (itemData['sellingPriceAtSale'] as num?)?.toDouble() ?? 0.0,
              'original_price_at_sale':
                  (itemData['originalPriceAtSale'] as num?)?.toDouble(),
              'subtotal':
                  ((itemData['quantity'] as num?)?.toInt() ?? 0) *
                  ((itemData['sellingPriceAtSale'] as num?)?.toDouble() ?? 0.0),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        }

        final saleRow = await _localDatabaseService.getSaleById(createdSaleId);
        final itemsRows = await _localDatabaseService.getSaleItemsForSale(
          createdSaleId,
        );

        final saleItems = itemsRows.map((row) {
          return SaleItem(
            id: row['id'] as String,
            saleId: row['sale_id'] as String,
            inventoryItemId: row['inventory_item_id'] as String,
            quantitySold: (row['quantity_sold'] as num).toInt(),
            sellingPriceAtSale: (row['selling_price_at_sale'] as num)
                .toDouble(),
            originalPriceAtSale: row['original_price_at_sale'] != null
                ? (row['original_price_at_sale'] as num).toDouble()
                : null,
            subtotal: (row['subtotal'] as num).toDouble(),
            createdAt: DateTime.parse(row['created_at'] as String),
            updatedAt: DateTime.parse(row['updated_at'] as String),
            itemName: row['item_name'] as String?,
            itemSku: row['item_sku'] as String?,
          );
        }).toList();

        final now = DateTime.now();
        return Sale(
          id: saleRow?['id'] as String? ?? createdSaleId,
          shopId: saleRow?['shop_id'] as String? ?? saleData.shopId,
          merchantId: saleRow?['merchant_id'] as String? ?? '',
          saleDate: DateTime.parse(
            saleRow?['sale_date'] ?? now.toIso8601String(),
          ),
          totalAmount:
              (saleRow?['total_amount'] as num?)?.toDouble() ??
              (saleMap['totalAmount'] as num?)?.toDouble() ??
              0.0,
          deliveryCharge:
              (saleRow?['delivery_charge'] as num?)?.toDouble() ??
              (saleMap['deliveryCharge'] as num?)?.toDouble() ??
              0.0,
          appliedPromotionId:
            saleRow?['applied_promotion_id'] as String? ??
            saleMap['appliedPromotionId'] as String?,
          discountAmount:
            (saleRow?['discount_amount'] as num?)?.toDouble() ??
            (saleMap['discountAmount'] as num?)?.toDouble() ??
            0.0,
          items: saleItems,
          paymentType:
              saleRow?['payment_type'] as String? ?? saleData.paymentType,
          paymentStatus: saleRow?['payment_status'] as String? ?? 'pending',
          createdAt: DateTime.parse(
            saleRow?['created_at'] ?? now.toIso8601String(),
          ),
          updatedAt: DateTime.parse(
            saleRow?['updated_at'] ?? now.toIso8601String(),
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          getLogger('app').info('[ShopApiService] Local createSale failed: $e');
        }
        return null;
      }
    }

    final token = await _getAuthToken();
    if (token == null) return null;
    final Map<String, dynamic> saleMap = saleData.toJson();
    final clientSaleId = saleMap['id'] ?? const Uuid().v4();
    final payload = {
      ...saleMap,
      'id': clientSaleId,
      'clientSaleId': clientSaleId,
    };

    try {
      final response = await _connect.post(
        _merchantSalesBaseUrl,
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientSaleId,
        },
      );

      if (response.statusCode == 201 && response.body['status'] == 'success') {
        return Sale.fromJson(asMap(response.body['data']));
      }
      _handleError(response, "creating sale");
      return null;
    } catch (e) {
      if (_offlineSalesService != null) {
        await _offlineSalesService.processSale(payload);
        return Sale(
          id: clientSaleId,
          shopId: saleData.shopId,
          merchantId: '',
          saleDate: DateTime.now(),
          totalAmount: 0.0,
          deliveryCharge: 0.0,
          paymentType: saleData.paymentType,
          paymentStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: const [],
        );
      }
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientSaleId,
          entityType: 'merchant_sale',
          action: 'create',
          endpoint: _merchantSalesBaseUrl,
          payload: payload,
        );
      }
      rethrow;
    }
  }

  /// Fetches a paginated list of sales for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops/{shopId}/sales`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `page`: `int`
  ///   - `pageSize`: `int`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A paginated response of sale objects)
  Future<PaginatedSalesResponse?> listSalesForShop(
    String shopId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return PaginatedSalesResponse(
        items: [],
        totalItems: 0,
        currentPage: 1,
        pageSize: 10,
        totalPages: 0,
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;

    final queryParameters = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final response = await _connect.get(
      '$_merchantShopsBaseUrl/$shopId/sales',
      headers: {'Authorization': 'Bearer $token'},
      query: queryParameters,
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return PaginatedSalesResponse.fromJson(asMap(response.body['data']));
    } else {
      _handleError(response, "listing sales for shop $shopId");
      return null;
    }
  }

  /// Fetches a single sale by its ID.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/sales/{saleId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The full sale object)
  Future<Sale?> getSaleById(String saleId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Sale(
        id: saleId,
        shopId: '1',
        merchantId: '1',
        saleDate: DateTime.now(),
        totalAmount: 100.0,
        deliveryCharge: 0.0,
        paymentType: 'card',
        paymentStatus: 'succeeded',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [],
      );
    }

    // Local-only mode: return sale from local database
    if (_appConfig.localStorageOnly) {
      try {
        final saleRow = await _localDatabaseService.getSaleById(saleId);
        if (saleRow == null) return null;

        final itemsRows = await _localDatabaseService.getSaleItemsForSale(
          saleId,
        );
        final saleItems = itemsRows.map((row) {
          return SaleItem(
            id: row['id'] as String,
            saleId: row['sale_id'] as String,
            inventoryItemId: row['inventory_item_id'] as String,
            quantitySold: (row['quantity_sold'] as num).toInt(),
            sellingPriceAtSale: (row['selling_price_at_sale'] as num)
                .toDouble(),
            originalPriceAtSale: row['original_price_at_sale'] != null
                ? (row['original_price_at_sale'] as num).toDouble()
                : null,
            subtotal: (row['subtotal'] as num).toDouble(),
            createdAt: DateTime.parse(row['created_at'] as String),
            updatedAt: DateTime.parse(row['updated_at'] as String),
            itemName: row['item_name'] as String?,
            itemSku: row['item_sku'] as String?,
          );
        }).toList();

        return Sale(
          id: saleRow['id'] as String,
          shopId: saleRow['shop_id'] as String,
          merchantId: saleRow['merchant_id'] as String,
          saleDate: DateTime.parse(saleRow['sale_date'] as String),
          totalAmount: (saleRow['total_amount'] as num).toDouble(),
          deliveryCharge:
              (saleRow['delivery_charge'] as num?)?.toDouble() ?? 0.0,
          appliedPromotionId:
            saleRow['applied_promotion_id'] as String? ??
            saleRow['appliedPromotionId'] as String?,
          discountAmount:
            (saleRow['discount_amount'] as num?)?.toDouble() ?? 0.0,
          items: saleItems,
          paymentType: saleRow['payment_type'] as String? ?? 'unknown',
          paymentStatus: saleRow['payment_status'] as String? ?? 'pending',
          createdAt: DateTime.parse(saleRow['created_at'] as String),
          updatedAt: DateTime.parse(saleRow['updated_at'] as String),
        );
      } catch (e) {
        if (kDebugMode) {
          getLogger(
            'app',
          ).info('[ShopApiService] Local getSaleById failed: $e');
        }
        return null;
      }
    }
    final token = await _getAuthToken();
    if (token == null) return null;

    final response = await _connect.get(
      '$_merchantSalesBaseUrl/$saleId',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return Sale.fromJson(asMap(response.body['data']));
    } else {
      _handleError(response, "fetching sale $saleId");
      return null;
    }
  }

  /// Fetches a receipt for a specific sale.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/sales/{saleId}/receipt`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The receipt object)
  Future<Receipt?> getReceipt(String saleId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Receipt(
        saleId: saleId,
        saleDate: DateTime.now(),
        shopName: 'Mock Shop',
        shopAddress: 'Mock Address',
        merchantName: 'Mock Merchant',
        originalTotal: 100.0,
        discountAmount: 10.0,
        deliveryCharge: 0.0,
        finalTotal: 90.0,
        paymentType: 'card',
        paymentStatus: 'succeeded',
        items: [],
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final response = await _connect.get(
      '$_merchantSalesBaseUrl/$saleId/receipt',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.isOk && response.body['data'] != null) {
      return Receipt.fromJson(asMap(response.body['data']));
    } else {
      _handleError(response, "fetching receipt");
      return null;
    }
  }

  // --- Staff Dashboard ---

  /// Fetches the summary for the staff dashboard.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/staff/dashboard/summary`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "assignedShopName": "Main Street Shop",
  ///     "salesToday": 1250.75,
  ///     "transactionsToday": 15,
  ///     "recentActivities": [
  ///       {
  ///         "type": "sale",
  ///         "timestamp": "2023-10-29T14:00:00Z",
  ///         "details": "Sale of $50.25 to John Doe",
  ///         "relatedId": "uuid-sale-1"
  ///       }
  ///     ]
  ///   }
  ///   ```
  Future<StaffDashboardSummaryResponse?> getStaffDashboardSummary() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return StaffDashboardSummaryResponse(
        assignedShopName: 'Mock Shop',
        salesToday: 1234.56,
        transactionsToday: 15,
        recentActivities: [],
      );
    }
    final token = await _getAuthToken();
    if (token == null) {
      DialogUtils.showError(
        "You are not logged in or your session has expired.",
      );
      return null;
    }

    final response = await _connect.get(
      '$_staffBaseUrl/dashboard/summary', // Endpoint path
      headers: {'Authorization': 'Bearer $token'},
    );

    if (kDebugMode) {
      if (kDebugMode) {
        getLogger('app').info(
          'Staff Dashboard Summary Response Status: ${response.statusCode}',
        );
        getLogger(
          'app',
        ).info('Staff Dashboard Summary Response Body: ${response.bodyString}');
      }
    }

    if (response.statusCode == 200 && response.body != null) {
      try {
        return StaffDashboardSummaryResponse.fromJson(
          response.body as Map<String, dynamic>,
        );
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) {
            getLogger('app').info('Error parsing staff dashboard summary: $e');
          }
        }
        _handleError(
          Response(
            statusCode: 500,
            statusText: 'Invalid response format',
            body: {'message': 'Error parsing dashboard data from server.'},
          ),
          "fetching staff dashboard summary",
        );
        return null;
      }
    } else {
      String errorMessage = "Failed to fetch staff dashboard summary.";
      if (response.body is Map && response.body['message'] != null) {
        errorMessage = response.body['message'];
      } else if (response.statusText != null &&
          response.statusText!.isNotEmpty) {
        errorMessage = response.statusText!;
      }
      DialogUtils.showError(
        // Fallback error dialog
        errorMessage,
      );
      return null;
    }
  }
}
