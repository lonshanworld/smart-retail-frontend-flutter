
import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';

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
    print('🔍 [SHOP DASHBOARD] Fetching dashboard summary...');
    if (shopId != null) {
      print('📦 [SHOP DASHBOARD] Shop ID: $shopId');
    }

    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      // Return mock data for development environment
      print('✅ [SHOP DASHBOARD] Returning mock data (development mode)');
      return ShopDashboardSummary(
        salesToday: 1450.75,
        transactionsToday: 23,
        lowStockItems: 5,
      );
    }

    // Build URL with optional shopId query parameter
    String url = '$_baseUrl/dashboard/summary';
    if (shopId != null) {
      url += '?shopId=$shopId';
    }

    final response = await _connect.get(
      url,
      headers: await _getHeaders(),
    );

    print('📥 [SHOP DASHBOARD] Response status: ${response.statusCode}');
    print('📥 [SHOP DASHBOARD] Response body: ${response.body}');

    if (response.statusCode == null) {
      throw Exception('Network error: Unable to connect to server. Please check your connection and ensure the backend is running.');
    }

    if (response.statusCode! < 300 && response.body != null && response.body['success'] == true) {
      print('✅ [SHOP DASHBOARD] Parsing dashboard data...');
      return ShopDashboardSummary.fromJson(response.body['data']);
    } else {
      throw Exception(response.body?['message'] ?? 'Failed to load dashboard summary');
    }
  }
}
