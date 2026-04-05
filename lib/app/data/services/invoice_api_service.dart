import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class InvoiceApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDb = Get.find<LocalDatabaseService>();

  String _resolveMerchantIdForLocal() {
    return _authService.user.value?.merchantId ?? _authService.user.value?.id ?? '';
  }

  Future<List<Map<String, dynamic>>> _buildLocalInvoiceItems(
    Map<String, dynamic> row, {
    String? fallbackItemId,
  }) async {
    final saleId = (row['saleId'] ?? row['sale_id'])?.toString() ?? '';
    final saleItemId = (row['saleItemId'] ?? row['sale_item_id'])?.toString() ?? '';
    final shopId = (row['shopId'] ?? row['shop_id'])?.toString() ?? '';

    final inventoryLookup = shopId.isNotEmpty
        ? await _localDb.getInventoryForShopLocal(shopId)
        : <Map<String, dynamic>>[];

    Future<Map<String, dynamic>> normalizeSaleItem(Map<String, dynamic> si) async {
      final itemId = (si['inventory_item_id'] ?? si['inventoryItemId'])?.toString() ?? '';
      var itemName = (si['item_name'] ?? si['itemName'])?.toString() ?? '';
      if (itemName.isEmpty && itemId.isNotEmpty && inventoryLookup.isNotEmpty) {
        final match = inventoryLookup.firstWhereOrNull(
          (item) => (item['id'] ?? item['inventory_item_id'])?.toString() == itemId,
        );
        itemName = (match?['name'] ?? match?['title'])?.toString() ?? '';
      }
      return {
        'id': si['id'],
        'saleId': si['sale_id'] ?? si['saleId'],
        'inventoryItemId': si['inventory_item_id'] ?? si['inventoryItemId'],
        'itemName': itemName,
        'itemSku': si['item_sku'] ?? si['itemSku'],
        'quantitySold': si['quantity_sold'] ?? si['quantitySold'],
        'sellingPriceAtSale': si['selling_price_at_sale'] ?? si['sellingPriceAtSale'],
        'subtotal': si['subtotal'],
      };
    }

    if (saleId.isNotEmpty) {
      final saleItems = await _localDb.getSaleItemsForSale(saleId);
      if (saleItems.isNotEmpty) {
        return Future.wait(saleItems.map(normalizeSaleItem));
      }
    }

    final lookupItemId = saleItemId.isNotEmpty ? saleItemId : (fallbackItemId ?? '');
    if (lookupItemId.isNotEmpty) {
      final allSaleItems = await _localDb.getAll('sale_items');
      final match = allSaleItems.firstWhereOrNull(
        (item) =>
            (item['id'] ?? item['sale_item_id'])?.toString() == lookupItemId ||
            (item['sale_id'] ?? item['saleId'])?.toString() == lookupItemId,
      );
      if (match != null) {
        final matchSaleId = (match['sale_id'] ?? match['saleId'])?.toString() ?? '';
        if (matchSaleId.isNotEmpty) {
          final saleItems = await _localDb.getSaleItemsForSale(matchSaleId);
          if (saleItems.isNotEmpty) {
            return Future.wait(saleItems.map(normalizeSaleItem));
          }
        }
        return [await normalizeSaleItem(match)];
      }
    }

    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> _enrichInvoiceRow(Map<String, dynamic> row) async {
    final enriched = Map<String, dynamic>.from(row);
    final shopId = (enriched['shopId'] ?? enriched['shop_id'])?.toString() ?? '';
    if ((enriched['shopName'] == null && enriched['shop_name'] == null) && shopId.isNotEmpty) {
      final shop = await _localDb.getShopById(shopId);
      final shopName = shop?['name']?.toString();
      if (shopName != null && shopName.isNotEmpty) {
        enriched['shopName'] = shopName;
      }
    }

    final checkoutTime = enriched['checkoutTime'] ?? enriched['checkout_time'] ?? enriched['invoiceDate'] ?? enriched['invoice_date'] ?? enriched['saleDate'] ?? enriched['sale_date'];
    if (checkoutTime != null) {
      enriched['checkoutTime'] = checkoutTime;
    }
    return enriched;
  }

  Future<String?> _getAuthToken() async {
    return await _authService.getToken();
  }

  final String _merchantInvoicesBase =
      "${ApiConstants.baseUrl}/merchant/invoices";
  final String _shopInvoicesBasePrefix =
      "${ApiConstants.baseUrl}/shop/shops"; // append /:shopId/invoices
  final String _staffInvoicesBase = "${ApiConstants.baseUrl}/staff/invoices";

  /// Fetches a paginated list of invoices for the merchant.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/invoices`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `page`: `int` (The page number to fetch)
  ///   - `pageSize`: `int` (The number of items per page)
  ///   - `shopId`: `string` (Optional shop filter)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "status": "success",
  ///     "data": {
  ///       "items": [...],
  ///       "pagination": {
  ///         "totalItems": 100,
  ///         "currentPage": 1,
  ///         "pageSize": 10,
  ///         "totalPages": 10
  ///       }
  ///     }
  ///   }
  ///   ```
  Future<PaginatedInvoicesResponse?> listInvoices({
    int page = 1,
    int pageSize = 10,
    String? shopId,
  }) async {
    if (_appConfig.localStorageOnly) {
      // Return invoices from local DB
      final merchantId = _resolveMerchantIdForLocal();
      try {
        final rows = await _localDb.listInvoicesForMerchantLocal(
          merchantId,
          page: page,
          pageSize: pageSize,
          shopId: shopId,
        );

        final items = rows.map((r) => Invoice.fromJson(r)).toList();
        final totalItems = items.length; // best-effort
        final totalPages = (totalItems / pageSize).ceil();
        return PaginatedInvoicesResponse(
          items: items,
          totalItems: totalItems,
          currentPage: page,
          pageSize: pageSize,
          totalPages: totalPages,
        );
      } catch (e, st) {
        if (kDebugMode) {
          getLogger('app').info('[InvoiceApiService] local listInvoices error: $e');
        }
        if (kDebugMode) {
          getLogger('app').info(st);
        }
        return null;
      }
    }

    final token = await _getAuthToken();
    if (token == null) {
      if (kDebugMode) {
        getLogger('app').info('[InvoiceApiService] Auth token is null when listing invoices');
      }
      return null;
    }

    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    // Determine endpoint based on user role
    final role = await _authService.getUserRole();
    final assignedShopId = await _authService.getShopId();
    String endpoint;
      if (role == 'merchant') {
      endpoint = _merchantInvoicesBase;
      if (shopId != null && shopId.isNotEmpty) {
        queryParams['shopId'] = shopId;
      }
    } else if (role == 'staff') {
      // Staff can use the staff-scoped endpoint which derives shop from their assigned_shop_id
      endpoint = _staffInvoicesBase;
      } else if (role == 'shop') {
        // Shop-level login (could be merchant or shop role that requires shopId)
        final sid = shopId ?? assignedShopId;
        if (sid == null || sid.isEmpty) {
          if (kDebugMode) {
            getLogger('app').info(
              '[InvoiceApiService] No shopId available for shop role when listing invoices',
            );
          }
          return null;
        }
        endpoint = '$_shopInvoicesBasePrefix/$sid/invoices';
      } else {
      // fallback to merchant endpoint
      endpoint = _merchantInvoicesBase;
      if (shopId != null && shopId.isNotEmpty) {
        queryParams['shopId'] = shopId;
      }
    }

    try {
      final response = await _connect.get(
        endpoint,
        headers: {'Authorization': 'Bearer $token'},
        query: queryParams,
      );

      if (kDebugMode) {
        getLogger('app').info(
          '[InvoiceApiService] listInvoices response status: ${response.statusCode}',
        );
      }

      if (response.statusCode == 200 && response.body != null) {
        final bodyMap = response.body as Map<String, dynamic>;
        if (bodyMap['status'] == 'success' && bodyMap['data'] != null) {
          return PaginatedInvoicesResponse.fromJson(bodyMap['data']);
        }
      }

      getLogger('app').info('[InvoiceApiService] Unexpected response format or status');
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        getLogger('app').info('[InvoiceApiService] Error listing invoices: $e');
      }
      if (kDebugMode) {
        getLogger('app').info(stackTrace);
      }
      return null;
    }
  }

  /// Fetches a single invoice by ID.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/invoices/:invoiceId`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "status": "success",
  ///     "data": { ... invoice object ... }
  ///   }
  ///   ```
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    if (_appConfig.localStorageOnly) {
      try {
        var row = await _localDb.getInvoiceByIdLocal(invoiceId);
        if (kDebugMode) {
          getLogger('app').info('Local DB lookup for invoiceId $invoiceId returned: $row');
        }
        // fallback lookups if direct ID lookup fails
        if (row == null) {
          final rows = await _localDb.listInvoicesForMerchantLocal(
            _resolveMerchantIdForLocal(),
          );
          row = rows.firstWhereOrNull((i) {
            final rowId = i['id']?.toString() ?? '';
            final rowSaleId = i['saleId']?.toString() ?? i['sale_id']?.toString() ?? '';
            final rowInvoiceNumber = i['invoiceNumber']?.toString() ?? i['invoice_number']?.toString() ?? '';
            return rowId == invoiceId ||
                rowSaleId == invoiceId ||
                rowInvoiceNumber == invoiceId;
          });
        }

        if (row == null) {
          // Try fallback directly using local database if we have a chance
          final allRows = await _localDb.getAll('invoices');
          row = allRows.firstWhereOrNull((i) {
            final rowId = i['id']?.toString() ?? '';
            final rowSaleId = i['saleId']?.toString() ?? i['sale_id']?.toString() ?? '';
            final rowInvoiceNumber = i['invoiceNumber']?.toString() ?? i['invoice_number']?.toString() ?? '';
            return rowId == invoiceId ||
                rowSaleId == invoiceId ||
                rowInvoiceNumber == invoiceId;
          });
        }

        if (row == null) {
          return null;
        }

        row['items'] = await _buildLocalInvoiceItems(row, fallbackItemId: invoiceId);
        row = await _enrichInvoiceRow(row);
        row['items'] = await _buildLocalInvoiceItems(row, fallbackItemId: invoiceId);
        return Invoice.fromJson(row);
      } catch (e, st) {
        if (kDebugMode) {
          getLogger('app').info('[InvoiceApiService] local getInvoiceById error: $e');
        }
        if (kDebugMode) {
          getLogger('app').info(st);
        }
        return null;
      }
    }

    final token = await _getAuthToken();
    if (token == null) {
      if (kDebugMode) {
        getLogger('app').info(
          '[InvoiceApiService] Auth token is null when fetching invoice by ID',
        );
      }
      return null;
    }

    try {
      // choose endpoint based on role
      final role = await _authService.getUserRole();
      final assignedShopId = await _authService.getShopId();
      String url;
      if (role == 'merchant') {
        url = '$_merchantInvoicesBase/$invoiceId';
      } else if (role == 'staff') {
        url = '$_staffInvoicesBase/$invoiceId';
      } else if (role == 'shop') {
        final sid = assignedShopId;
        if (sid == null || sid.isEmpty) {
          if (kDebugMode) {
            getLogger('app').info(
              '[InvoiceApiService] No shopId available for shop role when fetching invoice by ID',
            );
          }
          return null;
        }
        url = '$_shopInvoicesBasePrefix/$sid/invoices/$invoiceId';
      } else {
        url = '$_merchantInvoicesBase/$invoiceId';
      }

      final response = await _connect.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        getLogger('app').info(
          '[InvoiceApiService] getInvoiceById response status: ${response.statusCode}',
        );
      }
      // Debug: print response body to help diagnose missing items
      try {
        if (kDebugMode) {
          getLogger('app').info('[InvoiceApiService] response body: ${response.body}');
        }
      } catch (e) {
        if (kDebugMode) {
          getLogger('app').info('[InvoiceApiService] failed to print response body: $e');
        }
      }

      if (response.statusCode == 200 && response.body != null) {
        final bodyMap = response.body as Map<String, dynamic>;
        if (bodyMap['status'] == 'success' && bodyMap['data'] != null) {
          return Invoice.fromJson(bodyMap['data']);
        }
      }

      getLogger('app').info('[InvoiceApiService] Invoice not found or unexpected response');
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        getLogger('app').info('[InvoiceApiService] Error fetching invoice by ID: $e');
      }
      if (kDebugMode) {
        getLogger('app').info(stackTrace);
      }
      return null;
    }
  }

  /// Fetches an invoice by sale ID.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/invoices/sale/:saleId`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "status": "success",
  ///     "data": { ... invoice object ... }
  ///   }
  ///   ```
  Future<Invoice?> getInvoiceBySaleId(String saleId) async {
    if (_appConfig.localStorageOnly) {
      try {
        final row = await _localDb.getInvoiceBySaleIdLocal(saleId);
        if (row == null) return null;
        row['items'] = await _buildLocalInvoiceItems(row, fallbackItemId: saleId);
        final enriched = await _enrichInvoiceRow(row);
        enriched['items'] = await _buildLocalInvoiceItems(enriched, fallbackItemId: saleId);
        return Invoice.fromJson(enriched);
      } catch (e, st) {
        if (kDebugMode) getLogger('app').info('[InvoiceApiService] local getInvoiceBySaleId error: $e');
        if (kDebugMode) getLogger('app').info(st);
        return null;
      }
    }

    final token = await _getAuthToken();
    if (token == null) {
      if (kDebugMode) {
        getLogger('app').info(
          '[InvoiceApiService] Auth token is null when fetching invoice by sale ID',
        );
      }
      return null;
    }

    try {
      final response = await _connect.get(
        '$_merchantInvoicesBase/sale/$saleId',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        getLogger('app').info(
          '[InvoiceApiService] getInvoiceBySaleId response status: ${response.statusCode}',
        );
      }

      if (response.statusCode == 200 && response.body != null) {
        final bodyMap = response.body as Map<String, dynamic>;
        if (bodyMap['status'] == 'success' && bodyMap['data'] != null) {
          return Invoice.fromJson(bodyMap['data']);
        }
      }
      if (kDebugMode) {
        getLogger('app').info('[InvoiceApiService] Invoice not found or unexpected response');
      }
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        getLogger('app').info('[InvoiceApiService] Error fetching invoice by sale ID: $e');
      }
      if (kDebugMode) {
        getLogger('app').info(stackTrace);
      }
      return null;
    }
  }
}

