import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
// Import for Admin Dashboard
import 'package:smart_retail/app/modules/admin/dashboard/models/admin_dashboard_summary_model.dart';
// Import for Merchant Dashboard
import 'package:smart_retail/app/data/models/merchant_dashboard_summary_model.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';

import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class AdminDashboardApiService extends GetxService {
  final GetConnect _getConnect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  /// Fetches the summary data for the admin dashboard.
  ///
  /// This method sends a GET request to the `/admin/dashboard/summary` endpoint.
  final LocalDatabaseService _localDatabaseService = Get.find<LocalDatabaseService>();
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
  ///     "total_active_merchants": 15,
  ///     "total_active_staff": 50,
  ///     "total_active_shops": 25,
  ///     "total_products_listed": 1200
  ///   }
  ///   ```
  Future<AdminDashboardSummaryModel?> getAdminDashboardSummary() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return AdminDashboardSummaryModel(
        totalActiveMerchants: 15,
        totalActiveStaff: 50,
        totalActiveShops: 25,
        totalProductsListed: 1200,
      );
    }
    // Local-only mode: return a best-effort summary from local DB (or safe defaults)
    if (_appConfig.localStorageOnly) {
      try {
        final totalShops = (await _localDatabaseService.listShopsForMerchant(_authService.user.value?.merchantId ?? '')).length;
        final totalUsers = (await _localDatabaseService.listAllUsers()).length;
        return AdminDashboardSummaryModel(
          totalActiveMerchants: 0,
          totalActiveStaff: totalUsers,
          totalActiveShops: totalShops,
          totalProductsListed: 0,
        );
      } catch (e) {
        getLogger('app').info('[AdminDashboardApiService] Local admin summary failed: $e');
        return AdminDashboardSummaryModel(
          totalActiveMerchants: 0,
          totalActiveStaff: 0,
          totalActiveShops: 0,
          totalProductsListed: 0,
        );
      }
    }

    final token = _authService.authToken.value;
    if (token == null) {
      DialogUtils.showError(
        'Authentication token not found. Please login again.',
      );
      return null;
    }

    final adminUrl = '${ApiConstants.baseUrl}/admin/dashboard/summary';
    getLogger('app').info('[AdminDashboardApiService] Admin summary URL: $adminUrl');
    final response = await _getConnect.get(
      adminUrl,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      if (response.body != null) {
        try {
          if (response.body is Map<String, dynamic>) {
            return AdminDashboardSummaryModel.fromJson(
              response.body as Map<String, dynamic>,
            );
          } else {
            DialogUtils.showError('Invalid data format received from server.');
            return null;
          }
        } catch (e) {
          DialogUtils.showError(
            'Failed to parse admin dashboard data: ${e.toString()}',
          );
          return null;
        }
      } else {
        DialogUtils.showError(
          'Received empty response from server for admin dashboard summary.',
        );
        return null;
      }
    } else {
      String errorMessage =
          'Failed to fetch admin dashboard summary. Status Code: ${response.statusCode}';
      if (response.body != null && response.body['message'] != null) {
        errorMessage = response.body['message'];
      }
      DialogUtils.showError(errorMessage);
      return null;
    }
  }

  /// Fetches the summary data for the merchant dashboard.
  ///
  /// This method sends a GET request to the `/merchant/dashboard/summary` endpoint.
  /// An optional `shopId` can be provided to filter the summary for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/dashboard/summary`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters (Optional):__
  ///   - `shop_id`: `string` (UUID of the shop)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "total_sales_revenue": { "value": 15000.75 },
  ///     "number_of_transactions": { "value": 300 },
  ///     "average_order_value": { "value": 50.00 },
  ///     "top_selling_products": [
  ///       { "product_id": "uuid-1", "product_name": "Product A", "quantity_sold": 100, "revenue": 5000.00 },
  ///       { "product_id": "uuid-2", "product_name": "Product B", "quantity_sold": 75, "revenue": 3750.50 }
  ///     ]
  ///   }
  ///   ```
  ///
  /// __Dummy Response Data (for testing):__
  /// ```dart
  /// final dummyMerchantSummary = MerchantDashboardSummaryModel(
  ///   totalSalesRevenue: KpiData(value: 15000.75),
  ///   numberOfTransactions: KpiData(value: 300),
  ///   averageOrderValue: KpiData(value: 50.00),
  ///   topSellingProducts: [
  ///     ProductSummaryModel(productId: 'uuid-1', productName: 'Product A', quantitySold: 100, revenue: 5000.00),
  ///     ProductSummaryModel(productId: 'uuid-2', productName: 'Product B', quantitySold: 75, revenue: 3750.50),
  ///   ],
  /// );
  /// ```
  Future<MerchantDashboardSummaryModel?> getMerchantDashboardSummary({
    String? shopId,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return MerchantDashboardSummaryModel(
        totalSalesRevenue: KpiData(value: 15000.75),
        numberOfTransactions: KpiData(value: 300),
        averageOrderValue: KpiData(value: 50.00),
        topSellingProducts: [
          ProductSummaryModel(
            productId: 'uuid-1',
            productName: 'Product A',
            quantitySold: 100,
            revenue: 5000.00,
          ),
          ProductSummaryModel(
            productId: 'uuid-2',
            productName: 'Product B',
            quantitySold: 75,
            revenue: 3750.50,
          ),
        ],
      );
    }
    // Local-only: compute a best-effort summary from local DB (or safe defaults)
    if (_appConfig.localStorageOnly) {
      try {
        final merchantId = _authService.user.value?.merchantId ?? '';
        final db = await _localDatabaseService.database;
        final whereArgs = <Object>[];
        String salesWhere = 'merchant_id = ?';
        whereArgs.add(merchantId);
        if (shopId != null && shopId.isNotEmpty) {
          salesWhere = '$salesWhere AND shop_id = ?';
          whereArgs.add(shopId);
        }
        final totalRow = await db.rawQuery('SELECT SUM(total_amount) as total, COUNT(*) as cnt FROM sales WHERE $salesWhere', whereArgs.map((e) => e.toString()).toList());
        final total = (totalRow.isNotEmpty && totalRow.first['total'] != null) ? (totalRow.first['total'] as num).toDouble() : 0.0;
        final cnt = (totalRow.isNotEmpty && totalRow.first['cnt'] != null) ? (totalRow.first['cnt'] as int) : 0;
        return MerchantDashboardSummaryModel(
          totalSalesRevenue: KpiData(value: total),
          numberOfTransactions: KpiData(value: cnt.toDouble()),
          averageOrderValue: KpiData(value: cnt > 0 ? (total / cnt) : 0.0),
          topSellingProducts: [],
        );
      } catch (e) {
        getLogger('app').info('[AdminDashboardApiService] Local merchant summary failed: $e');
        return MerchantDashboardSummaryModel(
          totalSalesRevenue: KpiData(value: 0.0),
          numberOfTransactions: KpiData(value: 0.0),
          averageOrderValue: KpiData(value: 0.0),
          topSellingProducts: [],
        );
      }
    }

    final token = _authService.authToken.value;
    if (token == null) {
      DialogUtils.showError(
        'Authentication token not found. Please login again.',
      );
      return null;
    }

    String url = '${ApiConstants.baseUrl}/merchant/dashboard/summary';
    getLogger('app').info('[AdminDashboardApiService] Merchant summary URL: $url');
    Map<String, String> queryParameters = {};
    if (shopId != null && shopId.isNotEmpty) {
      queryParameters['shop_id'] =
          shopId; // Changed from 'shopId' to 'shop_id' to match backend
    }

    try {
      getLogger('app').info(
        '[AdminDashboardApiService] Requesting merchant dashboard summary for shopId: $shopId',
      );
      // Set a request timeout so the UI won't wait indefinitely on network issues.
      final response = await _getConnect
          .get(
            url,
            headers: {'Authorization': 'Bearer $token'},
            query: queryParameters.isNotEmpty ? queryParameters : null,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timed out after 15 seconds');
            },
          );

      getLogger('app').info('[MerchantDashboard] Response status: ${response.statusCode}');
      getLogger('app').info(
        '[MerchantDashboard] Response body type: ${response.body.runtimeType}',
      );
      getLogger('app').info('[MerchantDashboard] Response body: ${response.body}');

      if (response.statusCode != null && response.statusCode! < 300) {
        if (response.body != null) {
          try {
            // Support responses wrapped in { data: {...}, status: 'success' }
            dynamic payload = response.body;
            if (payload is Map && payload.containsKey('data')) {
              payload = payload['data'];
            }
            getLogger('app').info(
              '[AdminDashboardApiService] payload runtimeType: ${payload.runtimeType}',
            );
            final Map<String, dynamic> map = asMap(payload);
            getLogger('app').info('[AdminDashboardApiService] map keys: ${map.keys.length}');
            final model = MerchantDashboardSummaryModel.fromJson(map);
            return model;
          } catch (e, st) {
            getLogger('app').info(
              '[AdminDashboardApiService] Error parsing dashboard JSON: $e',
            );
            getLogger('app').info(st);
            DialogUtils.showError('Failed to parse merchant dashboard data.');
            return null;
          }
        } else {
          DialogUtils.showError(
            'Received empty response from server for merchant dashboard summary.',
          );
          return null;
        }
      } else {
        String errorMessage =
            'No data in dashboard summary. Status Code: ${response.statusCode}';
        if (response.body != null && response.body['message'] != null) {
          errorMessage = response.body['message'];
        }
        DialogUtils.showError(errorMessage);
        return null;
      }
    } catch (e, st) {
      // Local-only fallback: compute a best-effort merchant dashboard summary
      if (_appConfig.localStorageOnly) {
        try {
          final merchantId = _authService.user.value?.merchantId ?? '';
          final db = await _localDatabaseService.database;
          // build where clause
          final whereArgs = <Object>[];
          String salesWhere = 'merchant_id = ?';
          whereArgs.add(merchantId);
          if (shopId != null && shopId.isNotEmpty) {
            salesWhere = '$salesWhere AND shop_id = ?';
            whereArgs.add(shopId);
          }
          final totalRow = await db.rawQuery('SELECT SUM(total_amount) as total, COUNT(*) as cnt FROM sales WHERE $salesWhere', whereArgs.map((e) => e.toString()).toList());
          final total = (totalRow.isNotEmpty && totalRow.first['total'] != null) ? (totalRow.first['total'] as num).toDouble() : 0.0;
          final cnt = (totalRow.isNotEmpty && totalRow.first['cnt'] != null) ? (totalRow.first['cnt'] as int) : 0;

          // top selling products
          final productRows = await db.rawQuery('''
            SELECT si.inventory_item_id as product_id, si.item_name as product_name, SUM(si.quantity_sold) as quantity_sold, SUM(si.subtotal) as revenue
            FROM sale_items si
            JOIN sales s ON s.id = si.sale_id
            WHERE s.merchant_id = ? ${shopId != null && shopId.isNotEmpty ? 'AND s.shop_id = ?' : ''}
            GROUP BY si.inventory_item_id, si.item_name
            ORDER BY quantity_sold DESC
            LIMIT 10
          ''', shopId != null && shopId.isNotEmpty ? [merchantId, shopId] : [merchantId]);

          List<ProductSummaryModel> topProducts = [];
          try {
            topProducts = productRows.map<ProductSummaryModel>((r) => ProductSummaryModel(
              productId: r['product_id']?.toString() ?? '',
              productName: r['product_name']?.toString() ?? '',
              quantitySold: (r['quantity_sold'] is int) ? (r['quantity_sold'] as int) : int.tryParse((r['quantity_sold']?.toString() ?? '0')),
              revenue: (r['revenue'] is num) ? (r['revenue'] as num).toDouble() : double.tryParse(r['revenue']?.toString() ?? '0') ?? 0.0,
            )).toList();
          } catch (convErr) {
            getLogger('app').info('[AdminDashboardApiService] Failed converting productRows to ProductSummaryModel: $convErr, rows: $productRows');
            topProducts = <ProductSummaryModel>[];
          }

          final avg = cnt > 0 ? (total / cnt) : 0.0;
          return MerchantDashboardSummaryModel(
            totalSalesRevenue: KpiData(value: total),
            numberOfTransactions: KpiData(value: cnt.toDouble()),
            averageOrderValue: KpiData(value: avg),
            topSellingProducts: topProducts,
          );
        } catch (le) {
          getLogger('app').info('[AdminDashboardApiService] Local merchant summary failed: $le');
          return MerchantDashboardSummaryModel(
            totalSalesRevenue: KpiData(value: 0.0),
            numberOfTransactions: KpiData(value: 0.0),
            averageOrderValue: KpiData(value: 0.0),
            topSellingProducts: [],
          );
        }
      }
      getLogger('app').info(
        '[AdminDashboardApiService] Exception fetching dashboard summary: $e',
      );
      getLogger('app').info(st);
      DialogUtils.showError(
        'Error fetching merchant dashboard data: ${e.toString()}',
      );
      return null;
    }
  }
}

