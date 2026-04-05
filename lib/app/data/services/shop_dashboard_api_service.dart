import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

// Model for the dashboard summary data
class ShopDashboardSummary {
  final double salesToday;
  final int transactionsToday;
  final int lowStockItems;

  ShopDashboardSummary({
    required this.salesToday,
    required this.transactionsToday,
    required this.lowStockItems,
  });

  factory ShopDashboardSummary.fromJson(Map<String, dynamic> json) {
    return ShopDashboardSummary(
      salesToday: (json['salesToday'] as num).toDouble(),
      transactionsToday: (json['transactionsToday'] as num).toInt(),
      lowStockItems: (json['lowStockItems'] as num).toInt(),
    );
  }
}

class ShopDashboardApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDb = Get.find<LocalDatabaseService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/shop';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches the summary data for the shop dashboard.
  ///
  /// This would typically include metrics like sales today, number of transactions,
  /// and count of items that are low on stock for the specific shop.
  ///
  /// For merchants: requires shopId parameter
  /// For staff: uses assigned_shop_id automatically
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/shop/dashboard/summary` (with optional ?shopId= for merchants)
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "success": true,
  ///     "data": {
  ///       "salesToday": 1450.75,
  ///       "transactionsToday": 23,
  ///       "lowStockItems": 5
  ///     }
  ///   }
  ///   ```
  Future<ShopDashboardSummary> getDashboardSummary({String? shopId}) async {
    getLogger('app').info('ðŸ” [SHOP DASHBOARD] Fetching dashboard summary...');
    if (shopId != null) {
      getLogger('app').info('ðŸ“¦ [SHOP DASHBOARD] Shop ID: $shopId');
    }

    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      // Return mock data for development environment
      getLogger('app').info('âœ… [SHOP DASHBOARD] Returning mock data (development mode)');
      return ShopDashboardSummary(
        salesToday: 1450.75,
        transactionsToday: 23,
        lowStockItems: 5,
      );
    }

    // Local-only mode: compute dashboard summary from local DB
    if (_appConfig.localStorageOnly) {
      final effectiveShopId = shopId ?? await _authService.getShopId();
      if (effectiveShopId == null) throw Exception('No shop selected');

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final nowIso = now.toIso8601String();

      final db = await _localDb.database;
      final salesRows = await db.rawQuery(
        'SELECT * FROM sales WHERE shop_id = ? AND sale_date >= ? AND sale_date <= ?',
        [effectiveShopId, startOfDay, nowIso],
      );

      double salesToday = 0.0;
      for (var r in salesRows) {
        salesToday += (r['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      final transactionsToday = salesRows.length;

      // Count low stock items by comparing stock quantity to low_stock_threshold
      final invRows = await _localDb.getInventoryForShopLocal(effectiveShopId);
      int lowStockItems = 0;
      for (var ir in invRows) {
        final stockInfo = ir['stockInfo'] as List<dynamic>? ?? [];
        final qty = stockInfo.isNotEmpty ? (stockInfo.first['quantity'] as int?) ?? 0 : 0;
        final threshold = (ir['low_stock_threshold'] as int?) ?? (ir['lowStockThreshold'] as int?) ?? 0;
        if (threshold > 0 && qty <= threshold) lowStockItems++;
      }

      return ShopDashboardSummary(
        salesToday: salesToday,
        transactionsToday: transactionsToday,
        lowStockItems: lowStockItems,
      );
    }

    // Build URL with optional shopId query parameter
    String url = '$_baseUrl/dashboard/summary';
    if (shopId != null) {
      url += '?shopId=$shopId';
    }

    final response = await _connect.get(url, headers: await _getHeaders());

    getLogger('app').info('ðŸ“¥ [SHOP DASHBOARD] Response status: ${response.statusCode}');
    getLogger('app').info('ðŸ“¥ [SHOP DASHBOARD] Response body: ${response.body}');

    if (response.statusCode == null) {
      throw Exception(
        'Network error: Unable to connect to server. Please check your connection and ensure the backend is running.',
      );
    }

    if (response.statusCode! < 300 &&
        response.body != null &&
        response.body['success'] == true) {
      getLogger('app').info('âœ… [SHOP DASHBOARD] Parsing dashboard data...');
      return ShopDashboardSummary.fromJson(asMap(response.body['data']));
    } else {
      throw Exception(
        response.body?['message'] ?? 'Failed to load dashboard summary',
      );
    }
  }
}

