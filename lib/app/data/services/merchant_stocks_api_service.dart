import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class PaginatedStockResponse {
  final List<InventoryItem> items;
  final int totalCount;

  PaginatedStockResponse({required this.items, required this.totalCount});

  factory PaginatedStockResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedStockResponse(
      items: (json['items'] as List)
          .map((i) => InventoryItem.fromJson(i))
          .toList(),
      totalCount: json['totalItems'],
    );
  }
}

class MerchantStocksApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  String get _baseUrl => '${ApiConstants.baseUrl}/merchant/stocks';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches a combined, paginated list of all inventory items from all shops.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/stocks`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `page`: `int` (The page number to fetch)
  ///   - `pageSize`: `int` (The number of items per page)
  ///   - `searchTerm`: `String` (Optional search term for item name)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "status": "success",
  ///     "data": {
  ///       "items": [
  ///         {
  ///           "id": "uuid-item-1",
  ///           "name": "Laptop",
  ///           "sku": "LP123",
  ///           "quantity": 50,
  ///           "sellingPrice": 1299.99,
  ///           "originalPrice": 950.00,
  ///           "shopName": "Main Street Branch",
  ///           "shopId": "uuid-shop-1"
  ///         }
  ///       ],
  ///       "totalItems": 1
  ///     }
  ///   }
  ///   ```
  Future<PaginatedStockResponse> getCombinedStocks({
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 800));
      final items = List.generate(
        50,
        (i) => InventoryItem(
          id: 'item-$i',
          name: 'Product Name $i',
          sku: 'SKU-00$i',
          sellingPrice: (i + 1) * 12.5,
          originalPrice:
              ((i + 1) * 12.5) * 0.7, // Original price is 70% of selling price
          merchantId: 'mock-merchant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          categoryObj: CategoryRef(
            id: 'cat-${i % 3}',
            name: 'Category ${i % 3}',
          ),
          subcategoryObj: SubcategoryRef(
            id: 'sub-${i % 4}',
            categoryId: 'cat-${i % 3}',
            name: 'Subcategory ${i % 4}',
          ),
          brandObj: BrandRef(id: 'brand-${i % 5}', name: 'Brand ${i % 5}'),
          stockInfo: [
            StockInfo(
              quantity: (i * 5) % 100,
              shopId: 'shop-${i % 2}',
              shopName: i % 2 == 0 ? 'Downtown Store' : 'Uptown Mall',
            ),
          ],
        ),
      );

      return PaginatedStockResponse(items: items, totalCount: items.length);
    }

    // Local-only: build combined stock response from local DB
    if (_appConfig.localStorageOnly) {
      try {
        final localDb = Get.find<LocalDatabaseService>();
        final db = await localDb.database;
        final merchantId =
            _authService.user.value?.merchantId ??
            _authService.user.value?.id ??
            '';
        final whereClauses = <String>[];
        final whereArgs = <dynamic>[];
        if (merchantId.isNotEmpty) {
          whereClauses.add('i.merchant_id = ?');
          whereArgs.add(merchantId);
        }
        if (searchTerm != null && searchTerm.isNotEmpty) {
          whereClauses.add('LOWER(i.name) LIKE ?');
          whereArgs.add('%${searchTerm.toLowerCase()}%');
        }
        final whereSql = whereClauses.isNotEmpty
            ? 'WHERE ${whereClauses.join(' AND ')}'
            : '';
        final allRows = await db.rawQuery('''
          SELECT
            i.id,
            i.merchant_id,
            i.name,
            i.description,
            i.sku,
            i.selling_price,
            i.original_price,
            i.low_stock_threshold,
            i.category,
            i.category_id,
            i.subcategory_id,
            i.brand_id,
            i.supplier_id,
            i.created_at,
            i.updated_at,
            c.id AS category_obj_id,
            c.name AS category_obj_name,
            c.description AS category_obj_description,
            sc.id AS subcategory_obj_id,
            sc.category_id AS subcategory_obj_category_id,
            sc.name AS subcategory_obj_name,
            sc.description AS subcategory_obj_description,
            b.id AS brand_obj_id,
            b.name AS brand_obj_name,
            b.description AS brand_obj_description,
            b.image_url AS brand_obj_image_url
          FROM inventory_items i
          LEFT JOIN categories c ON i.category_id = c.id
          LEFT JOIN subcategories sc ON i.subcategory_id = sc.id
          LEFT JOIN brands b ON i.brand_id = b.id
          $whereSql
          ORDER BY COALESCE(i.created_at, i.updated_at, i.id) DESC
          ''', whereArgs);
        final total = allRows.length;
        final start = (page - 1) * pageSize;
        final end = (start + pageSize) > total ? total : (start + pageSize);
        final pageRows = start < total
            ? allRows.sublist(start, end)
            : <Map<String, dynamic>>[];

        final items = <InventoryItem>[];
        for (final r in pageRows) {
          final id = r['id']?.toString();
          final stockRows = await db.query(
            'shop_stock',
            where: 'inventory_item_id = ?',
            whereArgs: [id],
          );
          final List<StockInfo> stockInfo = stockRows
              .map<StockInfo>(
                (s) => StockInfo(
                  quantity: (s['quantity'] as num?)?.toInt() ?? 0,
                  shopId:
                      s['shop_id']?.toString() ?? s['shopId']?.toString() ?? '',
                  shopName: s['shop_name'] as String?,
                ),
              )
              .toList(growable: false);

          final categoryId = r['category_id'] as String?;
          final subcategoryId = r['subcategory_id'] as String?;
          final brandId = r['brand_id'] as String?;

          final item = InventoryItem(
            id: id,
            merchantId:
                r['merchant_id']?.toString() ??
                r['merchantId']?.toString() ??
                '',
            name: r['name'] as String? ?? '',
            description: r['description'] as String?,
            sku: r['sku'] as String?,
            sellingPrice: (r['selling_price'] as num?)?.toDouble() ?? 0.0,
            originalPrice: (r['original_price'] as num?)?.toDouble() ?? 0.0,
            lowStockThreshold: (r['low_stock_threshold'] as int?),
            category: r['category'] as String?,
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            brandId: brandId,
            supplier: r['supplier_id'] as String?,
            createdAt:
                DateTime.tryParse(r['created_at']?.toString() ?? '') ??
                DateTime.now(),
            updatedAt:
                DateTime.tryParse(r['updated_at']?.toString() ?? '') ??
                DateTime.now(),
            categoryObj: categoryId != null
                ? CategoryRef(
                    id: r['category_obj_id']?.toString() ?? categoryId ?? '',
                    name: r['category_obj_name']?.toString() ?? '',
                    description: r['category_obj_description']?.toString(),
                  )
                : null,
            subcategoryObj: subcategoryId != null
                ? SubcategoryRef(
                    id: r['subcategory_obj_id']?.toString() ?? subcategoryId,
                    categoryId:
                        r['subcategory_obj_category_id']?.toString() ?? '',
                    name: r['subcategory_obj_name']?.toString() ?? '',
                    description: r['subcategory_obj_description']?.toString(),
                  )
                : null,
            brandObj: brandId != null
                ? BrandRef(
                    id: r['brand_obj_id']?.toString() ?? brandId,
                    name: r['brand_obj_name']?.toString() ?? '',
                    description: r['brand_obj_description']?.toString(),
                    imageUrl: r['brand_obj_image_url']?.toString(),
                  )
                : null,
            stockInfo: stockInfo,
          );
          items.add(item);
        }

        return PaginatedStockResponse(items: items, totalCount: total);
      } catch (e) {
        getLogger(
          'app',
        ).info('[MerchantStocksApiService] local getCombinedStocks failed: $e');
        return PaginatedStockResponse(items: [], totalCount: 0);
      }
    }

    final query = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
    };

    final response = await _connect.get(
      _baseUrl,
      headers: await _getHeaders(),
      query: query,
    );

    // Defensive guard: if local-only mode was enabled concurrently, avoid
    // returning network data unexpectedly by checking again.
    if (_appConfig.localStorageOnly) {
      // Prefer the local DB response above; return empty if none.
      return PaginatedStockResponse(items: [], totalCount: 0);
    }

    if (response.isOk && response.body['data'] != null) {
      return PaginatedStockResponse.fromJson(asMap(response.body['data']));
    } else {
      throw Exception(
        response.body?['message'] ?? 'Failed to load combined stock data',
      );
    }
  }
}
