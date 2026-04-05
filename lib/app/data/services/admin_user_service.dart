import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/data/models/admin_paginated_users_response.dart'; // <<< ADDED IMPORT
import 'package:smart_retail/app/data/models/user_selection_item.dart'; // <<< ADDED IMPORT
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class AdminUserService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

  final String _adminUsersBaseUrl = "${ApiConstants.baseUrl}/admin/users";

  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = _authService.authToken.value;
    if (token == null) {
      getLogger('app').info("Auth token is null in AdminUserService");
      return null;
    }
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

  /// Fetches a paginated list of users.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/admin/users`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `page`: `int`
  ///   - `pageSize`: `int`
  ///   - `role`: `string`
  ///   - `is_active`: `bool`
  ///   - `q`: `string` (search term)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A paginated response of user objects)
  Future<AdminPaginatedUsersResponse?> listUsers({
    int page = 1,
    int pageSize = 10,
    String? role,
    bool? isActive,
    String? searchTerm,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final users = [
        User(
          id: '1',
          name: 'Test Merchant',
          email: 'merchant@test.com',
          role: 'merchant',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        User(
          id: '2',
          name: 'Test Staff',
          email: 'staff@test.com',
          role: 'staff',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        User(
          id: '3',
          name: 'Inactive User',
          email: 'inactive@test.com',
          role: 'merchant',
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      return AdminPaginatedUsersResponse(
        users: users,
        currentPage: 1,
        totalPages: 1,
        pageSize: 10,
        totalCount: 3,
      );
    }
    final headers = await _getAuthHeaders();
    if (headers == null) return null;

    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['q'] = searchTerm;
    }

    final response = await _connect.get(
      _adminUsersBaseUrl,
      query: queryParams,
      headers: headers,
    );
    if (_appConfig.localStorageOnly) {
      try {
        final rows = await _localDatabaseService.listAllUsers(role: role);
        // Apply isActive and searchTerm filters locally
        var filtered = rows;
        if (isActive != null) {
          filtered = filtered.where((r) => ((r['is_active'] as int?) ?? 1) == (isActive ? 1 : 0)).toList();
        }
        if (searchTerm != null && searchTerm.isNotEmpty) {
          final q = searchTerm.toLowerCase();
          filtered = filtered.where((r) => (r['name'] as String?)?.toLowerCase().contains(q) == true || (r['email'] as String?)?.toLowerCase().contains(q) == true).toList();
        }
        final total = filtered.length;
        final start = (page - 1) * pageSize;
        final pageItems = filtered.skip(start).take(pageSize).map((r) => User.fromJson(r)).toList();
        return AdminPaginatedUsersResponse(
          users: pageItems,
          currentPage: page,
          totalPages: (total / pageSize).ceil(),
          pageSize: pageSize,
          totalCount: total,
        );
      } catch (e) {
        getLogger('app').info('[AdminUserService] Local listUsers error: $e');
        return null;
      }
    }

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      // Use defensive normalization for the response data
      return AdminPaginatedUsersResponse.fromJson(asMap(response.body['data']));
    } else {
      getLogger('app').info(
        'Error listing users: ${response.statusCode} - ${response.bodyString}',
      );
      DialogUtils.showError(
        "Failed to fetch users: ${response.body?['message'] ?? response.statusText}",
      );
      return null;
    }
  }

  /// Creates a new user.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/admin/users`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (User data)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created user object)
  Future<User?> createUser(Map<String, dynamic> userData) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return User.fromJson(userData..['id'] = 'new-user-id');
    }
    final headers = await _getAuthHeaders();
    if (headers == null) return null;
    final clientOperationId = userData['clientOperationId']?.toString() ??
        const Uuid().v4();
    final payload = Map<String, dynamic>.from(userData)
      ..['clientOperationId'] = clientOperationId;
    try {
      if (_appConfig.localStorageOnly) {
        final toSave = Map<String, dynamic>.from(payload);
        toSave['id'] = toSave['id'] ?? clientOperationId;
        toSave['is_active'] = toSave['is_active'] ?? 1;
        await _localDatabaseService.createUserLocal(toSave);
        return User.fromJson({
          ...toSave,
          'id': toSave['id'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      final response = await _connect.post(
        _adminUsersBaseUrl,
        payload,
        headers: {
          ...headers,
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      if (response.statusCode! < 300) {
        return User.fromJson(asMap(response.body['data']['user']));
      }
      getLogger('app').info(
        'Error creating user: ${response.statusCode} - ${response.bodyString}',
      );
      DialogUtils.showError(
        "Failed to create user: ${response.body?['message'] ?? response.statusText}",
      );
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_user',
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

  /// Fetches a single user by their ID.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/admin/users/{userId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The full user object)
  Future<User?> getUserById(String userId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return User(
        id: userId,
        name: 'Mock User',
        email: 'mock@test.com',
        role: 'merchant',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    if (_appConfig.localStorageOnly) {
      try {
        final row = await _localDatabaseService.getUserById(userId);
        return row == null ? null : User.fromJson(row);
      } catch (e) {
        getLogger('app').info('[AdminUserService] Local getUserById error: $e');
        return null;
      }
    }

    final headers = await _getAuthHeaders();
    if (headers == null) return null;

    final response = await _connect.get(
      '$_adminUsersBaseUrl/$userId',
      headers: headers,
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return User.fromJson(asMap(response.body['data']));
    } else {
      getLogger('app').info(
        'Error fetching user $userId: ${response.statusCode} - ${response.bodyString}',
      );
      DialogUtils.showError(
        "Failed to fetch user: ${response.body?['message'] ?? response.statusText}",
      );
      return null;
    }
  }

  /// Updates an existing user.
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
  Future<User?> updateUser(String userId, Map<String, dynamic> userData) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return User.fromJson(userData..['id'] = userId);
    }
    final headers = await _getAuthHeaders();
    if (headers == null) return null;
    final clientOperationId = userData['clientOperationId']?.toString() ??
        const Uuid().v4();
    final payload = Map<String, dynamic>.from(userData)
      ..['clientOperationId'] = clientOperationId;

    try {
      if (_appConfig.localStorageOnly) {
        final toSave = Map<String, dynamic>.from(payload)..['id'] = userId;
        await _localDatabaseService.upsertUser(toSave);
        return User.fromJson({
          ...toSave,
          'id': userId,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      final response = await _connect.put(
        '$_adminUsersBaseUrl/$userId',
        payload,
        headers: {
          ...headers,
          'X-Client-Operation-Id': clientOperationId,
        },
      );

      if (response.statusCode == 200 && response.body['status'] == 'success') {
        return User.fromJson(asMap(response.body['data']));
      }
      getLogger('app').info(
        'Error updating user $userId: ${response.statusCode} - ${response.bodyString}',
      );
      DialogUtils.showError(
        "Failed to update user: ${response.body?['message'] ?? response.statusText}",
      );
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_user',
          action: 'update',
          endpoint: '$_adminUsersBaseUrl/$userId',
          payload: payload,
          method: 'PUT',
        );
        return User.fromJson({
          ...payload,
          'id': userId,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      rethrow;
    }
  }

  /// Deactivates a user (soft delete).
  ///
  /// __Request:__
  /// - __Method:__ DELETE
  /// - __Endpoint:__ `/api/v1/admin/users/{userId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  Future<bool> deleteUser(String userId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    final headers = await _getAuthHeaders();
    if (headers == null) return false;
    final clientOperationId = const Uuid().v4();
    try {
      if (_appConfig.localStorageOnly) {
        // soft-delete locally (deactivate)
        await _localDatabaseService.upsertUser({'id': userId, 'is_active': 0});
        return true;
      }

      final response = await _connect.delete(
        '$_adminUsersBaseUrl/$userId',
        headers: {
          ...headers,
          'X-Client-Operation-Id': clientOperationId,
        },
      );

      if (response.statusCode == 200 && response.body['status'] == 'success') {
        DialogUtils.showSuccess(
          response.body?['message'] ?? "User deactivated successfully",
        );
        return true;
      }
      getLogger('app').info(
        'Error deactivating user $userId: ${response.statusCode} - ${response.bodyString}',
      );
      DialogUtils.showError(
        "Failed to deactivate user: ${response.body?['message'] ?? response.statusText}",
      );
      return false;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_user',
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

  /// Activates a user.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/admin/users/{userId}/activate`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated user object)
  Future<User?> activateUser(String userId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return User(
        id: userId,
        name: 'Mock User',
        email: 'mock@test.com',
        role: 'merchant',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    final headers = await _getAuthHeaders();
    if (headers == null) return null;
    final clientOperationId = const Uuid().v4();
    try {
      if (_appConfig.localStorageOnly) {
        await _localDatabaseService.upsertUser({'id': userId, 'is_active': 1});
        return User.fromJson({
          'id': userId,
          'name': 'Local User',
          'email': '',
          'role': 'merchant',
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      final response = await _connect.put(
        '$_adminUsersBaseUrl/$userId/activate',
        {},
        headers: {
          ...headers,
          'X-Client-Operation-Id': clientOperationId,
        },
      );

      if (response.statusCode == 200 && response.body['status'] == 'success') {
        DialogUtils.showSuccess(
          response.body?['message'] ?? "User activated successfully",
        );
        return User.fromJson(asMap(response.body['data']));
      }
      getLogger('app').info(
        'Error activating user $userId: ${response.statusCode} - ${response.bodyString}',
      );
      DialogUtils.showError(
        "Failed to activate user: ${response.body?['message'] ?? response.statusText}",
      );
      return null;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_user',
          action: 'update',
          endpoint: '$_adminUsersBaseUrl/$userId/activate',
          payload: {'isActive': true},
          method: 'PUT',
        );
        return User(
          id: userId,
          name: 'Pending user',
          email: '',
          role: 'merchant',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  /// Permanently deletes a user.
  ///
  /// __Request:__
  /// - __Method:__ DELETE
  /// - __Endpoint:__ `/api/v1/admin/users/{userId}/permanent-delete`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  Future<bool> hardDeleteUser(String userId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    final headers = await _getAuthHeaders();
    if (headers == null) return false;
    // IMPORTANT: Confirm this is the correct endpoint for permanent deletion on your backend.
    // It might be something like '$userId/force' or with a query parameter like '?permanent=true'.
    // For now, I'm using a common pattern: '$userId/permanent-delete'
    final clientOperationId = const Uuid().v4();
    try {
      if (_appConfig.localStorageOnly) {
        // Permanently remove local user record
        await _localDatabaseService.database.then((db) => db.delete('users', where: 'id = ?', whereArgs: [userId]));
        return true;
      }

      final response = await _connect.delete(
        '$_adminUsersBaseUrl/$userId/permanent-delete',
        headers: {
          ...headers,
          'X-Client-Operation-Id': clientOperationId,
        },
      );

      if (response.statusCode == 200 && response.body['status'] == 'success') {
        DialogUtils.showSuccess(
          response.body?['message'] ?? "User permanently deleted",
        );
        return true;
      }
      getLogger('app').info(
        'Error permanently deleting user $userId: ${response.statusCode} - ${response.bodyString}',
      );
      DialogUtils.showError(
        "Failed to permanently delete user: ${response.body?['message'] ?? response.statusText}",
      );
      return false;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'admin_user',
          action: 'delete',
          endpoint: '$_adminUsersBaseUrl/$userId/permanent-delete',
          payload: {'userId': userId, 'permanent': true},
          method: 'DELETE',
        );
        return true;
      }
      rethrow;
    }
  }

  /// Fetches a list of merchants for selection in a dropdown.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/admin/users/merchants-for-selection`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A list of `UserSelectionItem` objects)
  Future<List<UserSelectionItem>?> getMerchantsForSelection() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 800));
      return [
        UserSelectionItem(id: 'merchant-1', name: 'SuperMart'),
        UserSelectionItem(id: 'merchant-2', name: 'QuickStop'),
        UserSelectionItem(id: 'merchant-3', name: 'Mega Foods'),
      ];
    }
    final headers = await _getAuthHeaders();
    if (headers == null) return null;

    final response = await _connect.get(
      '$_adminUsersBaseUrl/merchants-for-selection',
      headers: headers,
    );

    if (_appConfig.localStorageOnly) {
      try {
        final rows = await _localDatabaseService.listAllUsers(role: 'merchant');
        return rows.map((r) => UserSelectionItem(
          id: r['id'].toString(),
          name: r['name']?.toString() ?? r['email']?.toString() ?? '',
        )).toList();
      } catch (e) {
        getLogger('app').info('[AdminUserService] Local getMerchantsForSelection failed: $e');
        return [];
      }
    }

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      final rawList = asList(response.body['data']);
      return rawList
          .map(
            (json) =>
                UserSelectionItem.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } else {
      getLogger('app').info(
        'Error fetching merchants for selection: ${response.statusCode} - ${response.bodyString}',
      );
      DialogUtils.showError(
        "Failed to fetch merchant list: ${response.body?['message'] ?? response.statusText}",
      );
      return null;
    }
  }
}

