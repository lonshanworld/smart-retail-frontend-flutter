import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/offline_sales_service.dart';
import 'package:smart_retail/app/services/connectivity_service.dart';
import 'package:smart_retail/app/services/cache_manager_service.dart';

class MerchantPosApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  final Map<String, List<InventoryItem>> _mockProductsByShop = {
    'shop-0': [
      InventoryItem(id: 'prod_001', merchantId: 'mock-merchant', name: 'Espresso', sku: 'BEV-001', sellingPrice: 2.50, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      InventoryItem(id: 'prod_002', merchantId: 'mock-merchant', name: 'Latte', sku: 'BEV-002', sellingPrice: 3.50, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      InventoryItem(id: 'prod_101', merchantId: 'mock-merchant', name: 'Croissant', sku: 'PST-001', sellingPrice: 2.95, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      InventoryItem(id: 'prod_201', merchantId: 'mock-merchant', name: 'Ham & Cheese Sandwich', sku: 'SND-001', sellingPrice: 7.50, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    ],
    'shop-1': [
      InventoryItem(id: 'prod_102', merchantId: 'mock-merchant', name: 'Chocolate Muffin', sku: 'PST-002', sellingPrice: 3.25, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      InventoryItem(id: 'prod_103', merchantId: 'mock-merchant', name: 'Blueberry Scone', sku: 'PST-003', sellingPrice: 3.50, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      InventoryItem(id: 'prod_301', merchantId: 'mock-merchant', name: 'Bag of Coffee Beans (12oz)', sku: 'MER-001', sellingPrice: 14.99, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    ],
    'shop-2': [], // An empty shop for testing
  };

  String get _baseUrl => '${ApiConstants.baseUrl}/merchant/pos';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Searches for products available for sale in a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/pos/products`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `shopId`: `String` (The ID of the shop to search in)
  ///   - `searchTerm`: `String` (The search query for product name or SKU)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A list of `InventoryItem` objects matching the search)
  ///
  /// __Offline Support:__
  /// - If device is offline, returns cached products
  /// - If cache is expired but offline, still returns cached products
  /// - Logs warning when returning expired cache
  Future<List<InventoryItem>> searchProducts(String shopId, String searchTerm) async {
    CacheManagerService? cacheManagerService;
    ConnectivityService? connectivityService;
    
    try {
      cacheManagerService = Get.find<CacheManagerService>();
      connectivityService = Get.find<ConnectivityService>();
    } catch (e) {
      print('[POS API] Cache services not initialized');
    }

    // =========================================================================
    // MOCK IMPLEMENTATION
    // =========================================================================
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 400));
      final productsForShop = _mockProductsByShop[shopId] ?? [];
      
      if (searchTerm.isEmpty) {
        return productsForShop;
      }
      
      return productsForShop
          .where((p) => 
              p.name.toLowerCase().contains(searchTerm.toLowerCase()) || 
              (p.sku?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false))
          .toList();
    }
    // =========================================================================

    try {
      final response = await _connect.get(
        '$_baseUrl/products',
        headers: await _getHeaders(),
        query: {'shopId': shopId, 'searchTerm': searchTerm},
      );

      if (response.isOk && response.body['data'] != null) {
        final products = (response.body['data'] as List)
            .map((p) => InventoryItem.fromJson(p))
            .toList();
        
        // Cache the products for offline use
        if (cacheManagerService != null) {
          await cacheManagerService.cacheProducts(
            response.body['data'] as List<Map<String, dynamic>>,
            'merchant-${_authService.hashCode}', // Temporary merchant ID
          );
        }
        
        return products;
      } else {
        throw Exception(response.body?['message'] ?? 'Failed to fetch products');
      }
    } catch (e) {
      print('[POS API] Error fetching products: $e');
      
      // Try to return cached products if offline
      bool isOnline = connectivityService?.isOnline.value ?? true;
      if (!isOnline && cacheManagerService != null) {
        print('[POS API] ⚠️  Returning cached products (offline mode)');
        final cachedProducts = await cacheManagerService.getCachedProducts(
          'merchant-${_authService.hashCode}', // Temporary merchant ID
        );
        
        if (cachedProducts != null && cachedProducts.isNotEmpty) {
          final products = cachedProducts
              .map((p) => InventoryItem.fromJson(p))
              .toList();
          
          // Filter by search term
          if (searchTerm.isEmpty) {
            return products;
          }
          
          return products
              .where((p) => 
                  p.name.toLowerCase().contains(searchTerm.toLowerCase()) || 
                  (p.sku?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false))
              .toList();
        }
      }
      
      rethrow;
    }
  }

  /// Fetches active promotions for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/pos/promotions`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `shopId`: `String` (The ID of the shop)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A list of active `Promotion` objects)
  ///
  /// __Offline Support:__
  /// - If device is offline, returns cached promotions
  /// - If cache is expired but offline, still returns cached promotions
  /// - Logs warning when returning expired cache
  Future<List<Promotion>> getActivePromotions(String shopId) async {
    CacheManagerService? cacheManagerService;
    ConnectivityService? connectivityService;
    
    try {
      cacheManagerService = Get.find<CacheManagerService>();
      connectivityService = Get.find<ConnectivityService>();
    } catch (e) {
      print('[POS API] Cache services not initialized');
    }

    print('🔍 [POS API] Requesting promotions for shop: $shopId');
    
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 300));
      print('✅ [POS API] Development mode - returning 2 mock promotions');
      return [
        Promotion(
          id: 'promo-1',
          merchantId: 'mock-merchant',
          name: '10% Off Everything',
          description: 'Get 10% off your entire purchase',
          type: 'percentage',
          value: 10.0,
          minSpend: 20.0,
          conditions: {},
          startDate: DateTime.now().subtract(Duration(days: 7)),
          endDate: DateTime.now().add(Duration(days: 30)),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Promotion(
          id: 'promo-2',
          merchantId: 'mock-merchant',
          name: '\$5 Off \$30+',
          description: 'Save \$5 when you spend \$30 or more',
          type: 'fixed_amount',
          value: 5.0,
          minSpend: 30.0,
          conditions: {},
          startDate: DateTime.now().subtract(Duration(days: 3)),
          endDate: DateTime.now().add(Duration(days: 60)),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    try {
      print('📡 [POS API] Calling: ${_baseUrl}/promotions?shopId=$shopId');
      
      final response = await _connect.get(
        '$_baseUrl/promotions',
        headers: await _getHeaders(),
        query: {'shopId': shopId},
      );

      print('📥 [POS API] Response status: ${response.statusCode}');
      print('📥 [POS API] Response body: ${response.body}');

      if (response.isOk && response.body['data'] != null) {
        final promotions = (response.body['data'] as List).map((p) => Promotion.fromJson(p)).toList();
        print('✅ [POS API] Successfully parsed ${promotions.length} promotion(s)');
        
        // Cache the promotions for offline use
        if (cacheManagerService != null) {
          await cacheManagerService.cachePromotions(
            response.body['data'] as List<Map<String, dynamic>>,
            'merchant-${_authService.hashCode}', // Temporary merchant ID
          );
        }
        
        if (promotions.isNotEmpty) {
          for (var promo in promotions) {
            final minSpendText = promo.minSpend > 0 ? 'min: \$${promo.minSpend.toStringAsFixed(2)}' : 'no minimum';
            print('   • ${promo.name}: ${promo.type} ${promo.value} ($minSpendText)');
          }
        } else {
          print('⚠️  [POS API] Response contained empty promotions array');
        }
        
        return promotions;
      } else {
        final errorMsg = response.body?['message'] ?? 'Failed to fetch promotions';
        print('❌ [POS API] Error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('[POS API] Error fetching promotions: $e');
      
      // Try to return cached promotions if offline
      bool isOnline = connectivityService?.isOnline.value ?? true;
      if (!isOnline && cacheManagerService != null) {
        print('[POS API] ⚠️  Returning cached promotions (offline mode)');
        final cachedPromotions = await cacheManagerService.getCachedPromotions(
          'merchant-${_authService.hashCode}', // Temporary merchant ID
        );
        
        if (cachedPromotions != null && cachedPromotions.isNotEmpty) {
          return cachedPromotions
              .map((p) => Promotion.fromJson(p))
              .toList();
        }
      }
      
      rethrow;
    }
  }

  /// Processes a new sale for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/pos/checkout`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   '''json
  ///   {
  ///     "shopId": "uuid-shop-1",
  ///     "items": [
  ///       { "productId": "uuid-item-1", "quantity": 2, "sellingPriceAtSale": 15.0 },
  ///       { "productId": "uuid-item-2", "quantity": 1, "sellingPriceAtSale": 25.0 }
  ///     ],
  ///     "totalAmount": 55.0,
  ///     "paymentType": "cash"
  ///   }
  ///   '''
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created `Sale` object)
  ///
  /// __Offline Support:__
  /// - If device is offline, the sale is automatically queued for sync
  /// - Returns a local sale object with pending status
  /// - Sale will be synced when device goes online
  Future<Sale> checkout(String shopId, Map<String, dynamic> saleData) async {
    // Get offline services
    OfflineSalesService? offlineSalesService;
    ConnectivityService? connectivityService;
    
    try {
      offlineSalesService = Get.find<OfflineSalesService>();
    } catch (e) {
      print('⚠️  [POS API] OfflineSalesService not initialized yet');
    }

    try {
      connectivityService = Get.find<ConnectivityService>();
    } catch (e) {
      print('⚠️  [POS API] ConnectivityService not initialized yet, assuming online');
    }

    // =========================================================================
    // MOCK IMPLEMENTATION
    // =========================================================================
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));

      final saleId = 'sale-${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      
      final saleItems = (saleData['items'] as List).map((item) {
        final quantity = item['quantity'] as int;
        final price = item['sellingPriceAtSale'] as double;
        return SaleItem(
          id: 'sale-item-${item['productId']}-${now.microsecondsSinceEpoch}',
          saleId: saleId,
          inventoryItemId: item['productId'] as String,
          quantitySold: quantity,
          sellingPriceAtSale: price,
          subtotal: quantity * price,
          createdAt: now,
          updatedAt: now,
        );
      }).toList();

      return Sale(
        id: saleId,
        merchantId: 'mock-merchant',
        shopId: shopId,
        saleDate: now,
        totalAmount: saleData['totalAmount'],
        items: saleItems,
        paymentType: saleData['paymentType'],
        paymentStatus: 'succeeded',
        createdAt: now,
        updatedAt: now,
      );
    }
    // =========================================================================

    // Check connectivity
    bool isOnline = connectivityService?.isOnline.value ?? true;

    if (!isOnline && offlineSalesService != null) {
      print('[POS API] 🔴 Device is offline - queueing sale for later sync');
      
      // Queue the sale for offline processing
      final saleQueued = await offlineSalesService.processSale(saleData);
      
      if (saleQueued) {
        // Create a temporary local sale object for offline mode
        final saleId = 'sale-offline-${DateTime.now().millisecondsSinceEpoch}';
        final now = DateTime.now();
        
        final saleItems = (saleData['items'] as List).map((item) {
          final quantity = item['quantity'] as int;
          final price = item['sellingPriceAtSale'] as double;
          return SaleItem(
            id: 'sale-item-${item['productId']}-${now.microsecondsSinceEpoch}',
            saleId: saleId,
            inventoryItemId: item['productId'] as String,
            quantitySold: quantity,
            sellingPriceAtSale: price,
            subtotal: quantity * price,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

        final offlineSale = Sale(
          id: saleId,
          merchantId: 'mock-merchant',
          shopId: shopId,
          saleDate: now,
          totalAmount: saleData['totalAmount'],
          items: saleItems,
          paymentType: saleData['paymentType'],
          paymentStatus: 'pending', // Mark as pending offline
          createdAt: now,
          updatedAt: now,
        );

        print('[POS API] ✅ Sale queued successfully (will sync when online)');
        return offlineSale;
      } else {
        throw Exception('Failed to queue sale for offline processing');
      }
    }

    // If online, attempt to send to backend
    print('[POS API] 🟢 Device is online - sending sale to backend');
    try {
      final response = await _connect.post('$_baseUrl/checkout', saleData..['shopId'] = shopId, headers: await _getHeaders());

      if (response.statusCode == 201 && response.body['data'] != null) {
        print('[POS API] ✅ Sale processed successfully online');
        return Sale.fromJson(response.body['data']);
      } else {
        final errorMsg = response.body?['message'] ?? 'Checkout failed';
        print('[POS API] ❌ Backend returned error: $errorMsg');
        
        // If backend fails, queue for offline retry if service is available
        if (offlineSalesService != null) {
          print('[POS API] ⚠️  Queuing sale for retry...');
          await offlineSalesService.processSale(saleData);
        }
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('[POS API] ❌ Error sending sale to backend: $e');
      
      // On network error, queue for offline retry if service is available
      if (offlineSalesService != null) {
        print('[POS API] ⚠️  Queuing sale for offline retry...');
        await offlineSalesService.processSale(saleData);
      }
      
      rethrow;
    }
  }
}
