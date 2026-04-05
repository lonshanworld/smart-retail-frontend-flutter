import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class ShopSalesApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final LocalDatabaseService _localDatabaseService = Get.find<LocalDatabaseService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches paginated sales for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__
  ///   - For merchants: `/api/v1/merchant/shops/{shopId}/sales`
  ///   - For staff: `/api/v1/shop/shops/{shopId}/sales`
  /// - __Query Parameters:__
  ///   - `page`: (optional) Page number, defaults to 1
  ///   - `pageSize`: (optional) Items per page, defaults to 10
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ `PaginatedSalesResponse` with sales list
  Future<PaginatedSalesResponse> listShopSales(
    String shopId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    getLogger('app').info('ðŸ” [SHOP SALES API] Fetching sales for shop: $shopId');
    getLogger('app').info('ðŸ“„ [SHOP SALES API] Page: $page, PageSize: $pageSize');

    // Determine the correct endpoint based on user role
    final userRole = _authService.user.value?.role;
    final String baseUrl;

    if (userRole == 'merchant') {
      baseUrl = '${ApiConstants.baseUrl}/merchant/shops';
      getLogger('app').info('ðŸ‘” [SHOP SALES API] Using merchant endpoint');
    } else {
      baseUrl = '${ApiConstants.baseUrl}/shop/shops';
      getLogger('app').info('ðŸ‘¤ [SHOP SALES API] Using staff endpoint');
    }

    final url = '$baseUrl/$shopId/sales?page=$page&pageSize=$pageSize';
    getLogger('app').info('ðŸŒ [SHOP SALES API] Full URL: $url');

    try {
      if (_appConfig.localStorageOnly) {
        final rows = await _localDatabaseService.listSalesForShop(shopId, limit: 10000);
        final total = rows.length;
        final start = (page - 1) * pageSize;
        final end = start + pageSize;
        final pageRows = rows.sublist(start < total ? start : total, end < total ? end : total);

        final sales = <Sale>[];
        for (var r in pageRows) {
          final itemsRows = await _localDatabaseService.getSaleItemsForSale(r['id']);
          final items = itemsRows.map((it) {
            return {
              'id': it['id'],
              'saleId': it['sale_id'] ?? it['saleId'],
              'inventoryItemId': it['inventory_item_id'] ?? it['inventoryItemId'],
              'quantitySold': it['quantity_sold'] ?? it['quantitySold'],
              'sellingPriceAtSale': it['selling_price_at_sale'] ?? it['sellingPriceAtSale'],
              'originalPriceAtSale': it['original_price_at_sale'] ?? it['originalPriceAtSale'],
              'subtotal': it['subtotal'],
              'createdAt': it['created_at'] ?? it['createdAt'],
              'updatedAt': it['updated_at'] ?? it['updatedAt'],
              'itemName': it['item_name'] ?? it['itemName'],
              'itemSku': it['item_sku'] ?? it['itemSku'],
            };
          }).toList();

          final saleJson = {
            'id': r['id'],
            'shopId': r['shop_id'] ?? r['shopId'],
            'merchantId': r['merchant_id'] ?? r['merchantId'],
            'saleDate': r['sale_date'] ?? r['saleDate'],
            'totalAmount': r['total_amount'] ?? r['totalAmount'],
            'deliveryCharge': r['delivery_charge'] ?? r['deliveryCharge'],
            'appliedPromotionId': r['applied_promotion_id'] ?? r['appliedPromotionId'],
            'discountAmount': r['discount_amount'] ?? r['discountAmount'],
            'paymentType': r['payment_type'] ?? r['paymentType'],
            'paymentStatus': r['payment_status'] ?? r['paymentStatus'],
            'notes': r['notes'],
            'createdAt': r['created_at'] ?? r['createdAt'],
            'updatedAt': r['updated_at'] ?? r['updatedAt'],
            'items': items,
          };
          sales.add(Sale.fromJson(saleJson));
        }

        final paginated = PaginatedSalesResponse(
          items: sales,
          totalItems: total,
          currentPage: page,
          pageSize: pageSize,
          totalPages: (total / pageSize).ceil(),
        );
        return paginated;
      }
      final response = await _connect.get(url, headers: await _getHeaders());

      getLogger('app').info('ðŸ“¥ [SHOP SALES API] Response status: ${response.statusCode}');

      // Defensive guard: if local-only mode was enabled concurrently, prefer
      // the local result above â€” return empty paginated response instead of
      // consuming network payload.
      if (_appConfig.localStorageOnly) {
        return PaginatedSalesResponse(items: [], totalItems: 0, currentPage: page, pageSize: pageSize, totalPages: 0);
      }

      if (response.isOk && response.body != null) {
        getLogger('app').info('âœ… [SHOP SALES API] Successfully fetched sales');
        getLogger('app').info(
          'ðŸ“Š [SHOP SALES API] Response body type: ${response.body.runtimeType}',
        );

        final paginatedResponse = PaginatedSalesResponse.fromJson(
          response.body,
        );

        getLogger('app').info('ðŸ“‹ [SHOP SALES API] Parsed response:');
        getLogger('app').info('   - Items count: ${paginatedResponse.items.length}');
        getLogger('app').info('   - Total items: ${paginatedResponse.totalItems}');
        getLogger('app').info('   - Current page: ${paginatedResponse.currentPage}');
        getLogger('app').info('   - Total pages: ${paginatedResponse.totalPages}');

        for (int i = 0; i < paginatedResponse.items.length; i++) {
          final sale = paginatedResponse.items[i];
          getLogger('app').info(
            '   Sale #${i + 1}: ID=${sale.id}, Date=${sale.saleDate}, Total=${sale.totalAmount}, ItemsCount=${sale.items.length}',
          );
          for (int j = 0; j < sale.items.length; j++) {
            final item = sale.items[j];
            getLogger('app').info(
              '      Item #${j + 1}: SellingPrice=${item.sellingPriceAtSale}, OriginalPrice=${item.originalPriceAtSale}',
            );
          }
        }

        return paginatedResponse;
      } else {
        final errorMsg =
            response.body?['message'] ?? 'Failed to fetch shop sales';
        getLogger('app').info('âŒ [SHOP SALES API] Error: $errorMsg');
        getLogger('app').info('ðŸ“¥ [SHOP SALES API] Response body: ${response.body}');
        throw Exception(errorMsg);
      }
    } catch (e) {
      getLogger('app').info('âŒ [SHOP SALES API] Exception: $e');
      getLogger('app').info('ðŸ” [SHOP SALES API] Exception type: ${e.runtimeType}');
      throw Exception('Failed to fetch shop sales: $e');
    }
  }
}

