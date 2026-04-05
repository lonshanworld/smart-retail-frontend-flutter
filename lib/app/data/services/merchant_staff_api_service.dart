import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:uuid/uuid.dart';

class PaginatedStaffResponse {
  final List<User> staff;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;

  PaginatedStaffResponse({
    required this.staff,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedStaffResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedStaffResponse(
      staff: (json['users'] as List).map((i) => User.fromJson(i)).toList(),
      totalCount: json['totalCount'],
      currentPage: json['currentPage'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}

class MerchantStaffApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/merchant/staff';
  String get _shopsBaseUrl => '${ApiConstants.baseUrl}/merchant/shops';

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
      'entity_type': 'staff',
      'action': action,
      'method': action == 'delete' ? 'DELETE' : (action == 'update' ? 'PUT' : 'POST'),
      'endpoint': endpoint,
      'payload': payload,
      'headers': {'X-Client-Operation-Id': clientOperationId},
    });
  }

  /// Fetches a paginated list of staff for the current merchant.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/staff`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `page`: `int` (The page number to fetch)
  ///   - `pageSize`: `int` (The number of items per page)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "status": "success",
  ///     "data": {
  ///       "users": [
  ///         {
  ///           "id": "uuid-staff-1",
  ///           "name": "John Doe",
  ///           "email": "john.doe@example.com",
  ///           "role": "staff",
  ///           "isActive": true,
  ///           "merchantId": "uuid-merchant-1",
  ///           "createdAt": "2023-01-01T12:00:00Z"
  ///         }
  ///       ],
  ///       "totalCount": 1,
  ///       "currentPage": 1,
  ///       "pageSize": 10,
  ///       "totalPages": 1
  ///     }
  ///   }
  ///   ```
  Future<PaginatedStaffResponse> listStaff({
    int page = 1,
    int pageSize = 10,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final mockStaff = List.generate(
        15,
        (index) => User(
          id: 'staff-$index',
          name: 'Staff Member $index',
          email: 'staff$index@shop.com',
          role: 'staff',
          isActive: index % 4 != 0, // Make some inactive
          merchantId: 'mock-merchant-id',
          assignedShopId: (index % 3 == 0)
              ? 'shop-${index % 3}'
              : null, // Assign some staff to shops
          createdAt: DateTime.now().subtract(Duration(days: index)),
          updatedAt: DateTime.now(),
        ),
      );
      return PaginatedStaffResponse(
        staff: mockStaff,
        totalCount: mockStaff.length,
        currentPage: 1,
        pageSize: 10,
        totalPages: 2,
      );
    }

    if (_appConfig.localStorageOnly) {
      try {
        final merchantId = _authService.user.value?.merchantId ?? '';
        final rows = await _localDatabaseService.listUsersForMerchant(merchantId);
        final staffRows = rows.where((r) => (r['role'] as String?) == 'staff').toList();
        final total = staffRows.length;
        final start = (page - 1) * pageSize;
        final items = staffRows.skip(start).take(pageSize).map((r) => User.fromJson(r)).toList();
        return PaginatedStaffResponse(
          staff: items,
          totalCount: total,
          currentPage: page,
          pageSize: pageSize,
          totalPages: (total / pageSize).ceil(),
        );
      } catch (e) {
        throw Exception('Failed to load local staff: $e');
      }
    }

    final response = await _connect.get(
      _baseUrl,
      headers: await _getHeaders(),
      query: {'page': page.toString(), 'pageSize': pageSize.toString()},
    );

    if (response.isOk && response.body['data'] != null) {
      return PaginatedStaffResponse.fromJson(asMap(response.body['data']));
    } else {
      throw Exception(response.body?['message'] ?? 'Failed to load staff');
    }
  }

  /// Fetches a list of all shops for the current merchant (for selection).
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/shops`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A list of `Shop` objects)
  Future<List<Shop>> getShopsForSelection() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _uniqueShops(
        List.generate(
        5,
        (index) => Shop(
          id: 'shop-$index',
          name: 'Shop Branch $index',
          address: '$index Main St',
          merchantId: 'mock-merchant-id',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      );
    }
    if (_appConfig.localStorageOnly) {
      try {
        final merchantId = _authService.user.value?.merchantId ?? '';
        final rows = await _localDatabaseService.listShopsForMerchant(merchantId);
        return _uniqueShops(rows.map((r) => Shop.fromJson(r)).toList());
      } catch (e) {
        throw Exception('Failed to load local shops: $e');
      }
    }

    final response = await _connect.get(
      _shopsBaseUrl,
      headers: await _getHeaders(),
    );
    if (response.isOk && response.body['data'] != null) {
      final rawList = asList(response.body['data']);
      return _uniqueShops(rawList
          .map((i) => Shop.fromJson(Map<String, dynamic>.from(i)))
          .toList());
    } else {
      throw Exception(response.body?['message'] ?? 'Failed to load shops');
    }
  }

  List<Shop> _uniqueShops(List<Shop> shops) {
    final seenIds = <String>{};
    final unique = <Shop>[];

    for (final shop in shops) {
      final id = shop.id?.trim();
      if (id == null || id.isEmpty) {
        unique.add(shop);
        continue;
      }
      if (seenIds.add(id)) {
        unique.add(shop);
      }
    }

    return unique;
  }

  /// Creates a new staff member for the current merchant.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/staff`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "name": "Jane Doe",
  ///     "email": "jane.doe@example.com",
  ///     "password": "securePassword123",
  ///     "assignedShopId": "uuid-shop-1" // Optional
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created User object for the staff member)
  Future<User> createStaff(Map<String, dynamic> data) async {
    final clientOperationId = data['clientOperationId']?.toString() ?? const Uuid().v4();
    final payload = Map<String, dynamic>.from(data)..['clientOperationId'] = clientOperationId;
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      if (data['email'] == 'fail@test.com') {
        throw Exception('Mock Error: This email is already taken.');
      }
      final newUser = User(
        id: clientOperationId,
        name: data['name'],
        email: data['email'],
        role: 'staff',
        merchantId: 'mock-merchant-id',
        assignedShopId: data['assignedShopId'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return newUser;
    }
    try {
      if (_appConfig.localStorageOnly) {
        final toSave = Map<String, dynamic>.from(payload);
        toSave['id'] = toSave['id'] ?? clientOperationId;
        toSave['role'] = 'staff';
        toSave['is_active'] = 1;
        toSave['merchant_id'] = toSave['merchantId'] ?? _authService.user.value?.merchantId;
        toSave['password_hash'] = toSave['password_hash'] ?? toSave['password'];
        final now = DateTime.now().toIso8601String();
        toSave['created_at'] = toSave['created_at'] ?? now;
        toSave['updated_at'] = toSave['updated_at'] ?? now;
        await _localDatabaseService.createUserLocal(toSave);
        return User.fromJson({
          ...toSave,
          'id': toSave['id'],
          'createdAt': toSave['created_at'],
          'updatedAt': toSave['updated_at'],
        });
      }

      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.post(
        _baseUrl,
        payload,
        headers: headers,
      );

      if (response.statusCode == 201 && response.body['data'] != null) {
        return User.fromJson(asMap(response.body['data']));
      }
      throw Exception(
        response.body?['message'] ?? 'Failed to create staff member',
      );
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'create',
          endpoint: _baseUrl,
          payload: payload,
        );
        return User(
          id: clientOperationId,
          name: data['name'],
          email: data['email'],
          role: 'staff',
          merchantId: 'pending',
          assignedShopId: data['assignedShopId'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      throw Exception(
        e.toString().isNotEmpty ? e.toString() : 'Failed to create staff member',
      );
    }
  }

  /// Updates an existing staff member.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/merchant/staff/{staffId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (Fields to update)
  ///   ```json
  ///   {
  ///     "name": "Jane D. Smith", // Optional
  ///     "isActive": false, // Optional
  ///     "assignedShopId": "uuid-shop-2" // Optional
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated User object)
  Future<User> updateStaff(String staffId, Map<String, dynamic> data) async {
    final clientOperationId = data['clientOperationId']?.toString() ?? const Uuid().v4();
    final payload = Map<String, dynamic>.from(data)..['clientOperationId'] = clientOperationId;
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return User(
        id: staffId,
        name: data['name'] ?? 'Updated Staff Name',
        email: 'staff@test.com',
        role: 'staff',
        isActive: data['isActive'] ?? true,
        merchantId: 'mock-merchant-id',
        assignedShopId: data['assignedShopId'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    try {
      if (_appConfig.localStorageOnly) {
        final toSave = Map<String, dynamic>.from(payload)..['id'] = staffId;
        await _localDatabaseService.upsertUser(toSave);
        return User.fromJson({
          ...toSave,
          'id': staffId,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.put(
        '$_baseUrl/$staffId',
        payload,
        headers: headers,
      );
      if (response.isOk && response.body['data'] != null) {
        return User.fromJson(asMap(response.body['data']));
      }
      throw Exception(
        response.body?['message'] ?? 'Failed to update staff member',
      );
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'update',
          endpoint: '$_baseUrl/$staffId',
          payload: payload,
        );
        return User(
          id: staffId,
          name: data['name'] ?? 'Updated Staff',
          email: data['email'] ?? 'pending@example.com',
          role: 'staff',
          isActive: data['isActive'] ?? true,
          merchantId: 'pending',
          assignedShopId: data['assignedShopId'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      throw Exception(
        e.toString().isNotEmpty ? e.toString() : 'Failed to update staff member',
      );
    }
  }

  /// Deletes a staff member.
  ///
  /// __Request:__
  /// - __Method:__ DELETE
  /// - __Endpoint:__ `/api/v1/merchant/staff/{staffId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200 or 204
  Future<void> deleteStaff(String staffId) async {
    final clientOperationId = const Uuid().v4();
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      // Simulate success
      return;
    }

    try {
      if (_appConfig.localStorageOnly) {
        // soft-delete locally
        await _localDatabaseService.upsertUser({'id': staffId, 'is_active': 0});
        return;
      }

      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.delete(
        '$_baseUrl/$staffId',
        headers: headers,
      );

      if (!response.isOk) {
        throw Exception(
          response.body?['message'] ?? 'Failed to delete staff member',
        );
      }
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'delete',
          endpoint: '$_baseUrl/$staffId',
          payload: {'staffId': staffId},
        );
        return;
      }
      throw Exception(
        e.toString().isNotEmpty ? e.toString() : 'Failed to delete staff member',
      );
    }
  }

  /// Preflight check whether a staff member can be safely deleted.
  /// Returns { 'deletable': bool, 'blockers': { 'stock_movements': 2, ... } }
  Future<Map<String, dynamic>?> checkStaffDeletable(String staffId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 200));
      return {'deletable': true, 'blockers': {}};
    }
    if (_appConfig.localStorageOnly) {
      // Simple local check: assume deletable unless there are local stock movements
      try {
        final db = await _localDatabaseService.database;
        final res = await db.rawQuery('SELECT COUNT(*) as c FROM stock_movements WHERE user_id = ?', [staffId]);
        final count = res.isNotEmpty ? (res.first['c'] as int?) ?? 0 : 0;
        return {'deletable': count == 0, 'blockers': {'stock_movements': count}};
      } catch (e) {
        return {'deletable': true, 'blockers': {}};
      }
    }

    final response = await _connect.get(
      '$_baseUrl/$staffId/delete-check',
      headers: await _getHeaders(),
    );
    if (response.isOk && response.body['status'] == 'success') {
      return Map<String, dynamic>.from(asMap(response.body['data']));
    } else {
      throw Exception(
        response.body?['message'] ?? 'Failed to check deletable staff',
      );
    }
  }
}
