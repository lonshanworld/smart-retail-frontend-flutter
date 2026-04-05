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
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class MerchantPosApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

  final Map<String, List<InventoryItem>> _mockProductsByShop = {

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
  Future<List<InventoryItem>> searchProducts(
    String shopId,
    String searchTerm, {
    String? categoryId,
    String? subcategoryId,
    String? brandId,
  }) async {
    CacheManagerService? cacheManagerService;
    ConnectivityService? connectivityService;

    try {
      cacheManagerService = Get.find<CacheManagerService>();
      connectivityService = Get.find<ConnectivityService>();
    } catch (e) {
      getLogger('app').info('[POS API] Cache services not initialized');
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
          .where(
            (p) =>
                p.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
                (p.sku?.toLowerCase().contains(searchTerm.toLowerCase()) ??
                    false),
          )
          .toList();
    }
    // =========================================================================

    if (_appConfig.localStorageOnly) {
      getLogger(
        'app',
      ).info('[POS API] Local storage only mode - returning local products');
      try {
        final products = await _localDatabaseService.getInventoryForShopLocal(
          shopId,
        );
        var inventoryItems = products
            .map((p) => InventoryItem.fromJson(p))
            .toList();

        if (categoryId != null && categoryId.isNotEmpty) {
          inventoryItems = inventoryItems
              .where(
                (p) => p.categoryId == categoryId || p.category == categoryId,
              )
              .toList();
        }
        if (subcategoryId != null && subcategoryId.isNotEmpty) {
          inventoryItems = inventoryItems
              .where((p) => p.subcategoryId == subcategoryId)
              .toList();
        }
        if (brandId != null && brandId.isNotEmpty) {
          inventoryItems = inventoryItems
              .where((p) => p.brandId == brandId)
              .toList();
        }

        if (searchTerm.isEmpty) {
          return inventoryItems;
        }

        return inventoryItems
            .where(
              (p) =>
                  p.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
                  (p.sku?.toLowerCase().contains(searchTerm.toLowerCase()) ??
                      false),
            )
            .toList();
      } catch (e) {
        getLogger('app').info('[POS API] Local searchProducts failed: $e');
        return [];
      }
    }

    // Conservative guard: if local-only is set but cacheManagerService wasn't
    // available above, avoid making network calls and return empty list.
    if (_appConfig.localStorageOnly) {
      return [];
    }

    try {
      final response = await _connect.get(
        '$_baseUrl/products',
        headers: await _getHeaders(),
        query: {
          'shopId': shopId,
          'searchTerm': searchTerm,
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
          if (subcategoryId != null && subcategoryId.isNotEmpty)
            'subcategoryId': subcategoryId,
          if (brandId != null && brandId.isNotEmpty) 'brandId': brandId,
        },
      );

      if (response.isOk && response.body['data'] != null) {
        final rawList = asList(response.body['data']);
        final products = rawList
            .map((p) => InventoryItem.fromJson(Map<String, dynamic>.from(p)))
            .toList();

        // Cache the products for offline use
        if (cacheManagerService != null) {
          final toCache = rawList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          await cacheManagerService.cacheProducts(
            toCache,
            'merchant-${_authService.hashCode}', // Temporary merchant ID
          );
        }

        return products;
      } else {
        throw Exception(
          response.body?['message'] ?? 'Failed to fetch products',
        );
      }
    } catch (e) {
      getLogger('app').info('[POS API] Error fetching products: $e');

      // Try to return cached products if offline
      bool isOnline = connectivityService?.isOnline.value ?? true;
      if (!isOnline && cacheManagerService != null) {
        getLogger(
          'app',
        ).info('[POS API] âš ï¸  Returning cached products (offline mode)');
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
              .where(
                (p) =>
                    p.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
                    (p.sku?.toLowerCase().contains(searchTerm.toLowerCase()) ??
                        false),
              )
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
      getLogger('app').info('[POS API] Cache services not initialized');
    }

    getLogger(
      'app',
    ).info('ðŸ” [POS API] Requesting promotions for shop: $shopId');

    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 300));
      getLogger(
        'app',
      ).info('âœ… [POS API] Development mode - returning 2 mock promotions');
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

    if (_appConfig.localStorageOnly) {
      getLogger(
        'app',
      ).info('[POS API] Local storage only mode - returning local promotions');
      try {
        final promotions = await _localDatabaseService
            .listActivePromotionsForShop(shopId);
        return promotions.map((p) => Promotion.fromJson(p)).toList();
      } catch (e) {
        getLogger('app').info('[POS API] Local getActivePromotions failed: $e');
        return [];
      }
    }

    try {
      getLogger(
        'app',
      ).info('ðŸ“¡ [POS API] Calling: $_baseUrl/promotions?shopId=$shopId');

      final response = await _connect.get(
        '$_baseUrl/promotions',
        headers: await _getHeaders(),
        query: {'shopId': shopId},
      );

      getLogger(
        'app',
      ).info('ðŸ“¥ [POS API] Response status: ${response.statusCode}');
      getLogger('app').info('ðŸ“¥ [POS API] Response body: ${response.body}');

      if (response.isOk && response.body['data'] != null) {
        final rawList = asList(response.body['data']);
        final promotions = rawList
            .map((p) => Promotion.fromJson(Map<String, dynamic>.from(p)))
            .toList();
        getLogger('app').info(
          'âœ… [POS API] Successfully parsed ${promotions.length} promotion(s)',
        );

        // Cache the promotions for offline use
        if (cacheManagerService != null) {
          final toCache = rawList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final merchantId = _authService.user.value?.merchantId;
          if (merchantId != null && merchantId.isNotEmpty) {
            await cacheManagerService.cachePromotions(toCache, merchantId);
          }
        }

        if (promotions.isNotEmpty) {
          for (var promo in promotions) {
            final minSpendText = promo.minSpend > 0
                ? 'min: \$${promo.minSpend.toStringAsFixed(2)}'
                : 'no minimum';
            getLogger('app').info(
              '   â€¢ ${promo.name}: ${promo.type} ${promo.value} ($minSpendText)',
            );
          }
        } else {
          getLogger(
            'app',
          ).info('âš ï¸  [POS API] Response contained empty promotions array');
        }

        return promotions;
      } else {
        final errorMsg =
            response.body?['message'] ?? 'Failed to fetch promotions';
        getLogger('app').info('âŒ [POS API] Error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      getLogger('app').info('[POS API] Error fetching promotions: $e');

      // Try to return cached promotions if offline and merchantId is available
      bool isOnline = connectivityService?.isOnline.value ?? true;
      if (!isOnline && cacheManagerService != null) {
        getLogger(
          'app',
        ).info('[POS API] âš ï¸  Returning cached promotions (offline mode)');
        final merchantId = _authService.user.value?.merchantId;
        if (merchantId != null && merchantId.isNotEmpty) {
          final cachedPromotions = await cacheManagerService
              .getCachedPromotions(merchantId);
          if (cachedPromotions != null && cachedPromotions.isNotEmpty) {
            return cachedPromotions.map((p) => Promotion.fromJson(p)).toList();
          }
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
    saleData['id'] ??= const Uuid().v4();
    final clientSaleId = saleData['id'].toString();

    // Get offline services
    OfflineSalesService? offlineSalesService;
    ConnectivityService? connectivityService;

    try {
      offlineSalesService = Get.find<OfflineSalesService>();
    } catch (e) {
      getLogger(
        'app',
      ).info('âš ï¸  [POS API] OfflineSalesService not initialized yet');
    }

    try {
      connectivityService = Get.find<ConnectivityService>();
    } catch (e) {
      getLogger('app').info(
        'âš ï¸  [POS API] ConnectivityService not initialized yet, assuming online',
      );
    }

    // =========================================================================
    // MOCK IMPLEMENTATION (development only)
    // =========================================================================
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));

      final saleId = clientSaleId;
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
        deliveryCharge: saleData['deliveryCharge'] ?? 0.0,
        items: saleItems,
        paymentType: saleData['paymentType'],
        paymentStatus: 'succeeded',
        createdAt: now,
        updatedAt: now,
      );
    }
    // =========================================================================

    if (_appConfig.localStorageOnly) {
      Map<String, dynamic>? safeSaleData;
      try {
        final localDb = Get.find<LocalDatabaseService>();

        final merchantId =
            _authService.user.value?.merchantId ??
            _authService.user.value?.id ??
            'local-merchant';

        safeSaleData = <String, dynamic>{
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
          'customer_id': saleData['customerId'] ?? saleData['customer_id'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        getLogger(
          'app',
        ).info('DEBUG: Local storage sale payload to insert: $safeSaleData');
        getLogger(
          'app',
        ).info('DEBUG: Original saleData at checkout: $saleData');

        final createdSaleId = await localDb.createSaleLocal(safeSaleData);
        getLogger('app').info('DEBUG: Created local sale id: $createdSaleId');

        final saleRow = await localDb.getSaleById(createdSaleId);

        // Save line items as separate sale_items in local DB if it supports it
        final itemRows = (saleData['items'] as List<dynamic>?) ?? [];
        for (var itemIndex = 0; itemIndex < itemRows.length; itemIndex++) {
          final itemData = itemRows[itemIndex];
          if (itemData is Map<String, dynamic>) {
            final itemId =
                itemData['productId']?.toString() ??
                '${DateTime.now().microsecondsSinceEpoch}_$itemIndex';
            final quantity = (itemData['quantity'] as num?)?.toInt() ?? 0;
            // Accept multiple possible keys for item name coming from different UI/flows
            final extractedName = (itemData['itemName'] ?? itemData['item_name'] ?? itemData['name'] ?? itemData['productName'] ?? itemData['product_name'] ?? itemData['title'])?.toString() ?? '';
            final saleItemData = {
              'id': 'sale_item_${itemId}_$createdSaleId',
              'sale_id': createdSaleId,
              'inventory_item_id': itemId,
              'item_name': extractedName,
              'item_sku': itemData['itemSku'] ?? itemData['sku'] ?? '',
              'quantity_sold': quantity,
              'selling_price_at_sale':
                  (itemData['sellingPriceAtSale'] as num?)?.toDouble() ?? (itemData['price'] as num?)?.toDouble() ?? 0.0,
              'original_price_at_sale':
                  (itemData['originalPriceAtSale'] as num?)?.toDouble(),
              'subtotal':
                  quantity *
                  ((itemData['sellingPriceAtSale'] as num?)?.toDouble() ?? (itemData['price'] as num?)?.toDouble() ?? 0.0),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
            if ((saleItemData['item_name'] as String).isEmpty) {
              try {
                // Attempt to lookup inventory item name from local inventory cache
                final invs = await localDb.getInventoryForShopLocal(shopId);
                final match = invs.firstWhere(
                  (i) => (i['id'] ?? i['inventory_item_id'])?.toString() == itemId,
                  orElse: () => {},
                );
                final found = (match['name'] ?? match['name'])?.toString() ?? '';
                if (found.isNotEmpty) {
                  saleItemData['item_name'] = found;
                } else {
                  getLogger('app').info('[POS] saleItem missing name for itemData: $itemData');
                }
              } catch (e) {
                getLogger('app').info('[POS] saleItem name lookup failed: $e');
              }
            }
            await localDb.createSaleItemLocal(saleItemData);

            // Adjust local shop stock down for the sold item (mirror backend inventory decrement).
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
          final quantitySold = (row['quantity_sold'] as num?)?.toInt() ?? 0;
          final sellingPriceAtSale =
              (row['selling_price_at_sale'] as num?)?.toDouble() ?? 0.0;
          final originalPriceAtSale = (row['original_price_at_sale'] as num?)
              ?.toDouble();
          final subtotal =
              (row['subtotal'] as num?)?.toDouble() ??
              (quantitySold * sellingPriceAtSale);
          final createdAtValue = row['created_at'] as String?;
          final updatedAtValue = row['updated_at'] as String?;

          return SaleItem(
            id: row['id']?.toString() ?? '',
            saleId: row['sale_id']?.toString() ?? '',
            inventoryItemId: row['inventory_item_id']?.toString() ?? '',
            quantitySold: quantitySold,
            sellingPriceAtSale: sellingPriceAtSale,
            originalPriceAtSale: originalPriceAtSale,
            subtotal: subtotal,
            createdAt: createdAtValue != null
                ? DateTime.parse(createdAtValue)
                : DateTime.now(),
            updatedAt: updatedAtValue != null
                ? DateTime.parse(updatedAtValue)
                : DateTime.now(),
            itemName: row['item_name']?.toString(),
            itemSku: row['item_sku']?.toString(),
          );
        }).toList();

        final now = DateTime.now();

        // Also persist a local invoice entry so invoices page can display local-only transactions.
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
              sum,
              item,
            ) {
              if (item is Map<String, dynamic>) {
                final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
                final price =
                    (item['sellingPriceAtSale'] as num?)?.toDouble() ?? 0.0;
                return sum + (qty * price);
              }
              return sum;
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
          'customerId': saleData['customerId'] ?? saleData['customer_id'],
          'invoiceDate': now.toIso8601String(),
          'dueDate': null,
          'subtotal': subtotal,
            'discountAmount': discountAmount,
            'taxAmount': explicitTaxAmount ?? (derivedTaxAmount < 0 ? 0.0 : derivedTaxAmount),
            'deliveryCharge': deliveryCharge,
            'totalAmount': totalAmount,
          'paymentStatus': 'succeeded',
          'notes': saleData['notes'] ?? '',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'items': invoiceItems,
        });

        return Sale(
          id: saleRow?['id'] ?? createdSaleId,
          merchantId: saleRow?['merchant_id'] ?? merchantId,
          shopId: saleRow?['shop_id'] ?? shopId,
          saleDate: DateTime.parse(
            saleRow?['sale_date'] ?? now.toIso8601String(),
          ),
          totalAmount:
              (saleRow?['total_amount'] as num?)?.toDouble() ??
              (saleData['totalAmount'] as num?)?.toDouble() ??
              0.0,
          discountAmount:
              (saleRow?['discount_amount'] as num?)?.toDouble() ??
              (saleData['discountAmount'] as num?)?.toDouble() ??
              0.0,
          deliveryCharge:
              (saleRow?['delivery_charge'] as num?)?.toDouble() ??
              (saleData['deliveryCharge'] as num?)?.toDouble() ??
              0.0,
          items: saleItems,
          appliedPromotionId:
              saleRow?['applied_promotion_id'] as String? ??
              saleData['appliedPromotionId'] as String?,
          paymentType:
              saleRow?['payment_type'] ?? saleData['paymentType'] ?? 'cash',
          paymentStatus: saleRow?['payment_status'] ?? 'succeeded',
          createdAt: DateTime.parse(
            saleRow?['created_at'] ?? now.toIso8601String(),
          ),
          updatedAt: DateTime.parse(
            saleRow?['updated_at'] ?? now.toIso8601String(),
          ),
        );
      } catch (e, stackTrace) {
        final debugMsg =
            StringBuffer(
                'Local storage only mode is enabled but saving sale failed: $e',
              )
              ..writeln('\nSafe sale data: ${safeSaleData ?? 'unknown'}')
              ..writeln('Original checkout payload: $saleData')
              ..writeln('Stack trace: $stackTrace');
        final debugMsgString = debugMsg.toString();
        getLogger('app').info('DEBUG: $debugMsgString');
        // Printer-friendly output for emulator / terminal copy
        print('DEBUG: $debugMsgString');
        throw Exception(debugMsgString);
      }
    }

    // Check connectivity
    bool isOnline = connectivityService?.isOnline.value ?? true;

    if (!isOnline && offlineSalesService != null) {
      getLogger(
        'app',
      ).info('[POS API] ðŸ”´ Device is offline - queueing sale for later sync');

      // Queue the sale for offline processing
      final saleQueued = await offlineSalesService.processSale(saleData);

      if (saleQueued) {
        // Create a temporary local sale object for offline mode
        final saleId = clientSaleId;
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
          deliveryCharge: saleData['deliveryCharge'] ?? 0.0,
          items: saleItems,
          paymentType: saleData['paymentType'],
          paymentStatus: 'pending', // Mark as pending offline
          createdAt: now,
          updatedAt: now,
        );

        getLogger('app').info(
          '[POS API] âœ… Sale queued successfully (will sync when online)',
        );
        return offlineSale;
      } else {
        throw Exception('Failed to queue sale for offline processing');
      }
    }

    // If online, attempt to send to backend
    getLogger(
      'app',
    ).info('[POS API] ðŸŸ¢ Device is online - sending sale to backend');
    try {
      final response = await _connect.post(
        '$_baseUrl/checkout',
        saleData..['shopId'] = shopId,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 201 && response.body['data'] != null) {
        getLogger(
          'app',
        ).info('[POS API] âœ… Sale processed successfully online');
        return Sale.fromJson(asMap(response.body['data']));
      } else {
        final errorMsg = response.body?['message'] ?? 'Checkout failed';
        getLogger(
          'app',
        ).info('[POS API] âŒ Backend returned error: $errorMsg');

        // If backend fails, queue for offline retry if service is available
        if (offlineSalesService != null) {
          getLogger('app').info('[POS API] âš ï¸  Queuing sale for retry...');
          await offlineSalesService.processSale(saleData);
        }

        throw Exception(errorMsg);
      }
    } catch (e) {
      getLogger('app').info('[POS API] âŒ Error sending sale to backend: $e');

      // On network error, queue for offline retry if service is available
      if (offlineSalesService != null) {
        getLogger(
          'app',
        ).info('[POS API] âš ï¸  Queuing sale for offline retry...');
        await offlineSalesService.processSale(saleData);
      }

      rethrow;
    }
  }
}
