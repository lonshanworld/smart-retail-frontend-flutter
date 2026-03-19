import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:smart_retail/app/data/models/merchant_model.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:uuid/uuid.dart';

class AdminMerchantService extends GetxService {
  final GetConnect _connect = GetConnect(timeout: const Duration(seconds: 30));
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

  final String _adminMerchantsBaseUrl =
      "${ApiConstants.baseUrl}/admin/merchants";
  final String _adminUsersBaseUrl = "${ApiConstants.baseUrl}/admin/users";

  Future<String?> _getAuthToken() async {
    return await _authService.getToken();
  }

  void _handleError(
    Response response,
    String operation, {
    String? defaultMessage,
  }) {
    String errorMessage =
        response.body?['message'] ??
        defaultMessage ??
        "Unknown error during $operation.";
    if (response.body?['data'] != null && response.body?['data'] is String) {
      errorMessage += " (${response.body?['data']})";
    }
    if (kDebugMode) {
      print(
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

  /// Fetches a paginated list of merchants.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/admin/merchants`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `page`: `int`
  ///   - `pageSize`: `int`
  ///   - `name`: `string`
  ///   - `email`: `string`
  ///   - `isActive`: `bool`
  ///   - `userId`: `string`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A paginated response of merchant objects)
  Future<PaginatedAdminMerchantsResponse?> listMerchants({
    int page = 1,
    int pageSize = 10,
    String? nameFilter,
    String? emailFilter,
    bool? isActiveFilter,
    String? userIdFilter,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));
      // MOCK DATA IMPLEMENTATION
      final mockMerchants = List.generate(
        25,
        (index) => Merchant(
          id: 'merchant_id_${index + 1}',
          name: 'Mock Merchant ${index + 1}',
          email: 'merchant${index + 1}@example.com',
          isActive: (index % 4 != 0), // Make every 4th one inactive
          shopName: 'Shop ${index + 1}',
          createdAt: DateTime.now().subtract(Duration(days: 30 - index)),
          updatedAt: DateTime.now().subtract(Duration(hours: 10 * index)),
        ),
      );

      var filteredMerchants = mockMerchants;
      if (nameFilter != null && nameFilter.isNotEmpty) {
        filteredMerchants = filteredMerchants
            .where(
              (m) => m.name.toLowerCase().contains(nameFilter.toLowerCase()),
            )
            .toList();
      }
      if (emailFilter != null && emailFilter.isNotEmpty) {
        filteredMerchants = filteredMerchants
            .where(
              (m) => m.email.toLowerCase().contains(emailFilter.toLowerCase()),
            )
            .toList();
      }
      if (isActiveFilter != null) {
        filteredMerchants = filteredMerchants
            .where((m) => m.isActive == isActiveFilter)
            .toList();
      }

      return PaginatedAdminMerchantsResponse(
        merchants: filteredMerchants
            .skip((page - 1) * pageSize)
            .take(pageSize)
            .toList(),
        pagination: PaginationInfo(
          totalItems: filteredMerchants.length,
          totalPages: (filteredMerchants.length / pageSize).ceil(),
          currentPage: page,
          pageSize: pageSize,
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
    if (emailFilter != null && emailFilter.isNotEmpty) {
      queryParameters['email'] = emailFilter;
    }
    if (isActiveFilter != null) {
      queryParameters['isActive'] = isActiveFilter.toString();
    }
    if (userIdFilter != null && userIdFilter.isNotEmpty) {
      queryParameters['userId'] = userIdFilter;
    }

    if (kDebugMode) {
      print(
        '[AdminMerchantService] Listing merchants with query: $queryParameters',
      );
    }

    final response = await _connect.get(
      _adminMerchantsBaseUrl,
      headers: {'Authorization': 'Bearer $token'},
      query: queryParameters,
    );
    print('checking respnose ${response.body}');
    print('is true mapping? ${response.body['data'] is Map<String, dynamic>}');
    if (response.statusCode == 200) {
      return PaginatedAdminMerchantsResponse.fromJson(response.body);
    } else {
      _handleError(response, "listing merchants");
      return null;
    }
  }

  /// Fetches a single merchant by their ID.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/admin/merchants/{merchantIdOrUserId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The full merchant object)
  Future<Merchant?> getMerchantById(String merchantIdOrUserId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Merchant(
        id: merchantIdOrUserId,
        name: 'Mock Merchant',
        email: 'merchant@test.com',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;

    final response = await _connect.get(
      '$_adminMerchantsBaseUrl/$merchantIdOrUserId',
      headers: {'Authorization': 'Bearer $token'},
    );
    print('checking get merchant response ${response.body}');

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return Merchant.fromJson(asMap(response.body['data']));
    } else {
      _handleError(response, "fetching merchant $merchantIdOrUserId");
      return null;
    }
  }

  /// Creates a new user with the role of merchant.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/admin/users`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (User data with role set to 'merchant')
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created user object)
  Future<User?> createUserAsMerchant(Map<String, dynamic> userData) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return User.fromJson(
        userData
          ..['id'] = 'new-merchant-id'
          ..['role'] = 'merchant',
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final clientOperationId = userData['clientOperationId']?.toString() ??
        const Uuid().v4();
    final payload = Map<String, dynamic>.from(userData)
      ..['role'] = 'MERCHANT'
      ..['clientOperationId'] = clientOperationId;

    try {
      final response = await _connect.post(
        _adminUsersBaseUrl,
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode! < 300) {
        final user = User.fromJsonWithShop(asMap(response.body['data']));
        return user;
      }
      _handleError(response, "creating user as merchant");
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_merchant_user',
          action: 'create',
          endpoint: _adminUsersBaseUrl,
          payload: payload,
        );
        return User.fromJson({
          ...payload,
          'id': clientOperationId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      rethrow;
    }
  }

  /// Updates the details of a user/merchant.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/admin/users/{userId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (Fields to be updated)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated user object)
  Future<User?> updateUserMerchantDetails(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return User.fromJson(
        updates
          ..['id'] = userId
          ..['role'] = 'merchant',
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final clientOperationId = updates['clientOperationId']?.toString() ??
        const Uuid().v4();
    final payload = Map<String, dynamic>.from(updates)
      ..['clientOperationId'] = clientOperationId;

    try {
      final response = await _connect.put(
        '$_adminUsersBaseUrl/$userId',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 200) {
        return User.fromJson(asMap(response.body['data']));
      }
      _handleError(response, "updating user/merchant details for $userId");
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_merchant_user',
          action: 'update',
          endpoint: '$_adminUsersBaseUrl/$userId',
          payload: payload,
          method: 'PUT',
        );
        return User.fromJson({
          ...payload,
          'id': userId,
          'role': 'merchant',
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      rethrow;
    }
  }

  /// Sets the active status of a merchant's user account.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/admin/users/{userId}/status`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "is_active": true
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  Future<bool> setMerchantUserActiveStatus(String userId, bool isActive) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 300));
      print('Mock status update for $userId to $isActive');
      return true;
    }
    final token = await _getAuthToken();
    if (token == null) return false;
    final clientOperationId = const Uuid().v4();
    final payload = {'isActive': isActive, 'clientOperationId': clientOperationId};
    try {
      final response = await _connect.put(
        '$_adminUsersBaseUrl/$userId',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 200 && response.body['status'] == 'success') {
        DialogUtils.showSuccess("Merchant status updated successfully.");
        return true;
      }
      _handleError(response, "updating merchant status");
      return false;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_merchant_user',
          action: 'update',
          endpoint: '$_adminUsersBaseUrl/$userId',
          payload: payload,
          method: 'PUT',
        );
        return true;
      }
      rethrow;
    }
  }

  /// Deletes a user/merchant.
  ///
  /// __Request:__
  /// - __Method:__ DELETE
  /// - __Endpoint:__ `/api/v1/admin/users/{userId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200 or 204
  Future<bool> deleteUserMerchant(String userId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));
      print('Mock delete for $userId');
      return true;
    }
    final token = await _getAuthToken();
    if (token == null) return false;
    final clientOperationId = const Uuid().v4();
    try {
      final response = await _connect.delete(
        '$_adminUsersBaseUrl/$userId',
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode == 200 && response.body['status'] == 'success') {
        DialogUtils.showSuccess("User $userId deleted successfully.");
        return true;
      }
      _handleError(response, "deleting user $userId");
      return false;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_merchant_user',
          action: 'delete',
          endpoint: '$_adminUsersBaseUrl/$userId',
          payload: {'userId': userId},
          method: 'DELETE',
        );
        return true;
      }
      rethrow;
    }
  }
}
