import 'dart:convert';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/supplier_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:logging/logging.dart';

class InventoryApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  String? _currentMerchantId() {
    return _authService.user.value?.merchantId ?? _authService.user.value?.id;
  }

  String? _currentScopeMerchantId() {
    final merchantId = _authService.user.value?.merchantId;
    if (merchantId != null && merchantId.isNotEmpty) {
      return merchantId;
    }
    final fallback = _authService.user.value?.id;
    return fallback != null && fallback.isNotEmpty ? fallback : null;
  }

  bool _matchesMerchant(Map<String, dynamic> row, String merchantId) {
    final rowMerchantId = row['merchant_id']?.toString() ?? row['merchantId']?.toString();
    return rowMerchantId == merchantId;
  }
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();
  final Logger _logger = Logger('InventoryApiService');

  Future<String?> _getAuthToken() async {
    return await _authService.getToken();
  }

  bool _shouldQueue(dynamic error) {
    final text = error.toString().toLowerCase();
    return _appConfig.localStorageOnly ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection') ||
        text.contains('timeout');
  }

  Future<void> _queueMutation({
    required String clientOperationId,
    required String entityType,
    required String action,
    required String endpoint,
    required Map<String, dynamic> payload,
    String method = 'POST',
  }) async {
    await _localDatabaseService.queueOperation({
      'id': clientOperationId,
      'client_operation_id': clientOperationId,
      'entity_type': entityType,
      'action': action,
      'method': method,
      'endpoint': endpoint,
      'payload': payload,
      'headers': {'X-Client-Operation-Id': clientOperationId},
    });
  }

  final String _inventoryBaseUrl = "${ApiConstants.baseUrl}/merchant/inventory";
  final String _suppliersBaseUrl = "${ApiConstants.baseUrl}/merchant/suppliers";
  final String _catalogBaseUrl = "${ApiConstants.baseUrl}/merchant/catalog";

  Future<CatalogOptionsResponse?> getCatalogOptions() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 250));
      return CatalogOptionsResponse(categories: [], brands: []);
    }

    // Local-only: read catalog options from the local DB so UI can operate offline.
    if (_appConfig.localStorageOnly) {
      try {
        final db = await _localDatabaseService.database;
        final merchantId = _currentScopeMerchantId();

        // Detect table schema for categories (structured vs JSON 'data' column)
        final pragma = await db.rawQuery("PRAGMA table_info('categories')");
        final hasDataCol = pragma.any((c) => (c['name'] as String?) == 'data');

        List<Map<String, dynamic>> catRows = [];
        if (hasDataCol) {
          final raw = await db.query('categories');
          for (final r in raw) {
            final data = r['data'] as String?;
            if (data != null) {
              try {
                final parsed = json.decode(data) as Map<String, dynamic>;
                if (!parsed.containsKey('id')) parsed['id'] = r['id'];
                if (merchantId == null || _matchesMerchant(parsed, merchantId)) {
                  catRows.add(parsed);
                }
              } catch (_) {
                // ignore malformed
              }
            }
          }
        } else {
          catRows = await db.query(
            'categories',
            where: merchantId != null ? 'merchant_id = ?' : null,
            whereArgs: merchantId != null ? [merchantId] : null,
            orderBy: 'created_at DESC, id DESC',
          );
        }

        // Subcategories (support JSON-backed or structured)
        final pragmaSub = await db.rawQuery("PRAGMA table_info('subcategories')");
        final hasSubData = pragmaSub.any((c) => (c['name'] as String?) == 'data');
        List<Map<String, dynamic>> subRows = [];
        if (hasSubData) {
          final raw = await db.query('subcategories');
          for (final r in raw) {
            final data = r['data'] as String?;
            if (data != null) {
              try {
                final parsed = json.decode(data) as Map<String, dynamic>;
                if (!parsed.containsKey('id')) parsed['id'] = r['id'];
                final parsedCategory = parsed['categoryId']?.toString() ?? parsed['category_id']?.toString();
                final categoryBelongsToMerchant = catRows.any(
                  (category) => category['id']?.toString() == parsedCategory,
                );
                if (merchantId == null || _matchesMerchant(parsed, merchantId) || categoryBelongsToMerchant) {
                  subRows.add(parsed);
                }
              } catch (_) {}
            }
          }
        } else {
          subRows = await db.query(
            'subcategories',
            where: merchantId != null ? 'merchant_id = ?' : null,
            whereArgs: merchantId != null ? [merchantId] : null,
            orderBy: 'created_at DESC, id DESC',
          );
        }

        final Map<String, List<Map<String, dynamic>>> subsByCat = {};
        for (final s in subRows) {
          final cid = s['categoryId'] as String? ?? s['category_id'] as String? ?? '';
          subsByCat.putIfAbsent(cid ?? '', () => []).add(s);
        }

        final categories = catRows.map((r) {
          final cid = r['id'] as String;
          final rawSubs = (subsByCat[cid] ?? []).map((s) => {
                'id': s['id'],
                'categoryId': s['categoryId'] ?? s['category_id'],
                'name': s['name'],
                'description': s['description'],
                'createdAt': s['createdAt'] ?? s['created_at'],
                'updatedAt': s['updatedAt'] ?? s['updated_at'],
              }).toList();
          return {
            'id': r['id'],
            'name': r['name'] ?? (r['data'] != null ? (json.decode(r['data'] as String) as Map<String, dynamic>)['name'] : null),
            'description': r['description'] ?? (r['data'] != null ? (json.decode(r['data'] as String) as Map<String, dynamic>)['description'] : null),
            'subcategories': rawSubs,
          };
        }).toList();

        // Brands (support JSON-backed or structured)
        final pragmaBrand = await db.rawQuery("PRAGMA table_info('brands')");
        final hasBrandData = pragmaBrand.any((c) => (c['name'] as String?) == 'data');
        List<Map<String, dynamic>> brandRows = [];
        if (hasBrandData) {
          final raw = await db.query('brands');
          for (final r in raw) {
            final data = r['data'] as String?;
            if (data != null) {
              try {
                final parsed = json.decode(data) as Map<String, dynamic>;
                if (!parsed.containsKey('id')) parsed['id'] = r['id'];
                if (merchantId == null || _matchesMerchant(parsed, merchantId)) {
                  brandRows.add(parsed);
                }
              } catch (_) {}
            }
          }
        } else {
          brandRows = await db.query(
            'brands',
            where: merchantId != null ? 'merchant_id = ?' : null,
            whereArgs: merchantId != null ? [merchantId] : null,
            orderBy: 'created_at DESC, id DESC',
          );
        }

        final brands = brandRows
          .map((b) => {
              'id': b['id'],
              'name': b['name'] ?? (b['data'] != null ? (json.decode(b['data'] as String) as Map<String, dynamic>)['name'] : null),
              'description': b['description'] ?? (b['data'] != null ? (json.decode(b['data'] as String) as Map<String, dynamic>)['description'] : null),
              'imageUrl': b['image_url'] ?? b['imageUrl'] ?? (b['data'] != null ? (json.decode(b['data'] as String) as Map<String, dynamic>)['imageUrl'] : null),
            })
          .toList();

        return CatalogOptionsResponse(
            categories: categories
                .map((c) => CategoryWithSubcategories.fromJson(Map<String, dynamic>.from(c)))
                .toList(),
            brands: brands
                .map((b) => BrandRef.fromJson(Map<String, dynamic>.from(b)))
                .toList());
      } catch (e) {
        _logger.warning('local getCatalogOptions failed: $e');
        return CatalogOptionsResponse(categories: [], brands: []);
      }
    }

    final token = await _getAuthToken();
    if (token == null) return null;

    final response = await _connect.get(
      '$_catalogBaseUrl/options',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return CatalogOptionsResponse.fromJson(asMap(response.body['data']));
    }

    _logger.warning('Error loading catalog options: ${response.statusCode} - ${response.bodyString}');
    return null;
  }

  Future<bool> createCategory({
    required String name,
    String? description,
  }) async {
    final clientOperationId = const Uuid().v4();
    final token = await _getAuthToken();
    if (token == null) return false;

    final payload = {
      'name': name,
      'clientOperationId': clientOperationId,
      if (description != null && description.isNotEmpty)
        'description': description,
    };

    try {
      if (_appConfig.localStorageOnly) {
        final merchantId = _currentScopeMerchantId();
        final toSave = {
          'id': clientOperationId,
          'name': name,
          'description': description,
          if (merchantId != null) 'merchantId': merchantId,
          if (merchantId != null) 'merchant_id': merchantId,
        };
        await _localDatabaseService.upsertCategory(toSave);
        return true;
      }

      final response = await _connect.post(
        '$_catalogBaseUrl/categories',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      return response.statusCode == 201 && response.body['status'] == 'success';
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          entityType: 'catalog_category',
          action: 'create',
          endpoint: '$_catalogBaseUrl/categories',
          payload: payload,
        );
        return true;
      }
      rethrow;
    }
  }

  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    String? description,
  }) async {
    final clientOperationId = const Uuid().v4();
    final token = await _getAuthToken();
    if (token == null) return false;

    final payload = {
      'name': name,
      'clientOperationId': clientOperationId,
      if (description != null && description.isNotEmpty)
        'description': description,
    };

    try {
      if (_appConfig.localStorageOnly) {
        final merchantId = _currentScopeMerchantId();
        final toSave = {
          'id': categoryId,
          'name': name,
          'description': description,
          if (merchantId != null) 'merchantId': merchantId,
          if (merchantId != null) 'merchant_id': merchantId,
        };
        await _localDatabaseService.upsertCategory(toSave);
        return true;
      }

      final response = await _connect.put(
        '$_catalogBaseUrl/categories/$categoryId',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      return response.statusCode == 200 && response.body['status'] == 'success';
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          entityType: 'catalog_category',
          action: 'update',
          endpoint: '$_catalogBaseUrl/categories/$categoryId',
          payload: payload,
          method: 'PUT',
        );
        return true;
      }
      rethrow;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    final clientOperationId = const Uuid().v4();
    final token = await _getAuthToken();
    if (token == null) return false;

    try {
      if (_appConfig.localStorageOnly) {
        await _localDatabaseService.database.then((db) => db.delete('categories', where: 'id = ?', whereArgs: [categoryId]));
        return true;
      }

      final response = await _connect.delete(
        '$_catalogBaseUrl/categories/$categoryId',
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          entityType: 'catalog_category',
          action: 'delete',
          endpoint: '$_catalogBaseUrl/categories/$categoryId',
          payload: {'categoryId': categoryId},
          method: 'DELETE',
        );
        return true;
      }
      rethrow;
    }
  }

  Future<bool> createSubcategory({
    required String categoryId,
    required String name,
    String? description,
  }) async {
    final clientOperationId = const Uuid().v4();
    final token = await _getAuthToken();
    if (token == null) return false;

    final payload = {
      'categoryId': categoryId,
      'name': name,
      'clientOperationId': clientOperationId,
      if (description != null && description.isNotEmpty)
        'description': description,
    };

    try {
      if (_appConfig.localStorageOnly) {
        final db = await _localDatabaseService.database;
        final now = DateTime.now().toIso8601String();
        final merchantId = _currentScopeMerchantId();
        // Detect whether subcategories table is JSON-backed (data column) or structured
        final pragma = await db.rawQuery("PRAGMA table_info('subcategories')");
        final hasData = pragma.any((c) => (c['name'] as String?) == 'data');
        if (hasData) {
          final payload = {
            'id': clientOperationId,
            'categoryId': categoryId,
            'name': name,
            'description': description,
            if (merchantId != null) 'merchantId': merchantId,
            if (merchantId != null) 'merchant_id': merchantId,
            'createdAt': now,
            'updatedAt': now,
          };
          await db.insert('subcategories', {'id': clientOperationId, 'data': json.encode(payload)});
        } else {
          await db.insert('subcategories', {
            'id': clientOperationId,
            'category_id': categoryId,
            'name': name,
            'description': description,
            if (merchantId != null) 'merchant_id': merchantId,
            'created_at': now,
            'updated_at': now,
          });
        }
        return true;
      }

      final response = await _connect.post(
        '$_catalogBaseUrl/subcategories',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      return response.statusCode == 201 && response.body['status'] == 'success';
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          entityType: 'catalog_subcategory',
          action: 'create',
          endpoint: '$_catalogBaseUrl/subcategories',
          payload: payload,
        );
        return true;
      }
      rethrow;
    }
  }

  Future<bool> updateSubcategory({
    required String subcategoryId,
    required String categoryId,
    required String name,
    String? description,
  }) async {
    final clientOperationId = const Uuid().v4();
    final token = await _getAuthToken();
    if (token == null) return false;

    final payload = {
      'categoryId': categoryId,
      'name': name,
      'clientOperationId': clientOperationId,
      if (description != null && description.isNotEmpty)
        'description': description,
    };

    try {
      if (_appConfig.localStorageOnly) {
        final db = await _localDatabaseService.database;
        final now = DateTime.now().toIso8601String();
        final merchantId = _currentScopeMerchantId();
        final pragma = await db.rawQuery("PRAGMA table_info('subcategories')");
        final hasData = pragma.any((c) => (c['name'] as String?) == 'data');
        if (hasData) {
          final rows = await db.query('subcategories', where: 'id = ?', whereArgs: [subcategoryId]);
          if (rows.isNotEmpty) {
            final existingData = rows.first['data'] as String?;
            Map<String, dynamic> parsed = {};
            if (existingData != null) {
              try {
                parsed = json.decode(existingData) as Map<String, dynamic>;
              } catch (_) {}
            }
            parsed['categoryId'] = categoryId;
            parsed['name'] = name;
            parsed['description'] = description;
            if (merchantId != null) {
              parsed['merchantId'] = merchantId;
              parsed['merchant_id'] = merchantId;
            }
            parsed['updatedAt'] = now;
            await db.update('subcategories', {'data': json.encode(parsed)}, where: 'id = ?', whereArgs: [subcategoryId]);
          } else {
            final payload = {
              'id': subcategoryId,
              'categoryId': categoryId,
              'name': name,
              'description': description,
              if (merchantId != null) 'merchantId': merchantId,
              if (merchantId != null) 'merchant_id': merchantId,
              'updatedAt': now,
            };
            await db.insert('subcategories', {'id': subcategoryId, 'data': json.encode(payload)});
          }
        } else {
          await db.update('subcategories', {
            'category_id': categoryId,
            'name': name,
            'description': description,
            if (merchantId != null) 'merchant_id': merchantId,
            'updated_at': now,
          }, where: 'id = ?', whereArgs: [subcategoryId]);
        }
        return true;
      }

      final response = await _connect.put(
        '$_catalogBaseUrl/subcategories/$subcategoryId',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      return response.statusCode == 200 && response.body['status'] == 'success';
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          entityType: 'catalog_subcategory',
          action: 'update',
          endpoint: '$_catalogBaseUrl/subcategories/$subcategoryId',
          payload: payload,
          method: 'PUT',
        );
        return true;
      }
      rethrow;
    }
  }

  Future<bool> deleteSubcategory(String subcategoryId) async {
    final clientOperationId = const Uuid().v4();
    final token = await _getAuthToken();
    if (token == null) return false;

    try {
      if (_appConfig.localStorageOnly) {
        await _localDatabaseService.database.then((db) => db.delete('subcategories', where: 'id = ?', whereArgs: [subcategoryId]));
        return true;
      }

      final response = await _connect.delete(
        '$_catalogBaseUrl/subcategories/$subcategoryId',
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          entityType: 'catalog_subcategory',
          action: 'delete',
          endpoint: '$_catalogBaseUrl/subcategories/$subcategoryId',
          payload: {'subcategoryId': subcategoryId},
          method: 'DELETE',
        );
        return true;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createBrand({
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    final clientOperationId = const Uuid().v4();
    final token = await _getAuthToken();
    if (token == null) return {'ok': false, 'message': 'Not authenticated'};

    final payload = {
      'name': name,
      'clientOperationId': clientOperationId,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
    };

    dynamic response;
    try {
      if (_appConfig.localStorageOnly) {
        final merchantId = _currentScopeMerchantId();
        await _localDatabaseService.upsertBrand({
          'id': clientOperationId,
          'name': name,
          'description': description,
          'image_url': imageUrl,
          if (merchantId != null) 'merchantId': merchantId,
          if (merchantId != null) 'merchant_id': merchantId,
        });
        return {'ok': true, 'message': 'Brand created locally'};
      }

      response = await _connect.post(
        '$_catalogBaseUrl/brands',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );

      if (response != null && response.statusCode == 201 && response.body['status'] == 'success') {
        return {'ok': true, 'message': 'Brand created'};
      }
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          entityType: 'catalog_brand',
          action: 'create',
          endpoint: '$_catalogBaseUrl/brands',
          payload: payload,
        );
        return {'ok': true, 'message': 'Brand queued locally'};
      }
      rethrow;
    }

    final msg = (response != null && response.body is Map && response.body['message'] != null)
        ? response.body['message'].toString()
        : ((response != null && response.bodyString != null) ? response.bodyString : 'Failed to create brand');
    return {'ok': false, 'message': msg};
  }

  Future<bool> updateBrand({
    required String brandId,
    required String name,
    String? description,
  }) async {
    final clientOperationId = const Uuid().v4();
    final token = await _getAuthToken();
    if (token == null) return false;

    final payload = {
      'name': name,
      'clientOperationId': clientOperationId,
      if (description != null && description.isNotEmpty)
        'description': description,
    };

    try {
      if (_appConfig.localStorageOnly) {
        final merchantId = _currentScopeMerchantId();
        await _localDatabaseService.upsertBrand({
          'id': brandId,
          'name': name,
          'description': description,
          if (merchantId != null) 'merchantId': merchantId,
          if (merchantId != null) 'merchant_id': merchantId,
        });
        return true;
      }

      final response = await _connect.put(
        '$_catalogBaseUrl/brands/$brandId',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      return response.statusCode == 200 && response.body['status'] == 'success';
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          entityType: 'catalog_brand',
          action: 'update',
          endpoint: '$_catalogBaseUrl/brands/$brandId',
          payload: payload,
          method: 'PUT',
        );
        return true;
      }
      rethrow;
    }
  }

  Future<bool> deleteBrand(String brandId) async {
    final clientOperationId = const Uuid().v4();
    final token = await _getAuthToken();
    if (token == null) return false;

    try {
      final response = await _connect.delete(
        '$_catalogBaseUrl/brands/$brandId',
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          entityType: 'catalog_brand',
          action: 'delete',
          endpoint: '$_catalogBaseUrl/brands/$brandId',
          payload: {'brandId': brandId},
          method: 'DELETE',
        );
        return true;
      }
      rethrow;
    }
  }

  // --- Supplier Specific Methods --- //

  /// Fetches a paginated list of suppliers for the merchant.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/suppliers`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `page`: `int` (The page number to fetch)
  ///   - `pageSize`: `int` (The number of items per page)
  ///   - `name`: `string` (Optional name to filter by)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "status": "success",
  ///     "data": {
  ///       "data": [
  ///         {
  ///           "id": "uuid-supplier-1",
  ///           "merchantId": "uuid-merchant-1",
  ///           "name": "Supplier A",
  ///           "contactName": "John Smith",
  ///           "contactEmail": "john@suppliera.com",
  ///           "contactPhone": "1112223333",
  ///           "address": "123 Supplier Lane",
  ///           "notes": "Notes about Supplier A",
  ///           "createdAt": "2023-01-01T12:00:00Z",
  ///           "updatedAt": "2023-10-01T12:00:00Z"
  ///         }
  ///       ],
  ///       "pagination": {
  ///         "totalItems": 1,
  ///         "currentPage": 1,
  ///         "pageSize": 10,
  ///         "totalPages": 1
  ///       }
  ///     }
  ///   }
  ///   ```
  Future<PaginatedSuppliersResponse?> listMerchantSuppliers({
    int page = 1,
    int pageSize = 10,
    String? nameQuery,
  }) async {
    // Added nameQuery
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return PaginatedSuppliersResponse(
        suppliers: [],
        totalItems: 0,
        currentPage: 1,
        pageSize: 10,
        totalPages: 0,
      );
    }
    // Local-only short-circuit
    if (_appConfig.localStorageOnly) {
      try {
        final db = await _localDatabaseService.database;
        final merchantId = _currentMerchantId();
        final whereClauses = <String>[];
        final whereArgs = <dynamic>[];
        if (merchantId != null) {
          whereClauses.add('merchant_id = ?');
          whereArgs.add(merchantId);
        }
        if (nameQuery != null && nameQuery.isNotEmpty) {
          whereClauses.add('LOWER(name) LIKE ?');
          whereArgs.add('%${nameQuery.toLowerCase()}%');
        }
        final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
        final allRows = await db.query('suppliers', where: where, whereArgs: whereArgs, orderBy: 'created_at DESC, updated_at DESC, id DESC');
        final totalItems = allRows.length;
        final start = (page - 1) * pageSize;
        final end = (start + pageSize) > totalItems ? totalItems : (start + pageSize);
        final pageRows = start < totalItems ? allRows.sublist(start, end) : <Map<String,dynamic>>[];
        final suppliers = pageRows.map((r) => Supplier.fromJson({
          'id': r['id'],
          'merchantId': r['merchant_id'],
          'name': r['name'],
          'contactName': r['contact_name'],
          'contactEmail': r['contact_email'],
          'contactPhone': r['contact_phone'],
          'address': r['address'],
          'notes': r['notes'],
          'createdAt': r['created_at'],
          'updatedAt': r['updated_at'],
        })).toList();

        final totalPages = (totalItems / pageSize).ceil();
        return PaginatedSuppliersResponse(
          suppliers: suppliers,
          totalItems: totalItems,
          currentPage: page,
          pageSize: pageSize,
          totalPages: totalPages,
        );
      } catch (e) {
        _logger.warning('local listMerchantSuppliers failed: $e');
        return PaginatedSuppliersResponse(suppliers: [], totalItems: 0, currentPage: page, pageSize: pageSize, totalPages: 0);
      }
    }
    final token = await _getAuthToken();
    if (token == null) {
      _logger.warning('Auth token is null, cannot list suppliers.');
      return null;
    }
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (nameQuery != null && nameQuery.isNotEmpty) {
      queryParams['name'] = nameQuery; // For filtering by name if needed
    }

    final response = await _connect.get(
      _suppliersBaseUrl,
      headers: {'Authorization': 'Bearer $token'},
      query: queryParams,
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      if (response.body['data'] != null) {
        return PaginatedSuppliersResponse.fromJson(
          asMap(response.body['data']),
        );
      }
    }
    _logger.warning('Error listing suppliers: ${response.statusCode} - ${response.bodyString}');
    return null;
  }

  /// Fetches the details for a single supplier.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/suppliers/{supplierId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The full supplier object)
  Future<Supplier?> getSupplierDetails(String supplierId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Supplier(
        id: supplierId,
        merchantId: '1',
        name: 'Supplier $supplierId',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    // Local-only
    if (_appConfig.localStorageOnly) {
      try {
        final row = await _localDatabaseService.getSupplierById(supplierId);
        if (row == null) return null;
        return Supplier.fromJson({
          'id': row['id'],
          'merchantId': row['merchant_id'],
          'name': row['name'],
          'contactName': row['contact_name'],
          'contactEmail': row['contact_email'],
          'contactPhone': row['contact_phone'],
          'address': row['address'],
          'notes': row['notes'],
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
        });
      } catch (e) {
        _logger.warning('local getSupplierDetails failed: $e');
        return null;
      }
    }
    final token = await _getAuthToken();
    if (token == null) {
      _logger.warning('Auth token is null, cannot get supplier details.');
      return null;
    }
    final response = await _connect.get(
      '$_suppliersBaseUrl/$supplierId',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      if (response.body['data'] != null) {
        return Supplier.fromJson(asMap(response.body['data']));
      }
    }
    _logger.warning('Error getting supplier details for $supplierId: ${response.statusCode} - ${response.bodyString}');
    return null;
  }

  /// Finds suppliers by name.
  ///
  /// This is a convenience method that uses `listMerchantSuppliers`.
  Future<List<Supplier>> findSuppliersByName(String name) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return <Supplier>[];
    }
    PaginatedSuppliersResponse? paginatedResponse = await listMerchantSuppliers(
      nameQuery: name,
      pageSize: 20,
    );
    return paginatedResponse?.suppliers ?? <Supplier>[];
  }

  /// Creates a new supplier.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/suppliers`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "name": "New Supplier",
  ///     "contactName": "Jane Doe",
  ///     "contactEmail": "jane@newsupplier.com"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created supplier object)
  Future<Supplier?> createNewSupplier(Map<String, dynamic> supplierData) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Supplier.fromJson(
        supplierData
          ..['id'] = 'new-supplier-id'
          ..['merchantId'] = '1'
          ..['createdAt'] = DateTime.now().toIso8601String()
          ..['updatedAt'] = DateTime.now().toIso8601String(),
      );
    }
    final token = await _getAuthToken();
    if (_appConfig.localStorageOnly) {
      try {
        if (!supplierData.containsKey('name') || (supplierData['name'] as String).isEmpty) {
          _logger.warning('Supplier name is required to create a new supplier.');
          return null;
        }
        final id = supplierData['id'] ?? const Uuid().v4();
        final merchantId = supplierData['merchantId'] ?? _currentMerchantId();
        final payload = {
          'id': id,
          'merchant_id': merchantId,
          'name': supplierData['name'],
          'contact_name': supplierData['contactName'] ?? supplierData['contact_name'],
          'contact_email': supplierData['contactEmail'] ?? supplierData['contact_email'],
          'contact_phone': supplierData['contactPhone'] ?? supplierData['contact_phone'],
          'address': supplierData['address'],
          'notes': supplierData['notes'],
        };
        await _localDatabaseService.upsertSupplier(payload);
        final row = await _localDatabaseService.getSupplierById(id);
        if (row == null) return null;
        return Supplier.fromJson({
          'id': row['id'],
          'merchantId': row['merchant_id'],
          'name': row['name'],
          'contactName': row['contact_name'],
          'contactEmail': row['contact_email'],
          'contactPhone': row['contact_phone'],
          'address': row['address'],
          'notes': row['notes'],
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
        });
      } catch (e) {
        _logger.warning('local createNewSupplier failed: $e');
        return null;
      }
    }
    if (token == null) {
      _logger.warning('Auth token is null, cannot create supplier.');
      return null;
    }
    final response = await _connect.post(
      _suppliersBaseUrl,
      supplierData,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 201 && response.body['status'] == 'success') {
      if (response.body['data'] != null) {
        return Supplier.fromJson(asMap(response.body['data']));
      }
    }
    _logger.warning('Error creating new supplier: ${response.statusCode} - ${response.bodyString}');
    return null;
  }

  /// Updates an existing supplier.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/merchant/suppliers/{supplierId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (Fields to be updated)
  ///   ```json
  ///   {
  ///     "contactPhone": "4445556666"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The updated supplier object)
  Future<Supplier?> updateExistingSupplier(
    String supplierId,
    Map<String, dynamic> supplierData,
  ) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Supplier.fromJson(
        supplierData
          ..['id'] = supplierId
          ..['merchantId'] = '1'
          ..['createdAt'] = DateTime.now().toIso8601String()
          ..['updatedAt'] = DateTime.now().toIso8601String(),
      );
    }
    if (_appConfig.localStorageOnly) {
      try {
        if (supplierData.containsKey('name') && (supplierData['name'] as String).isEmpty) {
          _logger.warning('Supplier name cannot be empty if provided for update.');
          return null;
        }
        final payload = {
          'id': supplierId,
          'merchant_id': supplierData['merchantId'] ?? _currentMerchantId(),
          'name': supplierData['name'] ?? supplierData['name'],
          'contact_name': supplierData['contactName'] ?? supplierData['contact_name'],
          'contact_email': supplierData['contactEmail'] ?? supplierData['contact_email'],
          'contact_phone': supplierData['contactPhone'] ?? supplierData['contact_phone'],
          'address': supplierData['address'] ?? supplierData['address'],
          'notes': supplierData['notes'] ?? supplierData['notes'],
        };
        await _localDatabaseService.upsertSupplier(payload);
        final row = await _localDatabaseService.getSupplierById(supplierId);
        if (row == null) return null;
        return Supplier.fromJson({
          'id': row['id'],
          'merchantId': row['merchant_id'],
          'name': row['name'],
          'contactName': row['contact_name'],
          'contactEmail': row['contact_email'],
          'contactPhone': row['contact_phone'],
          'address': row['address'],
          'notes': row['notes'],
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
        });
      } catch (e) {
        _logger.warning('local updateExistingSupplier failed: $e');
        return null;
      }
    }
    final token = await _getAuthToken();
    if (token == null) {
      _logger.warning('Auth token is null, cannot update supplier.');
      return null;
    }
    final response = await _connect.put(
      '$_suppliersBaseUrl/$supplierId',
      supplierData,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      if (response.body['data'] != null) {
        return Supplier.fromJson(asMap(response.body['data']));
      }
    }
    _logger.warning('Error updating supplier $supplierId: ${response.statusCode} - ${response.bodyString}');
    return null;
  }

  /// Deletes a supplier.
  ///
  /// __Request:__
  /// - __Method:__ DELETE
  /// - __Endpoint:__ `/api/v1/merchant/suppliers/{supplierId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200 (or 204)
  Future<bool> deleteExistingSupplier(String supplierId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    if (_appConfig.localStorageOnly) {
      try {
        final db = await _localDatabaseService.database;
        await db.delete('suppliers', where: 'id = ?', whereArgs: [supplierId]);
        return true;
      } catch (e) {
        _logger.warning('local deleteExistingSupplier failed: $e');
        return false;
      }
    }
    final token = await _getAuthToken();
    if (token == null) {
      _logger.warning('Auth token is null, cannot delete supplier.');
      return false;
    }
    final response = await _connect.delete(
      '$_suppliersBaseUrl/$supplierId',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return true;
    }
    _logger.warning('Error deleting supplier $supplierId: ${response.statusCode} - ${response.bodyString}');
    return false;
  }

  /// Resolves a supplier name to a supplier ID.
  /// If the supplier exists, its ID is returned. If not, a new supplier is created and its ID is returned.
  Future<String?> _resolveSupplierNameToId(String? supplierName) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return 'mock-supplier-id';
    }
    if (supplierName == null || supplierName.trim().isEmpty) {
      return null;
    }
    try {
      List<Supplier> existingSuppliers = await findSuppliersByName(
        supplierName,
      );
      Supplier? matchedSupplier = existingSuppliers.firstWhereOrNull(
        (s) => s.name.toLowerCase() == supplierName.toLowerCase(),
      );

      if (matchedSupplier != null) {
        return matchedSupplier.id;
      } else {
        _logger.info("Supplier '$supplierName' not found, creating new one for product association.");
        Supplier? newSupplier = await createNewSupplier({'name': supplierName});
        return newSupplier?.id;
      }
    } catch (e) {
      _logger.warning("Error resolving supplier name to ID for '$supplierName': $e");
      return null;
    }
  }

  // --- Inventory Item Methods --- //

  /// Fetches a paginated list of inventory items.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/inventory`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `page`: `int`
  ///   - `pageSize`: `int`
  ///   - `name`: `string` (Optional name filter)
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
  ///           "merchantId": "uuid-merchant-1",
  ///           "name": "Laptop",
  ///           "description": "A powerful laptop",
  ///           "sku": "LP123",
  ///           "sellingPrice": 1200.00,
  ///           "originalPrice": 800.00,
  ///           "lowStockThreshold": 10,
  ///           "category": "Electronics",
  ///           "supplier": "Supplier A",
  ///           "isArchived": false,
  ///           "createdAt": "2023-01-10T10:00:00Z",
  ///           "updatedAt": "2023-10-26T10:00:00Z"
  ///         }
  ///       ],
  ///       "totalItems": 1,
  ///       "currentPage": 1,
  ///       "pageSize": 10,
  ///       "totalPages": 1
  ///     }
  ///   }
  ///   ```
  Future<PaginatedInventoryResponse?> listInventoryItems({
    int page = 1,
    int pageSize = 10,
    String? nameFilter,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final items = [
        InventoryItem(
          id: '1',
          merchantId: '1',
          name: 'Mock Item 1 (Laptop)',
          sellingPrice: 1200.0,
          originalPrice: 800.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          stockInfo: [
            StockInfo(shopId: 'shop-1', quantity: 10, shopName: 'Downtown'),
            StockInfo(shopId: 'shop-2', quantity: 5, shopName: 'Uptown'),
          ],
        ),
        InventoryItem(
          id: '2',
          merchantId: '1',
          name: 'Mock Item 2 (Mouse)',
          sellingPrice: 25.0,
          originalPrice: 10.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          stockInfo: [
            StockInfo(shopId: 'shop-1', quantity: 50, shopName: 'Downtown'),
          ],
        ),
      ];
      return PaginatedInventoryResponse(
        items: items,
        totalItems: 2,
        currentPage: 1,
        pageSize: 10,
        totalPages: 1,
      );
    }
    // If running in local-storage-only mode, build the response from the local DB.
    if (_appConfig.localStorageOnly) {
      try {
        final localDb = Get.find<LocalDatabaseService>();
        final db = await localDb.database;
        final merchantId = _currentMerchantId();
        final whereClauses = <String>[];
        final whereArgs = <dynamic>[];
        if (merchantId != null && merchantId.isNotEmpty) {
          whereClauses.add('i.merchant_id = ?');
          whereArgs.add(merchantId);
        }
        if (nameFilter != null && nameFilter.isNotEmpty) {
          whereClauses.add('LOWER(i.name) LIKE ?');
          whereArgs.add('%${nameFilter.toLowerCase()}%');
        }
        final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
        final allRowsRaw = await db.rawQuery(
          '''
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
          ''',
          whereArgs,
        );

        // Skip records that are placeholder-only (no metadata), which can occur
        // when stock adjustments created temporary entries without a valid item.
        final allRows = allRowsRaw.where((r) {
          final rowMerchantId = r['merchant_id']?.toString() ?? r['merchantId']?.toString();
          if (merchantId != null && merchantId.isNotEmpty && rowMerchantId != merchantId) {
            return false;
          }
          final hasMetadata = (r['name'] != null && (r['name'] as String).trim().isNotEmpty) ||
              (r['sku'] != null && (r['sku'] as String).trim().isNotEmpty) ||
              (r['merchant_id'] != null && (r['merchant_id'] as String).trim().isNotEmpty) ||
              (r['category'] != null && (r['category'] as String).trim().isNotEmpty);
          return hasMetadata;
        }).toList();

        final total = allRows.length;
        final start = (page - 1) * pageSize;
        final end = (start + pageSize) > total ? total : (start + pageSize);
        final pageRows = start < total ? allRows.sublist(start, end) : <Map<String,dynamic>>[];

        final items = <InventoryItem>[];
        for (final r in pageRows) {
          final id = r['id'] as String?;
          final stockRows = await db.query('shop_stock', where: 'inventory_item_id = ?', whereArgs: [id]);
          _logger.fine('Local inventory - item row: $r');
          _logger.finer('Local inventory - raw shop_stock rows: $stockRows');
          final stockInfo = <StockInfo>[];
          for (final s in stockRows) {
            try {
              final qtyRaw = s['quantity'];
              final int qty = qtyRaw is int
                  ? qtyRaw
                  : (qtyRaw is num ? qtyRaw.toInt() : int.tryParse(qtyRaw.toString()) ?? 0);
              final shopId = (s['shop_id'] ?? s['shopId'])?.toString() ?? '';
              final shopName = s['shop_name'] as String? ?? s['shopName'] as String?;
              stockInfo.add(StockInfo(quantity: qty, shopId: shopId, shopName: shopName));
            } catch (e, st) {
              _logger.warning('Failed to parse shop_stock row: $s - $e\n$st');
            }
          }

          InventoryItem? item;
          try {
            final merchantId = r['merchant_id'] as String? ?? r['merchantId'] as String? ?? '';
            final name = r['name'] as String? ?? r['name']?.toString() ?? '';
            final description = r['description'] as String? ?? r['description']?.toString();
            final sku = r['sku'] as String? ?? r['sku']?.toString();
            final sellingPrice = (r['selling_price'] as num?)?.toDouble() ?? (r['sellingPrice'] as num?)?.toDouble() ?? 0.0;
            final originalPrice = (r['original_price'] as num?)?.toDouble() ?? (r['originalPrice'] as num?)?.toDouble();
            final lowStockThreshold = (r['low_stock_threshold'] as int?) ?? (r['lowStockThreshold'] as int?);

            DateTime createdAt;
            DateTime updatedAt;
            try {
              final createdAtRaw = (r['created_at'] as String?) ?? (r['createdAt'] as String?);
              createdAt = createdAtRaw != null ? DateTime.parse(createdAtRaw) : DateTime.now();
            } catch (_) {
              createdAt = DateTime.now();
            }
            try {
              final updatedAtRaw = (r['updated_at'] as String?) ?? (r['updatedAt'] as String?);
              updatedAt = updatedAtRaw != null ? DateTime.parse(updatedAtRaw) : DateTime.now();
            } catch (_) {
              updatedAt = DateTime.now();
            }

            item = InventoryItem(
              id: r['id'] as String?,
              merchantId: merchantId,
              name: name,
              description: description,
              sku: sku,
              sellingPrice: sellingPrice,
              originalPrice: originalPrice ?? 0.0,
              lowStockThreshold: lowStockThreshold,
              category: r['category'] as String? ?? r['category']?.toString(),
              categoryId: r['category_id'] as String? ?? r['categoryId'] as String?,
              subcategoryId: r['subcategory_id'] as String? ?? r['subcategoryId'] as String?,
              brandId: r['brand_id'] as String? ?? r['brandId'] as String?,
              supplier: r['supplier_id'] as String? ?? r['supplier'] as String?,
              createdAt: createdAt,
              updatedAt: updatedAt,
              categoryObj: (r['category_obj_id'] != null)
                  ? CategoryRef(
                      id: r['category_obj_id']?.toString() ?? '',
                      name: r['category_obj_name']?.toString() ?? '',
                      description: r['category_obj_description']?.toString(),
                    )
                  : null,
              subcategoryObj: (r['subcategory_obj_id'] != null)
                  ? SubcategoryRef(
                      id: r['subcategory_obj_id']?.toString() ?? '',
                      categoryId: r['subcategory_obj_category_id']?.toString() ?? '',
                      name: r['subcategory_obj_name']?.toString() ?? '',
                      description: r['subcategory_obj_description']?.toString(),
                    )
                  : null,
              brandObj: (r['brand_obj_id'] != null)
                  ? BrandRef(
                      id: r['brand_obj_id']?.toString() ?? '',
                      name: r['brand_obj_name']?.toString() ?? '',
                      description: r['brand_obj_description']?.toString(),
                      imageUrl: r['brand_obj_image_url']?.toString(),
                    )
                  : null,
              stockInfo: stockInfo,
            );
          } catch (e, st) {
            _logger.warning('Failed to construct InventoryItem from row: $r - $e\n$st');
            continue;
          }
          items.add(item);
        }

        return PaginatedInventoryResponse(
          items: items,
          totalItems: total,
          currentPage: page,
          pageSize: pageSize,
          totalPages: (total / pageSize).ceil(),
        );
      } catch (e) {
        _logger.warning('Local inventory fetch failed: $e');
        return PaginatedInventoryResponse(items: [], totalItems: 0, currentPage: page, pageSize: pageSize, totalPages: 0);
      }
    }

    final token = await _getAuthToken();
    if (token == null) {
      _logger.warning('Auth token is null, cannot fetch inventory items.');
      return null;
    }
    final queryParameters = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (nameFilter != null && nameFilter.isNotEmpty) {
      queryParameters['name'] = nameFilter;
    }
    final response = await _connect.get(
      _inventoryBaseUrl,
      headers: {'Authorization': 'Bearer $token'},
      query: queryParameters,
    );
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      // Backend returns a list directly in 'data', not a paginated object
      final data = response.body['data'];
      final rawList = asList(data);
      if (rawList.isNotEmpty) {
        final items = rawList
            .map((i) => InventoryItem.fromJson(Map<String, dynamic>.from(i)))
            .toList();
        return PaginatedInventoryResponse(
          items: items,
          totalItems: items.length,
          currentPage: page,
          pageSize: pageSize,
          totalPages: 1,
        );
      } else if (data is Map<String, dynamic>) {
        // If it's a paginated response object
        return PaginatedInventoryResponse.fromJson(asMap(data));
      }
    }

    _logger.warning('Error fetching inventory: ${response.statusCode} - ${response.bodyString}');
    return null;
  }

  /// Creates a new inventory item.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/inventory`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (The `InventoryItem` object serialized for creation)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (Returns the newly created inventory item object)
  Future<InventoryItem?> createInventoryItem(InventoryItem item) async {
    final clientOperationId = item.id ?? const Uuid().v4();

    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return item.copyWith(id: 'new-item-id');
    }
    Map<String, dynamic> payload = item.toJsonForCreate();

    // Ensure clientOperationId is included for idempotency / offline queueing
    payload['clientOperationId'] = clientOperationId;

    try {
      // Local-only mode: persist the inventory item locally and mark it for sync
      if (_appConfig.localStorageOnly) {
        final now = DateTime.now();
        final localId = item.id ?? clientOperationId;
        final merchantId = item.merchantId.isNotEmpty ? item.merchantId : (_currentScopeMerchantId() ?? item.merchantId);
        final toSave = item.copyWith(
          id: localId,
          merchantId: merchantId,
          isSynced: false,
          needsCreate: true,
          createdAt: item.createdAt,
          updatedAt: now,
        );
        await _localDatabaseService.insertInventoryItem(toSave.toDbMap());
        return toSave;
      }

      final token = await _getAuthToken();
      if (token == null) return null;

    if (item.categoryId != null && item.categoryId!.isNotEmpty) {
      payload['categoryId'] = item.categoryId;
    }
    if (item.subcategoryId != null && item.subcategoryId!.isNotEmpty) {
      payload['subcategoryId'] = item.subcategoryId;
    }
    if (item.brandId != null && item.brandId!.isNotEmpty) {
      payload['brandId'] = item.brandId;
    }

    if (item.supplier != null && item.supplier!.isNotEmpty) {
      String? supplierId = await _resolveSupplierNameToId(item.supplier!);
      if (supplierId != null) {
        payload['supplierId'] = supplierId;
      }
      payload.remove('supplier');
    } else {
      payload.remove('supplier');
    }

    _logger.fine('Creating inventory item with payload: ${jsonEncode(payload)}');

    final response = await _connect.post(
      _inventoryBaseUrl,
      payload,
      headers: {
        'Authorization': 'Bearer $token',
        'X-Client-Operation-Id': clientOperationId,
      },
    );

    if (response.statusCode! < 300) {
      return InventoryItem.fromJson(asMap(response.body['data']));
    } else {
      _logger.warning('Error creating inventory item: ${response.statusCode} - ${response.bodyString}');
      return null;
    }
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          entityType: 'inventory_item',
          action: 'create',
          endpoint: _inventoryBaseUrl,
          payload: payload,
        );
        return item.copyWith(id: clientOperationId, merchantId: item.merchantId);
      }
      rethrow;
    }
  }

  /// Fetches a single inventory item by its ID.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/inventory/{itemId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (The full inventory item object)
  Future<InventoryItem?> getInventoryItemById(String itemId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return InventoryItem(
        id: itemId,
        merchantId: '1',
        name: 'Item $itemId',
        sellingPrice: 10.0,
        originalPrice: 7.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final response = await _connect.get(
      '$_inventoryBaseUrl/$itemId',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return InventoryItem.fromJson(asMap(response.body['data']));
    } else {
      _logger.warning('Error fetching item $itemId: ${response.statusCode} - ${response.bodyString}');
      return null;
    }
  }

  /// Updates an existing inventory item.
  ///
  /// __Request:__
  /// - __Method:__ PUT
  /// - __Endpoint:__ `/api/v1/merchant/inventory/{itemId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (Map of fields to be updated)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (Returns the updated inventory item object)
  Future<InventoryItem?> updateInventoryItem(
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      // Use a more realistic mock update
      final updatedItem = InventoryItem(
        id: itemId,
        merchantId: '1',
        name: updates['name'] ?? 'Updated Name',
        sellingPrice: updates['sellingPrice'] ?? 10.0,
        originalPrice: updates['originalPrice'] ?? 7.0,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      );
      return updatedItem;
    }
    final token = await _getAuthToken();
    if (token == null) return null;

    Map<String, dynamic> payload = Map<String, dynamic>.from(updates);

    if (payload['categoryId'] == '') payload.remove('categoryId');
    if (payload['subcategoryId'] == '') payload.remove('subcategoryId');
    if (payload['brandId'] == '') payload.remove('brandId');

    if (payload.containsKey('supplier') && payload['supplier'] is String) {
      String supplierName = payload['supplier'] as String;
      if (supplierName.isNotEmpty) {
        String? supplierId = await _resolveSupplierNameToId(supplierName);
        if (supplierId != null) {
          payload['supplierId'] = supplierId;
        }
      }
      payload.remove('supplier');
    } else {
      payload.remove('supplier');
    }

    _logger.fine('Updating inventory item $itemId with payload: ${jsonEncode(payload)}');

    final response = await _connect.put(
      '$_inventoryBaseUrl/$itemId',
      payload,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return InventoryItem.fromJson(asMap(response.body['data']));
    } else {
      _logger.warning('Error updating item $itemId: ${response.statusCode} - ${response.bodyString}');
      return null;
    }
  }

  /// Archives an inventory item.
  ///
  /// __Request:__
  /// - __Method:__ PATCH
  /// - __Endpoint:__ `/api/v1/merchant/inventory/{itemId}/archive`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (Returns the updated, archived inventory item object)
  Future<InventoryItem?> archiveInventoryItem(String itemId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return InventoryItem(
        id: itemId,
        merchantId: '1',
        name: 'Item $itemId',
        sellingPrice: 10.0,
        originalPrice: 7.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: true,
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final response = await _connect.patch(
      '$_inventoryBaseUrl/$itemId/archive',
      {},
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return InventoryItem.fromJson(asMap(response.body['data']));
    } else {
      _logger.warning('Error archiving item $itemId: ${response.statusCode} - ${response.bodyString}');
      return null;
    }
  }

  /// Unarchives an inventory item.
  ///
  /// __Request:__
  /// - __Method:__ PATCH
  /// - __Endpoint:__ `/api/v1/merchant/inventory/{itemId}/unarchive`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (Returns the updated, unarchived inventory item object)
  Future<InventoryItem?> unarchiveInventoryItem(String itemId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return InventoryItem(
        id: itemId,
        merchantId: '1',
        name: 'Item $itemId',
        sellingPrice: 10.0,
        originalPrice: 7.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: false,
      );
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final response = await _connect.patch(
      '$_inventoryBaseUrl/$itemId/unarchive',
      {},
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return InventoryItem.fromJson(asMap(response.body['data']));
    } else {
      _logger.warning('Error unarchiving item $itemId: ${response.statusCode} - ${response.bodyString}');
      return null;
    }
  }

  /// Deletes an inventory item.
  ///
  /// __Request:__
  /// - __Method:__ DELETE
  /// - __Endpoint:__ `/api/v1/merchant/inventory/{itemId}`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200 (or 204)
  Future<bool> deleteInventoryItem(String itemId) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    final token = await _getAuthToken();
    if (token == null) return false;
    final response = await _connect.delete(
      '$_inventoryBaseUrl/$itemId',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      // Backend uses 200 for successful delete
      return true;
    } else {
      _logger.warning('Error deleting item $itemId: ${response.statusCode} - ${response.bodyString}');
      return false;
    }
  }

  /// Preflight check whether an inventory item can be safely deleted.
  /// Returns { 'deletable': bool, 'blockers': { 'shop_stock': 2, ... } }
  Future<Map<String, dynamic>?> checkInventoryItemDeletable(
    String itemId,
  ) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 200));
      return {'deletable': true, 'blockers': {}};
    }
    final token = await _getAuthToken();
    if (token == null) return null;
    final response = await _connect.get(
      '$_inventoryBaseUrl/$itemId/delete-check',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return Map<String, dynamic>.from(asMap(response.body['data']));
    } else {
      _logger.warning('Error checking item deletable: ${response.statusCode} - ${response.bodyString}');
      return null;
    }
  }

  /// ADDED: New method for moving stock between shops.
  /// Moves a specified quantity of an item from one shop to another.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/inventory/move-stock`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "itemId": "uuid-item-1",
  ///     "fromShopId": "uuid-shop-A",
  ///     "toShopId": "uuid-shop-B",
  ///     "quantity": 10
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "status": "success",
  ///     "message": "Stock moved successfully."
  ///   }
  ///   ```
  Future<bool> moveStock({
    required String itemId,
    required String fromShopId,
    required String toShopId,
    required int quantity,
    String? clientOperationId,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 2));
      _logger.fine('Mock: Moved $quantity of item $itemId from shop $fromShopId to $toShopId');
      return true;
    }

    final token = await _getAuthToken();
    if (token == null) return false;

    clientOperationId ??= const Uuid().v4();

    final payload = {
      'clientOperationId': clientOperationId,
      'itemId': itemId,
      'fromShopId': fromShopId,
      'toShopId': toShopId,
      'quantity': quantity,
    };

    final response = await _connect.post(
      '$_inventoryBaseUrl/move-stock',
      payload,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return true;
    } else {
      _logger.warning('Error moving stock: ${response.statusCode} - ${response.bodyString}');
      return false;
    }
  }
}
