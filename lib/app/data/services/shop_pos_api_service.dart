import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class ShopPosApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  String get _baseUrl => '${ApiConstants.baseUrl}/shop/pos';

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
    ),
    InventoryItem(
      id: 'prod_003',
      merchantId: 'mock-merchant',
      name: 'Cappuccino',
      sku: 'BEV-003',
      sellingPrice: 3.50,
      originalPrice: 1.5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    InventoryItem(
      id: 'prod_004',
      merchantId: 'mock-merchant',
      name: 'Americano',
      sku: 'BEV-004',
      sellingPrice: 3.00,
      originalPrice: 1.2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    InventoryItem(
      id: 'prod_005',
      merchantId: 'mock-merchant',
      name: 'Iced Coffee',
      sku: 'BEV-005',
      sellingPrice: 3.75,
      originalPrice: 1.6,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    InventoryItem(
      id: 'prod_006',
      merchantId: 'mock-merchant',
      name: 'Herbal Tea',
      sku: 'BEV-006',
      sellingPrice: 2.75,
      originalPrice: 1.1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    InventoryItem(
      id: 'prod_007',
      merchantId: 'mock-merchant',
      name: 'Orange Juice',
      sku: 'BEV-007',
      sellingPrice: 4.00,
      originalPrice: 2.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
    ),
    InventoryItem(
      id: 'prod_102',
      merchantId: 'mock-merchant',
      name: 'Chocolate Muffin',
      sku: 'PST-002',
      sellingPrice: 3.25,
      originalPrice: 1.4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    InventoryItem(
      id: 'prod_103',
      merchantId: 'mock-merchant',
      name: 'Blueberry Scone',
      sku: 'PST-003',
      sellingPrice: 3.50,
      originalPrice: 1.5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    InventoryItem(
      id: 'prod_104',
      merchantId: 'mock-merchant',
      name: 'Banana Bread Slice',
      sku: 'PST-004',
      sellingPrice: 2.85,
      originalPrice: 1.3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    InventoryItem(
      id: 'prod_201',
      merchantId: 'mock-merchant',
      name: 'Ham & Cheese Sandwich',
      sku: 'SND-001',
      sellingPrice: 7.50,
      originalPrice: 3.5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    InventoryItem(
      id: 'prod_202',
      merchantId: 'mock-merchant',
      name: 'Turkey Club Sandwich',
      sku: 'SND-002',
      sellingPrice: 8.50,
      originalPrice: 4.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    InventoryItem(
      id: 'prod_203',
      merchantId: 'mock-merchant',
      name: 'Veggie Wrap',
      sku: 'SND-003',
      sellingPrice: 6.95,
      originalPrice: 3.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    InventoryItem(
      id: 'prod_301',
      merchantId: 'mock-merchant',
      name: 'Bag of Coffee Beans (12oz)',
      sku: 'MER-001',
      sellingPrice: 14.99,
      originalPrice: 8.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    InventoryItem(
      id: 'prod_302',
      merchantId: 'mock-merchant',
      name: 'Travel Mug',
      sku: 'MER-002',
      sellingPrice: 18.00,
      originalPrice: 10.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    InventoryItem(
      id: 'prod_303',
      merchantId: 'mock-merchant',
      name: 'Gift Card',
      sku: 'MER-003',
      sellingPrice: 25.00,
      originalPrice: 25.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Searches for products available for sale in the current shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__
  ///   - For merchants: `/api/v1/merchant/pos/products?shopId={shopId}&searchTerm={term}`
  ///   - For staff: `/api/v1/staff/pos/products?searchTerm={term}` (uses assigned shop from JWT)
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `searchTerm`: `String` (The search query for product name or SKU)
  ///   - `shopId`: (optional, for merchants when accessing shop dashboard)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A list of `InventoryItem` objects matching the search)
  Future<List<InventoryItem>> searchProducts(
    String shopId,
    String searchTerm, {
    String? categoryId,
    String? subcategoryId,
    String? brandId,
  }) async {
    // =========================================================================
    // MOCK IMPLEMENTATION
    // =========================================================================
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 300));

      if (searchTerm.isEmpty) {
        return _mockProducts;
      }

      final lowerCaseSearchTerm = searchTerm.toLowerCase();
      return _mockProducts.where((product) {
        final nameMatch = product.name.toLowerCase().contains(
          lowerCaseSearchTerm,
        );
        final skuMatch =
            product.sku?.toLowerCase().contains(lowerCaseSearchTerm) ?? false;
        return nameMatch || skuMatch;
      }).toList();
    }
    // =========================================================================

    // Local-only short-circuit for product search
    if (_appConfig.localStorageOnly) {
      try {
        final localDb = Get.find<LocalDatabaseService>();
        final rows = await localDb.getInventoryForShopLocal(shopId);

        // convert base rows to InventoryItem for filter operations
        final items = rows
            .map((r) => InventoryItem.fromJson(Map<String, dynamic>.from(r)))
            .toList();

        var filtered = items;

        if (categoryId != null && categoryId.isNotEmpty) {
          filtered = filtered
              .where(
                (p) => p.categoryId == categoryId || p.category == categoryId,
              )
              .toList();
        }
        if (subcategoryId != null && subcategoryId.isNotEmpty) {
          filtered = filtered
              .where((p) => p.subcategoryId == subcategoryId)
              .toList();
        }
        if (brandId != null && brandId.isNotEmpty) {
          filtered = filtered.where((p) => p.brandId == brandId).toList();
        }

        if (searchTerm.isEmpty) {
          return filtered;
        }

        final lowerCaseSearchTerm = searchTerm.toLowerCase();
        return filtered
            .where(
              (p) =>
                  p.name.toLowerCase().contains(lowerCaseSearchTerm) ||
                  (p.sku?.toLowerCase().contains(lowerCaseSearchTerm) ?? false),
            )
            .toList();
      } catch (e) {
        getLogger('app').info('[SHOP POS API] Local searchProducts failed: $e');
        return [];
      }
    }

    // Safety: if running in local-only mode but local DB lookup failed above,
    // return an empty list rather than making a network call.
    if (_appConfig.localStorageOnly) {
      return [];
    }

    // Determine the correct endpoint based on user role
    final userRole = _authService.user.value?.role;
    final String endpoint;
    final Map<String, dynamic> queryParams = {
      'searchTerm': searchTerm,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (subcategoryId != null && subcategoryId.isNotEmpty)
        'subcategoryId': subcategoryId,
      if (brandId != null && brandId.isNotEmpty) 'brandId': brandId,
    };

    if (userRole == 'merchant') {
      // Merchants accessing shop dashboard use merchant endpoint with shopId
      endpoint = '${ApiConstants.baseUrl}/merchant/pos/products';
      queryParams['shopId'] = shopId;
      getLogger('app').info(
        'ðŸ‘” [SHOP POS API] Using merchant POS endpoint for products search (shopId: $shopId)',
      );
    } else if (userRole == 'staff') {
      // Staff accessing shop dashboard use staff endpoint (uses their assigned shop from JWT)
      endpoint = '${ApiConstants.baseUrl}/staff/pos/products';
      getLogger('app').info(
        'ðŸ‘¤ [SHOP POS API] Using staff POS endpoint for products search',
      );
    } else {
      // Fallback for other roles
      endpoint = '$_baseUrl/$shopId/products';
      getLogger('app').info(
        'ðŸª [SHOP POS API] Using generic shop POS endpoint for products search (shopId: $shopId)',
      );
    }

    final response = await _connect.get(
      endpoint,
      headers: await _getHeaders(),
      query: queryParams,
    );

    if (response.isOk && response.body['data'] != null) {
      final rawList = asList(response.body['data']);
      return rawList
          .map((i) => InventoryItem.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } else {
      throw Exception(response.body?['message'] ?? 'Failed to search products');
    }
  }

  /// Fetches active promotions for the current shop.
  Future<List<Promotion>> getActivePromotions({String? shopId}) async {
    // =========================================================================
    // MOCK IMPLEMENTATION
    // =========================================================================
    if (_appConfig.isDevelopment) {
      final now = DateTime.now();
      return [
        Promotion(
          id: 'promo-001',
          merchantId: 'mock-merchant',
          shopId: shopId,
          name: '10% Off Everything',
          description: 'Get 10% discount on all items',
          type: 'percentage',
          value: 10.0,
          minSpend: 20.0,
          conditions: {'minSpend': 20.0},
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 30)),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        Promotion(
          id: 'promo-002',
          merchantId: 'mock-merchant',
          shopId: shopId,
          name: '\$5 Off Orders Over \$50',
          description: 'Save \$5 on orders over \$50',
          type: 'fixed_amount',
          value: 5.0,
          minSpend: 50.0,
          conditions: {'minSpend': 50.0},
          startDate: now.subtract(const Duration(days: 5)),
          endDate: now.add(const Duration(days: 15)),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }
    // =========================================================================

    // Local-only short-circuit
    if (_appConfig.localStorageOnly) {
      try {
        final localDb = Get.find<LocalDatabaseService>();
        final rows = await localDb.listActivePromotionsForShop(shopId ?? '');
        return rows
            .map((r) => Promotion.fromJson(Map<String, dynamic>.from(r)))
            .toList();
      } catch (e) {
        if (kDebugMode)
          getLogger(
            'app',
          ).info('[SHOP POS API] Local promotions fetch failed: $e');
        return [];
      }
    }

    // Determine the correct endpoint based on user role
    final userRole = _authService.user.value?.role;
    final String endpoint;
    final Map<String, dynamic> queryParams = {};

    if (userRole == 'merchant') {
      endpoint = '${ApiConstants.baseUrl}/merchant/pos/promotions';
      if (shopId != null) queryParams['shopId'] = shopId;
    } else if (userRole == 'staff') {
      endpoint = '${ApiConstants.baseUrl}/staff/pos/promotions';
    } else {
      endpoint = '$_baseUrl/promotions';
      if (shopId != null) queryParams['shopId'] = shopId;
    }

    final response = await _connect.get(
      endpoint,
      headers: await _getHeaders(),
      query: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.isOk) {
      final rawList = asList(response.body['data'] ?? response.body);
      return rawList
          .map((i) => Promotion.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } else {
      if (kDebugMode)
        getLogger(
          'app',
        ).info('[SHOP POS API] Promotions fetch failed: ${response.body}');
      throw Exception(
        response.body?['message'] ?? 'Failed to fetch promotions',
      );
    }
  }

  /// Processes a new sale for the current shop.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__
  ///   - For merchants: `/api/v1/merchant/pos/checkout?shopId=<shopId>`
  ///   - For staff: `/api/v1/staff/pos/checkout`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "items": [
  ///       { "productId": "uuid-item-1", "quantity": 2, "sellingPriceAtSale": 15.0 },
  ///       { "productId": "uuid-item-2", "quantity": 1, "sellingPriceAtSale": 25.0 }
  ///     ],
  ///     "totalAmount": 55.0,
  ///     "paymentType": "cash",
  ///     "customerId": "cust-uuid-1" // Optional
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created `Sale` object)
  Future<Sale> checkout(String shopId, Map<String, dynamic> saleData) async {
    saleData['id'] ??= const Uuid().v4();
    final clientSaleId = saleData['id'].toString();

    // =========================================================================
    // MOCK IMPLEMENTATION
    // =========================================================================
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final saleId = clientSaleId;
      final now = DateTime.now();

      final saleItems = (saleData['items'] as List).map((item) {
        final product = _mockProducts.firstWhere(
          (p) => p.id == item['productId'],
          orElse: () =>
              throw Exception('Mock product not found: ${item['productId']}'),
        );
        final quantity = item['quantity'] as int;
        final price = item['sellingPriceAtSale'] as double;
        return SaleItem(
          id: 'sale-item-${item['productId']}-${now.microsecondsSinceEpoch}',
          saleId: saleId,
          inventoryItemId: item['productId'] as String,
          quantitySold: quantity,
          sellingPriceAtSale: price,
          originalPriceAtSale: product.originalPrice,
          subtotal: quantity * price,
          createdAt: now,
          updatedAt: now,
          itemName: product.name,
          itemSku: product.sku,
        );
      }).toList();

      return Sale(
        id: saleId,
        merchantId: 'mock-merchant',
        shopId: shopId,
        saleDate: now,
        totalAmount: saleData['totalAmount'],
        deliveryCharge: saleData['deliveryCharge'] ?? 0.0,
        items: saleItems,
        paymentType: saleData['paymentType'],
        paymentStatus: 'succeeded',
        discountAmount: saleData['discountAmount'] as double?,
        createdAt: now,
        updatedAt: now,
      );
    }
    // Local-only mode: persist sale in local DB and return constructed Sale
    if (_appConfig.localStorageOnly) {
      try {
        final localDb = Get.find<LocalDatabaseService>();

        final merchantId =
            _authService.user.value?.merchantId ??
            _authService.user.value?.id ??
            'local-merchant';

        final safeSaleData = <String, dynamic>{
          'id': clientSaleId,
          'client_sale_id': clientSaleId,
          'shop_id': shopId,
          'merchant_id': merchantId,
          'sale_date': DateTime.now().toIso8601String(),
          'total_amount': (saleData['totalAmount'] as num?)?.toDouble() ?? 0.0,
          'discount_amount':
              (saleData['discountAmount'] as num?)?.toDouble() ?? 0.0,
          'applied_promotion_id': saleData['appliedPromotionId'],
          'delivery_charge':
              (saleData['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
          'payment_type': saleData['paymentType'] ?? 'cash',
          'payment_status': 'succeeded',
          'customer_id':
              saleData['customerName'] ??
              saleData['customer_id'] ??
              saleData['customerId'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        getLogger('app').info(
          'DEBUG [ShopPosApiService] local checkout safeSaleData: $safeSaleData',
        );

        final createdSaleId = await localDb.createSaleLocal(safeSaleData);

        final saleRow = await localDb.getSaleById(createdSaleId);

        final itemRows = (saleData['items'] as List<dynamic>?) ?? [];
        for (var i = 0; i < itemRows.length; i++) {
          final itemData = itemRows[i];
          if (itemData is Map<String, dynamic>) {
            final itemId =
                itemData['productId']?.toString() ??
                '${DateTime.now().microsecondsSinceEpoch}_$i';
            final quantity = (itemData['quantity'] as num?)?.toInt() ?? 0;
            final extractedName = (itemData['itemName'] ?? itemData['item_name'] ?? itemData['name'] ?? itemData['productName'] ?? itemData['product_name'] ?? itemData['title'])?.toString() ?? '';
            var resolvedItemName = extractedName;

            if (resolvedItemName.isEmpty) {
              try {
                final inventoryRows = await localDb.getInventoryForShopLocal(shopId);
                final match = inventoryRows.firstWhere(
                  (iRow) => (iRow['id'] ?? iRow['inventory_item_id'])?.toString() == itemId,
                  orElse: () => {},
                );
                resolvedItemName = (match['name'] ?? match['title'] ?? '').toString();
              } catch (_) {}
            }

            await localDb.createSaleItemLocal({
              'id': 'sale_item_${itemId}_$createdSaleId',
              'sale_id': createdSaleId,
              'inventory_item_id': itemId,
              'item_name': resolvedItemName,
              'item_sku': itemData['itemSku'] ?? itemData['sku'] ?? '',
              'quantity_sold': quantity,
              'selling_price_at_sale':
                  (itemData['sellingPriceAtSale'] as num?)?.toDouble() ?? 0.0,
              'original_price_at_sale':
                  (itemData['originalPriceAtSale'] as num?)?.toDouble(),
              'subtotal':
                  quantity *
                      ((itemData['sellingPriceAtSale'] as num?)?.toDouble() ?? 0.0),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });

            if (quantity > 0) {
              await localDb.adjustStockLocal(
                shopId: shopId,
                itemId: itemId,
                quantity: -quantity,
                actorId: _authService.user.value?.id,
              );
            }
          }
        }

        final itemsRows = await localDb.getSaleItemsForSale(createdSaleId);

        final saleItems = itemsRows.map((row) {
          return SaleItem(
            id: row['id'] as String,
            saleId: row['sale_id'] as String,
            inventoryItemId: row['inventory_item_id'] as String,
            quantitySold: (row['quantity_sold'] as num).toInt(),
            sellingPriceAtSale: (row['selling_price_at_sale'] as num)
                .toDouble(),
            originalPriceAtSale: row['original_price_at_sale'] != null
                ? (row['original_price_at_sale'] as num).toDouble()
                : null,
            subtotal: (row['subtotal'] as num).toDouble(),
            createdAt: DateTime.parse(row['created_at'] as String),
            updatedAt: DateTime.parse(row['updated_at'] as String),
            itemName: row['item_name'] as String?,
            itemSku: row['item_sku'] as String?,
          );
        }).toList();

        final now = DateTime.now();

        final invoiceId = 'invoice_${createdSaleId}';
        final invoiceItems = saleItems
            .map(
              (s) => {
                'id': s.id,
                'saleId': s.saleId,
                'inventoryItemId': s.inventoryItemId,
                'itemName': s.itemName,
                'itemSku': s.itemSku,
                'quantitySold': s.quantitySold,
                'sellingPriceAtSale': s.sellingPriceAtSale,
                'subtotal': s.subtotal,
              },
            )
            .toList();
        final subtotal =
            (saleData['items'] as List<dynamic>?)?.fold<double>(0.0, (
              prev,
              elem,
            ) {
              if (elem is Map<String, dynamic>) {
                final qty = (elem['quantity'] as num?)?.toDouble() ?? 0.0;
                final price =
                    (elem['sellingPriceAtSale'] as num?)?.toDouble() ?? 0.0;
                return prev + qty * price;
              }
              return prev;
            }) ??
            0.0;

        final discountAmount = (saleData['discountAmount'] as num?)?.toDouble() ?? 0.0;
        final deliveryCharge = (saleData['deliveryCharge'] as num?)?.toDouble() ?? 0.0;
        final totalAmount = (saleData['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final explicitTaxAmount = (saleData['taxAmount'] as num?)?.toDouble();
        final derivedTaxAmount = totalAmount - subtotal + discountAmount - deliveryCharge;

        await localDb.createInvoiceLocal({
          'id': invoiceId,
          'saleId': createdSaleId,
          'invoiceNumber': 'INV-${DateTime.now().millisecondsSinceEpoch}',
          'merchantId': merchantId,
          'shopId': shopId,
          'customerId':
              saleData['customerName'] ??
              saleData['customerId'] ??
              saleData['customer_id'],
          'invoiceDate': now.toIso8601String(),
          'dueDate': null,
          'subtotal': subtotal,
            'discountAmount': discountAmount,
            'taxAmount': explicitTaxAmount ?? (derivedTaxAmount < 0 ? 0.0 : derivedTaxAmount),
            'deliveryCharge': deliveryCharge,
            'totalAmount': totalAmount,
          'paymentStatus': 'succeeded',
          'notes': 'Local shop checkout (offline)',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'items': invoiceItems,
        });

        return Sale(
          id: saleRow?['id'] ?? createdSaleId,
          merchantId: saleRow?['merchant_id'] ?? 'local-storage',
          shopId: saleRow?['shop_id'] ?? shopId,
          saleDate: DateTime.parse(
            saleRow?['sale_date'] ?? now.toIso8601String(),
          ),
          totalAmount:
              (saleRow?['total_amount'] as num?)?.toDouble() ??
              (saleData['totalAmount'] as num?)?.toDouble() ??
              0.0,
          deliveryCharge:
              (saleRow?['delivery_charge'] as num?)?.toDouble() ??
              (saleData['deliveryCharge'] as num?)?.toDouble() ??
              0.0,
          items: saleItems,
          paymentType:
              saleRow?['payment_type'] ?? saleData['paymentType'] ?? 'unknown',
          paymentStatus: saleRow?['payment_status'] ?? 'pending',
          createdAt: DateTime.parse(
            saleRow?['created_at'] ?? now.toIso8601String(),
          ),
          updatedAt: DateTime.parse(
            saleRow?['updated_at'] ?? now.toIso8601String(),
          ),
        );
      } catch (e) {
        throw Exception(
          'Local storage only mode is enabled but saving sale failed: $e',
        );
      }
    }
    // =========================================================================

    // Determine endpoint based on user role
    final userRole = _authService.user.value?.role;
    final String endpoint;
    final Map<String, dynamic> requestBody;

    if (userRole == 'merchant') {
      endpoint = '${ApiConstants.baseUrl}/merchant/pos/checkout';
      // Create a copy of saleData and add shopId for merchant endpoint
      requestBody = {...saleData, 'shopId': shopId};
      getLogger('app').info(
        'ðŸ‘” [SHOP POS API] Using merchant POS endpoint for checkout (shopId: $shopId)',
      );
    } else if (userRole == 'staff') {
      endpoint = '${ApiConstants.baseUrl}/staff/pos/checkout';
      // Staff endpoint doesn't need shopId (it's in JWT)
      requestBody = saleData;
      getLogger('app').info(
        'ðŸ‘¤ [SHOP POS API] Using staff POS endpoint for checkout (assigned shop from JWT)',
      );
    } else {
      endpoint = '${ApiConstants.baseUrl}/shop/pos/checkout';
      // Generic shop endpoint includes shopId
      requestBody = {...saleData, 'shopId': shopId};
      getLogger('app').info(
        'ðŸª [SHOP POS API] Using generic shop POS endpoint for checkout (shopId: $shopId)',
      );
    }

    getLogger('app').info('ðŸ“¡ [SHOP POS API] Calling: $endpoint');
    getLogger('app').info('ðŸ“¤ [SHOP POS API] Request body: $requestBody');

    final response = await _connect.post(
      endpoint,
      requestBody,
      headers: await _getHeaders(),
    );

    getLogger(
      'app',
    ).info('ðŸ“¥ [SHOP POS API] Response status: ${response.statusCode}');
    getLogger(
      'app',
    ).info('ðŸ“¥ [SHOP POS API] Response body: ${response.bodyString}');

    if (response.statusCode == 201 && response.body['data'] != null) {
      getLogger('app').info('âœ… [SHOP POS API] Checkout succeeded');
      return Sale.fromJson(asMap(response.body['data']));
    } else {
      getLogger('app').info(
        'âŒ [SHOP POS API] Checkout failed. Status: ${response.statusCode}',
      );
      getLogger(
        'app',
      ).info('âŒ [SHOP POS API] Response body: ${response.bodyString}');
      throw Exception(response.body?['message'] ?? 'Checkout failed');
    }
  }
}
