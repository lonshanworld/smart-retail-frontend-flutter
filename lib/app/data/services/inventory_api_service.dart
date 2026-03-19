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

class InventoryApiService extends GetxService {
  final GetConnect _connect = GetConnect(timeout: const Duration(seconds: 30));
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

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

    final token = await _getAuthToken();
    if (token == null) return null;

    final response = await _connect.get(
      '$_catalogBaseUrl/options',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return CatalogOptionsResponse.fromJson(asMap(response.body['data']));
    }

    print(
      'Error loading catalog options: ${response.statusCode} - ${response.bodyString}',
    );
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

    try {
      final response = await _connect.post(
        '$_catalogBaseUrl/brands',
        payload,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Client-Operation-Id': clientOperationId,
        },
      );

      if (response.statusCode == 201 && response.body['status'] == 'success') {
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

    final msg = (response.body is Map && response.body['message'] != null)
        ? response.body['message'].toString()
        : (response.bodyString ?? 'Failed to create brand');
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
    final token = await _getAuthToken();
    if (token == null) {
      print("Auth token is null, cannot list suppliers.");
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
    print(
      'Error listing suppliers: ${response.statusCode} - ${response.bodyString}',
    );
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
    final token = await _getAuthToken();
    if (token == null) {
      print("Auth token is null, cannot get supplier details.");
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
    print(
      'Error getting supplier details for $supplierId: ${response.statusCode} - ${response.bodyString}',
    );
    return null;
  }

  /// Finds suppliers by name.
  ///
  /// This is a convenience method that uses `listMerchantSuppliers`.
  Future<List<Supplier>> findSuppliersByName(String name) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return [];
    }
    PaginatedSuppliersResponse? paginatedResponse = await listMerchantSuppliers(
      nameQuery: name,
      pageSize: 20,
    );
    return paginatedResponse?.suppliers ?? [];
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
    if (token == null) {
      print("Auth token is null, cannot create supplier.");
      return null;
    }
    if (!supplierData.containsKey('name') ||
        (supplierData['name'] as String).isEmpty) {
      print("Supplier name is required to create a new supplier.");
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
    print(
      'Error creating new supplier: ${response.statusCode} - ${response.bodyString}',
    );
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
    final token = await _getAuthToken();
    if (token == null) {
      print("Auth token is null, cannot update supplier.");
      return null;
    }
    if (supplierData.containsKey('name') &&
        (supplierData['name'] as String).isEmpty) {
      print("Supplier name cannot be empty if provided for update.");
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
    print(
      'Error updating supplier $supplierId: ${response.statusCode} - ${response.bodyString}',
    );
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
    final token = await _getAuthToken();
    if (token == null) {
      print("Auth token is null, cannot delete supplier.");
      return false;
    }
    final response = await _connect.delete(
      '$_suppliersBaseUrl/$supplierId',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return true;
    }
    print(
      'Error deleting supplier $supplierId: ${response.statusCode} - ${response.bodyString}',
    );
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
        print(
          "Supplier '$supplierName' not found, creating new one for product association.",
        );
        Supplier? newSupplier = await createNewSupplier({'name': supplierName});
        return newSupplier?.id;
      }
    } catch (e) {
      print("Error resolving supplier name to ID for '$supplierName': $e");
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
    final token = await _getAuthToken();
    if (token == null) {
      print("Auth token is null, cannot fetch inventory items.");
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

    print(
      'Error fetching inventory: ${response.statusCode} - ${response.bodyString}',
    );
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
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return item.copyWith(id: 'new-item-id');
    }
    final token = await _getAuthToken();
    if (token == null) return null;

    Map<String, dynamic> payload = item.toJsonForCreate();

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

    print("Creating inventory item with payload: ${jsonEncode(payload)}");

    final response = await _connect.post(
      _inventoryBaseUrl,
      payload,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode! < 300) {
      return InventoryItem.fromJson(asMap(response.body['data']));
    } else {
      print(
        'Error creating inventory item: ${response.statusCode} - ${response.bodyString}',
      );
      return null;
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
      print(
        'Error fetching item $itemId: ${response.statusCode} - ${response.bodyString}',
      );
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

    print(
      "Updating inventory item $itemId with payload: ${jsonEncode(payload)}",
    );

    final response = await _connect.put(
      '$_inventoryBaseUrl/$itemId',
      payload,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && response.body['status'] == 'success') {
      return InventoryItem.fromJson(asMap(response.body['data']));
    } else {
      print(
        'Error updating item $itemId: ${response.statusCode} - ${response.bodyString}',
      );
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
      print(
        'Error archiving item $itemId: ${response.statusCode} - ${response.bodyString}',
      );
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
      print(
        'Error unarchiving item $itemId: ${response.statusCode} - ${response.bodyString}',
      );
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
      print(
        'Error deleting item $itemId: ${response.statusCode} - ${response.bodyString}',
      );
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
      print(
        'Error checking item deletable: ${response.statusCode} - ${response.bodyString}',
      );
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
      print(
        'Mock: Moved $quantity of item $itemId from shop $fromShopId to $toShopId',
      );
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
      print(
        'Error moving stock: ${response.statusCode} - ${response.bodyString}',
      );
      return false;
    }
  }
}
