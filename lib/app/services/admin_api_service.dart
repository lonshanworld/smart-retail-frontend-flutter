import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/models/admin_dashboard_summary_model.dart'; // New
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';

class AdminApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDb = Get.find<LocalDatabaseService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/admin';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches the summary data for the admin dashboard.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/admin/dashboard/summary`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "totalMerchants": 10,
  ///     "activeMerchants": 8,
  ///     "totalStaff": 50,
  ///     "activeStaff": 45,
  ///     "totalShops": 20,
  ///     "totalSalesValue": 150000.00,
  ///     "salesToday": 5000.00,
  ///     "transactionsToday": 100
  ///   }
  ///   ```
  Future<AdminDashboardSummary?> getAdminDashboardSummary() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return AdminDashboardSummary(
        totalMerchants: 10,
        activeMerchants: 8,
        totalStaff: 50,
        activeStaff: 45,
        totalShops: 20,
        totalSalesValue: 150000.00,
        salesToday: 5000.00,
        transactionsToday: 100,
      );
    }
    if (_appConfig.localStorageOnly) {
      final db = await _localDb.database;
      final merchantsRes = await db.rawQuery('SELECT COUNT(DISTINCT merchant_id) as c FROM shops');
      final totalMerchants = (merchantsRes.isNotEmpty ? (merchantsRes.first['c'] as int?) ?? 0 : 0);

      final activeMerchantsRes = await db.rawQuery('SELECT COUNT(DISTINCT merchant_id) as c FROM shops WHERE is_active = 1');
      final activeMerchants = (activeMerchantsRes.isNotEmpty ? (activeMerchantsRes.first['c'] as int?) ?? 0 : 0);

      final staffRes = await db.rawQuery('SELECT COUNT(*) as c FROM users WHERE role = ?', ['staff']);
      final totalStaff = (staffRes.isNotEmpty ? (staffRes.first['c'] as int?) ?? 0 : 0);
      final activeStaffRes = await db.rawQuery('SELECT COUNT(*) as c FROM users WHERE role = ? AND is_active = 1', ['staff']);
      final activeStaff = (activeStaffRes.isNotEmpty ? (activeStaffRes.first['c'] as int?) ?? 0 : 0);

      final shopsRes = await db.rawQuery('SELECT COUNT(*) as c FROM shops');
      final totalShops = (shopsRes.isNotEmpty ? (shopsRes.first['c'] as int?) ?? 0 : 0);

      final salesRes = await db.rawQuery('SELECT SUM(total_amount) as s FROM sales');
      final totalSalesValue = (salesRes.isNotEmpty ? (salesRes.first['s'] as num?)?.toDouble() ?? 0.0 : 0.0);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final nowIso = now.toIso8601String();
      final salesTodayRes = await db.rawQuery('SELECT SUM(total_amount) as s, COUNT(*) as c FROM sales WHERE sale_date >= ? AND sale_date <= ?', [startOfDay, nowIso]);
      final salesToday = (salesTodayRes.isNotEmpty ? (salesTodayRes.first['s'] as num?)?.toDouble() ?? 0.0 : 0.0);
      final transactionsToday = (salesTodayRes.isNotEmpty ? (salesTodayRes.first['c'] as int?) ?? 0 : 0);

      return AdminDashboardSummary(
        totalMerchants: totalMerchants,
        activeMerchants: activeMerchants,
        totalStaff: totalStaff,
        activeStaff: activeStaff,
        totalShops: totalShops,
        totalSalesValue: totalSalesValue,
        salesToday: salesToday,
        transactionsToday: transactionsToday,
      );
    }

    final response = await _connect.get(
      '$_baseUrl/dashboard/summary',
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200 && response.body['success'] == true) {
      return AdminDashboardSummary.fromJson(asMap(response.body['data']));
    } else {
      throw Exception(
        response.body?['message'] ?? 'Failed to get admin dashboard summary',
      );
    }
  }

  /// Updates a user as an admin.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/admin/users/{userId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "name": "Updated Name"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated user object)
  Future<User?> adminUpdateUser(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return User.fromJson(
        updates
          ..['id'] = userId
          ..['email'] = 'mock@email.com'
          ..['role'] = 'merchant',
      );
    }
    // Local-only mode: persist changes to local DB and return the updated user.
    if (_appConfig.localStorageOnly) {
      final toSave = {...updates, 'id': userId};
      await _localDb.upsertUser(toSave);
      final u = await _localDb.getUserById(userId);
      return u != null ? User.fromJson(Map<String, dynamic>.from(u)) : null;
    }

    final response = await _connect.put(
      '$_baseUrl/users/$userId',
      updates,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200 && response.body['success'] == true) {
      return User.fromJson(asMap(response.body['data']));
    } else {
      throw Exception(response.body?['message'] ?? 'Failed to update user');
    }
  }
}
