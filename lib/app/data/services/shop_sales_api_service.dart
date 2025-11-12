import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';

class ShopSalesApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();

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
    print('🔍 [SHOP SALES API] Fetching sales for shop: $shopId');
    print('📄 [SHOP SALES API] Page: $page, PageSize: $pageSize');

    // Determine the correct endpoint based on user role
    final userRole = _authService.user.value?.role;
    final String baseUrl;
    
    if (userRole == 'merchant') {
      baseUrl = '${ApiConstants.baseUrl}/merchant/shops';
      print('👔 [SHOP SALES API] Using merchant endpoint');
    } else {
      baseUrl = '${ApiConstants.baseUrl}/shop/shops';
      print('👤 [SHOP SALES API] Using staff endpoint');
    }

    final url = '$baseUrl/$shopId/sales?page=$page&pageSize=$pageSize';
    print('🌐 [SHOP SALES API] Full URL: $url');

    try {
      final response = await _connect.get(
        url,
        headers: await _getHeaders(),
      );

      print('📥 [SHOP SALES API] Response status: ${response.statusCode}');

      if (response.isOk && response.body != null) {
        print('✅ [SHOP SALES API] Successfully fetched sales');
        print('📊 [SHOP SALES API] Response body type: ${response.body.runtimeType}');
        
        final paginatedResponse = PaginatedSalesResponse.fromJson(response.body);
        
        print('📋 [SHOP SALES API] Parsed response:');
        print('   - Items count: ${paginatedResponse.items.length}');
        print('   - Total items: ${paginatedResponse.totalItems}');
        print('   - Current page: ${paginatedResponse.currentPage}');
        print('   - Total pages: ${paginatedResponse.totalPages}');
        
        for (int i = 0; i < paginatedResponse.items.length; i++) {
          final sale = paginatedResponse.items[i];
          print('   Sale #${i + 1}: ID=${sale.id}, Date=${sale.saleDate}, Total=${sale.totalAmount}, ItemsCount=${sale.items.length}');
          for (int j = 0; j < sale.items.length; j++) {
            final item = sale.items[j];
            print('      Item #${j + 1}: SellingPrice=${item.sellingPriceAtSale}, OriginalPrice=${item.originalPriceAtSale}');
          }
        }
        
        return paginatedResponse;
      } else {
        final errorMsg = response.body?['message'] ?? 'Failed to fetch shop sales';
        print('❌ [SHOP SALES API] Error: $errorMsg');
        print('📥 [SHOP SALES API] Response body: ${response.body}');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [SHOP SALES API] Exception: $e');
      print('🔍 [SHOP SALES API] Exception type: ${e.runtimeType}');
      throw Exception('Failed to fetch shop sales: $e');
    }
  }
}
