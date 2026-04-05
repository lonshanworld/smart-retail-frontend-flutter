import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/shop_customer_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:uuid/uuid.dart';

// CORRECTED: The class name is plural to match what the controller and binding expect.
class ShopCustomersApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/shop/customers';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  bool _shouldQueue(dynamic error) {
    final text = error.toString().toLowerCase();
    return _appConfig.localStorageOnly ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection') ||
        text.contains('timeout');
  }

  Future<void> _queueOperation({
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

  /// Fetches a list of customers for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/shop/customers/search?shopId={shopId}&query=` (query is optional)
  /// - If query is empty, returns all customers for the shop
  /// - If query is provided, searches by name, email, or phone
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ A list of `ShopCustomer` objects.
  // CORRECTED: Method name is now getCustomers to match the controller.
  Future<List<ShopCustomer>> getCustomers(String shopId) async {
    developer.log(
      '🔍 [ShopCustomersApiService] Fetching customers for shopId: $shopId',
      name: 'API',
    );

    if (_appConfig.isDevelopment) {
      developer.log(
        '📱 [ShopCustomersApiService] Using mock data (development mode)',
        name: 'API',
      );
      await Future.delayed(const Duration(seconds: 1));
      return List.generate(
        8,
        (i) => ShopCustomer(
          id: 'cust-$i',
          shopId: shopId,
          name: 'Shop $shopId Customer ${i + 1}',
          email: 'customer${i + 1}@example.com',
          phone: '123-456-789$i',
          merchantId: 'merch-1',
          createdAt: DateTime.now().subtract(Duration(days: i * 5)),
          updatedAt: DateTime.now(),
        ),
      );
    }

    try {
      if (_appConfig.localStorageOnly) {
        final rows = await _localDatabaseService.listCustomersForShop(shopId);
        return rows.map((r) => ShopCustomer.fromJson(r)).toList();
      }
      // Using search endpoint with empty query to get all customers for a shop
      final url = '$_baseUrl/search?shopId=$shopId&query=';
      developer.log(
        '🌐 [ShopCustomersApiService] GET Request URL: $url',
        name: 'API',
      );

      final response = await _connect.get(url, headers: await _getHeaders());

      developer.log(
        '📡 [ShopCustomersApiService] Response Status: ${response.statusCode}',
        name: 'API',
      );
      developer.log(
        '📦 [ShopCustomersApiService] Response Body: ${response.body}',
        name: 'API',
      );

      if (response.isOk && response.body != null) {
        final data = asList(response.body['data']);
        developer.log(
          '✅ [ShopCustomersApiService] Data received: ${data.length} customers',
          name: 'API',
        );
        return data.map((json) {
          developer.log(
            '🔄 [ShopCustomersApiService] Parsing customer: $json',
            name: 'API',
          );
          return ShopCustomer.fromJson(Map<String, dynamic>.from(json));
        }).toList();
      } else {
        final errorMsg =
            response.body?['message'] ?? 'Failed to load customers';
        developer.log(
          '❌ [ShopCustomersApiService] Request failed: $errorMsg',
          name: 'API',
        );
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      developer.log(
        '💥 [ShopCustomersApiService] Exception caught: $e',
        name: 'API',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Creates a new customer record for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/shop/customers`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "shopId": "shop-uuid",
  ///     "name": "New Customer",
  ///     "email": "new.customer@example.com",
  ///     "phone": "555-123-4567"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ The newly created `ShopCustomer` object.
  // CORRECTED: Added the createCustomer method that was missing.
  Future<ShopCustomer> createCustomer(
    String shopId,
    Map<String, dynamic> customerData,
  ) async {
    developer.log(
      '➕ [ShopCustomersApiService] Creating customer for shopId: $shopId',
      name: 'API',
    );
    developer.log(
      '📝 [ShopCustomersApiService] Customer data: $customerData',
      name: 'API',
    );

    if (_appConfig.isDevelopment) {
      developer.log(
        '📱 [ShopCustomersApiService] Using mock data (development mode)',
        name: 'API',
      );
      await Future.delayed(const Duration(seconds: 1));
      final newCustomer = ShopCustomer.fromJson({
        ...customerData,
        'id': 'cust-new-${DateTime.now().millisecondsSinceEpoch}',
        'shopId': shopId,
        'merchantId': 'merch-1',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return newCustomer;
    }

    final clientOperationId = customerData['clientOperationId']?.toString() ??
        const Uuid().v4();

    try {
      if (_appConfig.localStorageOnly) {
        final requestBody = {
          ...customerData,
          'shop_id': shopId,
          'shopId': shopId,
          'clientOperationId': clientOperationId,
        };
        await _localDatabaseService.createCustomerLocal(requestBody);
        return ShopCustomer.fromJson({
          ...requestBody,
          'id': clientOperationId,
          'merchantId': 'local',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      // Add shopId to the request body
      final requestBody = {
        ...customerData,
        'shopId': shopId,
        'clientOperationId': clientOperationId,
      };

      developer.log(
        '🌐 [ShopCustomersApiService] POST Request URL: $_baseUrl/',
        name: 'API',
      );
      developer.log(
        '📦 [ShopCustomersApiService] Request Body: $requestBody',
        name: 'API',
      );

      final response = await _connect.post(
        _baseUrl,
        requestBody,
        headers: {
          ...await _getHeaders(),
          'X-Client-Operation-Id': clientOperationId,
        },
      );

      developer.log(
        '📡 [ShopCustomersApiService] Response Status: ${response.statusCode}',
        name: 'API',
      );
      developer.log(
        '📦 [ShopCustomersApiService] Response Body: ${response.body}',
        name: 'API',
      );

      if (response.statusCode == 201 && response.body['data'] != null) {
        developer.log(
          '✅ [ShopCustomersApiService] Customer created successfully',
          name: 'API',
        );
        return ShopCustomer.fromJson(asMap(response.body['data']));
      } else {
        final errorMsg =
            response.body?['message'] ?? 'Failed to create customer';
        developer.log(
          '❌ [ShopCustomersApiService] Request failed: $errorMsg',
          name: 'API',
        );
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      developer.log(
        '💥 [ShopCustomersApiService] Exception caught: $e',
        name: 'API',
        error: e,
        stackTrace: stackTrace,
      );
      if (_shouldQueue(e)) {
        final requestBody = {
          ...customerData,
          'shopId': shopId,
          'clientOperationId': clientOperationId,
        };
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'shop_customer',
          action: 'create',
          endpoint: _baseUrl,
          payload: requestBody,
        );
        return ShopCustomer.fromJson({
          ...requestBody,
          'id': clientOperationId,
          'merchantId': 'pending-merchant',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      rethrow;
    }
  }
}
