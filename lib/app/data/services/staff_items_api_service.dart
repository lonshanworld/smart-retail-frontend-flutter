import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';

class StaffItemsApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  String get _baseUrl => '${ApiConstants.baseUrl}/staff/items';

  final List<InventoryItem> _mockProducts = [
    InventoryItem(
      id: 'prod_001',
      merchantId: 'mock-merchant',
      name: 'Espresso',
      sku: 'BEV-001',
      sellingPrice: 2.50,
      originalPrice: 1.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      stockInfo: [
        StockInfo(quantity: 12, shopId: '1', shopName: 'Mock Central Shop'),
      ],
    ),
    InventoryItem(
      id: 'prod_002',
      merchantId: 'mock-merchant',
      name: 'Latte',
      sku: 'BEV-002',
      sellingPrice: 3.50,
      originalPrice: 1.5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      stockInfo: [
        StockInfo(quantity: 7, shopId: '1', shopName: 'Mock Central Shop'),
      ],
    ),
    InventoryItem(
      id: 'prod_101',
      merchantId: 'mock-merchant',
      name: 'Croissant',
      sku: 'PST-001',
      sellingPrice: 2.95,
      originalPrice: 1.2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      stockInfo: [
        StockInfo(quantity: 20, shopId: '1', shopName: 'Mock Central Shop'),
      ],
    ),
  ];

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches a list of all available product items for the assigned shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/shop/items`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ A list of `InventoryItem` objects.
  Future<List<InventoryItem>> getItems({
    String? categoryId,
    String? subcategoryId,
    String? brandId,
  }) async {
    // =========================================================================
    // MOCK IMPLEMENTATION
    // =========================================================================
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return _mockProducts;
    }
    // =========================================================================

    // Build query params if provided
    String url = _baseUrl;
    final params = <String, String>{};
    if (categoryId != null && categoryId.isNotEmpty)
      params['categoryId'] = categoryId;
    if (subcategoryId != null && subcategoryId.isNotEmpty)
      params['subcategoryId'] = subcategoryId;
    if (brandId != null && brandId.isNotEmpty) params['brandId'] = brandId;
    if (params.isNotEmpty) {
      url =
          '$_baseUrl?${params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    }

    final response = await _connect.get(url, headers: await _getHeaders());
    if (response.isOk && response.body['data'] != null) {
      final rawList = asList(response.body['data']);
      return rawList
          .map((i) => InventoryItem.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } else {
      throw Exception(response.body?['message'] ?? 'Failed to load items');
    }
  }
}
