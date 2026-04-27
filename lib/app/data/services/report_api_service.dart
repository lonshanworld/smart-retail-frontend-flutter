import 'dart:math';

import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/report_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class ReportApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDb = Get.find<LocalDatabaseService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/merchant/reports';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches a sales report based on specified filters.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/reports/sales`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `startDate`: `string` (ISO 8601 format)
  ///   - `endDate`: `string` (ISO 8601 format)
  ///   - `shopId`: `string` (Optional)
  ///   - `groupBy`: `string` (e.g., 'daily', 'weekly', 'monthly')
  Future<SalesReportResponse> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    String? shopId,
    String? groupBy,
    bool allowMockData = true,
  }) async {
    getLogger('app').info('ðŸ” [REPORT API] Requesting sales report...');
    getLogger('app').info('   URL: $_baseUrl/sales');
    getLogger('app').info('   Start: ${startDate.toIso8601String()}');
    getLogger('app').info('   End: ${endDate.toIso8601String()}');
    getLogger('app').info('   ShopId: ${shopId ?? "null (all shops)"}');
    getLogger('app').info('   GroupBy: ${groupBy ?? "null"}');

    if (allowMockData && _appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      getLogger(
        'app',
      ).info('âœ… [REPORT API] Development mode - returning 20 mock sales');
      final mockSales = List.generate(20, (index) {
        final date = startDate.add(Duration(days: index % 7));
        return Sale(
          id: 'sale-mock-$index',
          merchantId: 'merchant-mock',
          shopId: shopId ?? 'shop-mock-${index % 3}',
          saleDate: date,
          totalAmount: Random().nextDouble() * 200 + 50,
          deliveryCharge: 0.0,
          items: [], // Simplified for this mock
          paymentType: 'cash',
          paymentStatus: 'succeeded',
          createdAt: date,
          updatedAt: date,
        );
      });
      return SalesReportResponse(sales: mockSales);
    }

    // If running in local-only mode, build the report from the local DB.
    if (_appConfig.localStorageOnly) {
      final merchantId =
          _authService.user.value?.merchantId ??
          _authService.user.value?.id ??
          '';
      final startIso = startDate.toIso8601String();
      final endIso = endDate.toIso8601String();
      final ownedShops = await _localDb.listShopsForMerchant(merchantId);
      final ownedShopIds = ownedShops
          .map((shop) => shop['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      bool matchesMerchantShop(Map<String, dynamic> row) {
        final rowMerchantId =
            row['merchant_id']?.toString() ?? row['merchantId']?.toString();
        final rowShopId =
            row['shop_id']?.toString() ?? row['shopId']?.toString();

        if (merchantId.isNotEmpty &&
            rowMerchantId != null &&
            rowMerchantId.isNotEmpty &&
            rowMerchantId != merchantId) {
          return false;
        }

        if (shopId != null && shopId.isNotEmpty) {
          return rowShopId == shopId;
        }

        if (ownedShopIds.isNotEmpty) {
          return rowShopId != null && ownedShopIds.contains(rowShopId);
        }

        return true;
      }

      bool withinRange(DateTime? dateTime) {
        if (dateTime == null) return false;
        return !dateTime.isBefore(startDate) && !dateTime.isAfter(endDate);
      }

      DateTime? parseRowDate(dynamic rawDate) {
        if (rawDate == null) return null;
        final text = rawDate.toString();
        return DateTime.tryParse(text);
      }

      final sales = <Sale>[];

      final completedRows = await _localDb.getAll('sales');
      for (final row in completedRows) {
        final saleDate = parseRowDate(row['sale_date'] ?? row['saleDate']);
        if (!matchesMerchantShop(row) || !withinRange(saleDate)) {
          continue;
        }

        final saleId = row['id']?.toString() ?? '';
        if (saleId.isEmpty) {
          continue;
        }

        final itemsRows = await _localDb.getSaleItemsForSale(saleId);
        final itemsJson = itemsRows
            .map(
              (ir) => {
                'id': ir['id'],
                'saleId': ir['sale_id'],
                'inventoryItemId': ir['inventory_item_id'],
                'quantitySold': ir['quantity_sold'],
                'sellingPriceAtSale': ir['selling_price_at_sale'],
                'originalPriceAtSale': ir['original_price_at_sale'],
                'subtotal': ir['subtotal'],
                'createdAt': ir['created_at'],
                'updatedAt': ir['updated_at'],
                'itemName': ir['item_name'],
                'itemSku': ir['item_sku'],
              },
            )
            .toList();

        final saleJson = {
          'id': row['id'],
          'shopId': row['shop_id'] ?? row['shopId'],
          'merchantId': row['merchant_id'] ?? row['merchantId'],
          'saleDate': row['sale_date'] ?? row['saleDate'],
          'totalAmount': row['total_amount'] ?? row['totalAmount'],
          'deliveryCharge': row['delivery_charge'] ?? row['deliveryCharge'],
          'appliedPromotionId':
              row['applied_promotion_id'] ?? row['appliedPromotionId'],
          'discountAmount': row['discount_amount'] ?? row['discountAmount'],
          'paymentType': row['payment_type'] ?? row['paymentType'],
          'paymentStatus': row['payment_status'] ?? row['paymentStatus'],
          'stripePaymentIntentId':
              row['stripe_payment_intent_id'] ?? row['stripePaymentIntentId'],
          'notes': row['notes'],
          'createdAt': row['created_at'] ?? row['createdAt'],
          'updatedAt': row['updated_at'] ?? row['updatedAt'],
          'items': itemsJson,
        };

        sales.add(Sale.fromJson(Map<String, dynamic>.from(saleJson)));
      }

      final pendingRows = await _localDb.getAll('pending_sales');
      for (final row in pendingRows) {
        final rowData = row['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(row['data'] as Map)
            : Map<String, dynamic>.from(row);
        final saleDate = parseRowDate(
          rowData['sale_date'] ?? rowData['saleDate'] ?? rowData['timestamp'],
        );
        if (!matchesMerchantShop(rowData) || !withinRange(saleDate)) {
          continue;
        }

        final pendingItems = (rowData['items'] as List?) ?? const [];
        final itemsJson = pendingItems.whereType<Map>().map((item) {
          final map = Map<String, dynamic>.from(item);
          final quantity = (map['quantity'] as num?)?.toInt() ?? 0;
          final sellingPrice =
              (map['sellingPriceAtSale'] as num?)?.toDouble() ??
              (map['selling_price_at_sale'] as num?)?.toDouble() ??
              0.0;
          final originalPrice =
              (map['originalPriceAtSale'] as num?)?.toDouble() ??
              (map['original_price_at_sale'] as num?)?.toDouble();
          return {
            'id': map['id'],
            'saleId': rowData['id'] ?? rowData['sale_id'],
            'inventoryItemId':
                map['productId'] ??
                map['product_id'] ??
                map['inventoryItemId'] ??
                map['inventory_item_id'],
            'quantitySold': quantity,
            'sellingPriceAtSale': sellingPrice,
            'originalPriceAtSale': originalPrice,
            'subtotal':
                (map['subtotal'] as num?)?.toDouble() ??
                quantity * sellingPrice,
            'createdAt':
                map['createdAt'] ?? map['created_at'] ?? rowData['created_at'],
            'updatedAt':
                map['updatedAt'] ?? map['updated_at'] ?? rowData['updated_at'],
            'itemName':
                map['itemName'] ??
                map['item_name'] ??
                map['name'] ??
                map['productName'],
            'itemSku': map['itemSku'] ?? map['item_sku'] ?? map['sku'],
          };
        }).toList();

        final saleJson = {
          'id': rowData['id'] ?? rowData['sale_id'],
          'shopId': rowData['shop_id'] ?? rowData['shopId'],
          'merchantId': rowData['merchant_id'] ?? rowData['merchantId'],
          'saleDate':
              rowData['sale_date'] ??
              rowData['saleDate'] ??
              rowData['timestamp'],
          'totalAmount': rowData['total_amount'] ?? rowData['totalAmount'],
          'deliveryCharge':
              rowData['delivery_charge'] ?? rowData['deliveryCharge'],
          'appliedPromotionId':
              rowData['applied_promotion_id'] ?? rowData['appliedPromotionId'],
          'discountAmount':
              rowData['discount_amount'] ?? rowData['discountAmount'],
          'paymentType':
              rowData['payment_type'] ?? rowData['paymentType'] ?? 'cash',
          'paymentStatus':
              rowData['payment_status'] ??
              rowData['paymentStatus'] ??
              'succeeded',
          'stripePaymentIntentId':
              rowData['stripe_payment_intent_id'] ??
              rowData['stripePaymentIntentId'],
          'notes': rowData['notes'],
          'createdAt':
              rowData['created_at'] ??
              rowData['createdAt'] ??
              rowData['timestamp'],
          'updatedAt':
              rowData['updated_at'] ??
              rowData['updatedAt'] ??
              rowData['timestamp'],
          'items': itemsJson,
        };

        sales.add(Sale.fromJson(Map<String, dynamic>.from(saleJson)));
      }

      sales.sort((left, right) => right.saleDate.compareTo(left.saleDate));
      return SalesReportResponse(sales: sales);
    }

    final response = await _connect.get(
      '$_baseUrl/sales',
      headers: await _getHeaders(),
      query: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (shopId != null) 'shopId': shopId,
        if (groupBy != null) 'groupBy': groupBy,
      },
    );

    // Defensive: if local-only was enabled during the request, prefer local result
    // returned earlier and avoid using remote payload.
    if (_appConfig.localStorageOnly) {
      return SalesReportResponse(sales: []);
    }

    getLogger(
      'app',
    ).info('ðŸ“¥ [REPORT API] Response status: ${response.statusCode}');
    getLogger('app').info('ðŸ“¥ [REPORT API] Response body: ${response.body}');

    if (response.isOk && response.body['data'] != null) {
      getLogger('app').info('âœ… [REPORT API] Parsing sales report response');
      final salesReport = SalesReportResponse.fromJson(
        asMap(response.body['data']),
      );
      getLogger('app').info(
        'âœ… [REPORT API] Successfully parsed ${salesReport.sales.length} sales',
      );
      return salesReport;
    } else {
      final errorMsg =
          response.body?['message'] ?? 'Failed to load sales report';
      getLogger('app').info('âŒ [REPORT API] Error: $errorMsg');
      getLogger('app').info('âŒ [REPORT API] Full response: ${response.body}');
      throw Exception(errorMsg);
    }
  }

  Future<PaginatedSalesResponse> getSalesReportPage({
    required DateTime startDate,
    required DateTime endDate,
    required int page,
    required int pageSize,
    String? shopId,
    String? groupBy,
    bool allowMockData = true,
  }) async {
    if (allowMockData && _appConfig.isDevelopment) {
      final mockResponse = await getSalesReport(
        startDate: startDate,
        endDate: endDate,
        shopId: shopId,
        groupBy: groupBy,
        allowMockData: allowMockData,
      );
      final totalItems = mockResponse.sales.length;
      final start = (page - 1) * pageSize;
      final end = (start + pageSize) > totalItems
          ? totalItems
          : (start + pageSize);
      final items = start < totalItems
          ? mockResponse.sales.sublist(start, end)
          : <Sale>[];
      return PaginatedSalesResponse(
        items: items,
        totalItems: totalItems,
        currentPage: page,
        pageSize: pageSize,
        totalPages: totalItems == 0 ? 0 : (totalItems / pageSize).ceil(),
      );
    }

    if (_appConfig.localStorageOnly) {
      final merchantId =
          _authService.user.value?.merchantId ??
          _authService.user.value?.id ??
          '';
      final startIso = startDate.toIso8601String();
      final endIso = endDate.toIso8601String();
      final db = await _localDb.database;

      final whereClauses = <String>[
        'merchant_id = ?',
        'sale_date BETWEEN ? AND ?',
      ];
      final whereArgs = <dynamic>[merchantId, startIso, endIso];
      if (shopId != null && shopId.isNotEmpty) {
        whereClauses.add('shop_id = ?');
        whereArgs.add(shopId);
      }

      final whereSql = whereClauses.join(' AND ');
      final totalRow = await db.rawQuery(
        'SELECT COUNT(*) AS totalItems FROM sales WHERE $whereSql',
        whereArgs,
      );
      final totalItems = (totalRow.first['totalItems'] as num?)?.toInt() ?? 0;
      final offset = (page - 1) * pageSize;

      final rows = await db.query(
        'sales',
        where: whereSql,
        whereArgs: whereArgs,
        orderBy: 'sale_date DESC',
        limit: pageSize,
        offset: offset,
      );

      final sales = <Sale>[];
      for (final row in rows) {
        final saleId = row['id']?.toString() ?? '';
        if (saleId.isEmpty) {
          continue;
        }

        final itemsRows = await _localDb.getSaleItemsForSale(saleId);
        final itemsJson = itemsRows
            .map(
              (ir) => {
                'id': ir['id'],
                'saleId': ir['sale_id'] ?? ir['saleId'],
                'inventoryItemId':
                    ir['inventory_item_id'] ?? ir['inventoryItemId'],
                'quantitySold': ir['quantity_sold'] ?? ir['quantitySold'],
                'sellingPriceAtSale':
                    ir['selling_price_at_sale'] ?? ir['sellingPriceAtSale'],
                'originalPriceAtSale':
                    ir['original_price_at_sale'] ?? ir['originalPriceAtSale'],
                'subtotal': ir['subtotal'],
                'createdAt': ir['created_at'] ?? ir['createdAt'],
                'updatedAt': ir['updated_at'] ?? ir['updatedAt'],
                'itemName': ir['item_name'] ?? ir['itemName'],
                'itemSku': ir['item_sku'] ?? ir['itemSku'],
              },
            )
            .toList();

        final saleJson = {
          'id': row['id'],
          'shopId': row['shop_id'] ?? row['shopId'],
          'merchantId': row['merchant_id'] ?? row['merchantId'],
          'saleDate': row['sale_date'] ?? row['saleDate'],
          'totalAmount': row['total_amount'] ?? row['totalAmount'],
          'deliveryCharge': row['delivery_charge'] ?? row['deliveryCharge'],
          'appliedPromotionId':
              row['applied_promotion_id'] ?? row['appliedPromotionId'],
          'discountAmount': row['discount_amount'] ?? row['discountAmount'],
          'paymentType': row['payment_type'] ?? row['paymentType'],
          'paymentStatus': row['payment_status'] ?? row['paymentStatus'],
          'notes': row['notes'],
          'createdAt': row['created_at'] ?? row['createdAt'],
          'updatedAt': row['updated_at'] ?? row['updatedAt'],
          'items': itemsJson,
        };

        sales.add(Sale.fromJson(saleJson));
      }

      return PaginatedSalesResponse(
        items: sales,
        totalItems: totalItems,
        currentPage: page,
        pageSize: pageSize,
        totalPages: totalItems == 0 ? 0 : (totalItems / pageSize).ceil(),
      );
    }

    final response = await _connect.get(
      '$_baseUrl/sales',
      headers: await _getHeaders(),
      query: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (shopId != null) 'shopId': shopId,
        if (groupBy != null) 'groupBy': groupBy,
      },
    );

    if (_appConfig.localStorageOnly) {
      return PaginatedSalesResponse(
        items: [],
        totalItems: 0,
        currentPage: page,
        pageSize: pageSize,
        totalPages: 0,
      );
    }

    if (response.isOk && response.body['data'] != null) {
      return PaginatedSalesResponse.fromJson(asMap(response.body['data']));
    }

    final errorMsg = response.body?['message'] ?? 'Failed to load sales report';
    throw Exception(errorMsg);
  }

  /// Fetches a sales forecast for a specific item in a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/reports/sales-forecast`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `shopId`: `string` (UUID of the shop)
  ///   - `itemId`: `string` (UUID of the inventory item)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The sales forecast response object)
  Future<SalesForecastResponse> getSalesForecast(
    String shopId,
    String itemId,
  ) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return SalesForecastResponse(
        reportName: 'Sales Forecast',
        generatedAt: DateTime.now(),
        productName: 'Mock Product',
        shopName: 'Mock Shop',
        currentStock: 100,
        forecastPeriod: ForecastPeriod(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
        ),
        dailyForecast: [],
        aiAnalysis: AiAnalysis(
          summary: 'Mock summary',
          positiveFactors: [],
          negativeFactors: [],
        ),
      );
    }
    final response = await _connect.get(
      '$_baseUrl/sales-forecast',
      headers: await _getHeaders(),
      query: {'shopId': shopId, 'itemId': itemId},
    );

    if (response.statusCode == 200 && response.body['success'] == true) {
      return SalesForecastResponse.fromJson(asMap(response.body['data']));
    } else {
      throw Exception(
        response.body?['message'] ?? 'Failed to load sales forecast',
      );
    }
  }
}
