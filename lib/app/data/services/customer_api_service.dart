import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/customer_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:uuid/uuid.dart';

class CustomerApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/merchant/customers';

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

  Future<void> _queueMutation({
    required String clientOperationId,
    required String action,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    await _localDatabaseService.queueOperation({
      'id': clientOperationId,
      'client_operation_id': clientOperationId,
      'entity_type': 'customer',
      'action': action,
      'method': 'POST',
      'endpoint': endpoint,
      'payload': payload,
      'headers': {'X-Client-Operation-Id': clientOperationId},
    });
  }

  /// Searches for customers by name, email, or phone number.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/customers/search`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Query Parameters:__
  ///   - `query`: `string` (The search term)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "success": true,
  ///     "data": [
  ///       {
  ///         "id": "uuid-customer-1",
  ///         "shopId": "uuid-shop-1",
  ///         "name": "John Doe",
  ///         "phone": "1234567890",
  ///         "email": "john.doe@example.com",
  ///         "createdAt": "2023-01-15T10:00:00Z"
  ///       }
  ///     ]
  ///   }
  ///   ```
  ///
  /// __Dummy Response Data (for testing):__
  /// ```dart
  /// final dummyCustomers = [
  ///   Customer(
  ///     id: 'uuid-customer-1',
  ///     shopId: 'uuid-shop-1',
  ///     name: 'John Doe',
  ///     phone: '1234567890',
  ///     email: 'john.doe@example.com',
  ///     createdAt: DateTime.parse("2023-01-15T10:00:00Z"),
  ///   )
  /// ];
  /// ```
  Future<List<Customer>> searchCustomers(
    String query, {
    required String shopId,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      if (query.isEmpty) return [];
      return [
        Customer(
          id: 'uuid-customer-1',
          shopId: shopId, // CORRECTED
          name: 'John Doe',
          phone: '1234567890',
          email: 'john.doe@example.com',
          createdAt: DateTime.parse("2023-01-15T10:00:00Z"),
        ),
      ];
    }
    final response = await _connect.get(
      '$_baseUrl/search',
      headers: await _getHeaders(),
      query: {
        'query': query,
        'shopId': shopId,
      }, // CORRECTED: Added shopId to query
    );

    if (response.statusCode == 200 && response.body['success'] == true) {
      final List<dynamic> data = asList(response.body['data']);
      return data
          .map((json) => Customer.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } else {
      throw Exception(
        response.body?['message'] ?? 'Failed to search customers',
      );
    }
  }

  /// Creates a new customer for the merchant.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/customers`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///   - `Content-Type: application/json`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "shopId": "uuid-shop-1",
  ///     "name": "Jane Doe",
  ///     "phone": "0987654321",
  ///     "email": "jane.doe@example.com"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "success": true,
  ///     "data": {
  ///       "id": "uuid-customer-2",
  ///       "shopId": "uuid-shop-1",
  ///       "name": "Jane Doe",
  ///       "phone": "0987654321",
  ///       "email": "jane.doe@example.com",
  ///       "createdAt": "2023-10-28T10:00:00Z"
  ///     }
  ///   }
  ///   ```
  ///
  /// __Dummy Response Data (for testing):__
  /// ```dart
  /// final newCustomer = Customer(
  ///   id: 'uuid-customer-2',
  ///   shopId: 'uuid-shop-1',
  ///   name: 'Jane Doe',
  ///   phone: '0987654321',
  ///   email: 'jane.doe@example.com',
  ///   createdAt: DateTime.parse("2023-10-28T10:00:00Z"),
  /// );
  /// ```
  Future<Customer> createCustomer({
    required String shopId,
    required String name,
    String? phone,
    String? email,
  }) async {
    final clientOperationId = const Uuid().v4();
    final payload = {
      'shopId': shopId,
      'name': name,
      'phone': phone,
      'email': email,
      'clientOperationId': clientOperationId,
    };
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Customer(
        id: 'uuid-customer-2',
        shopId: shopId,
        name: name,
        phone: phone,
        email: email,
        createdAt: DateTime.now(),
      );
    }
    try {
      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.post(_baseUrl, payload, headers: headers);

      if (response.statusCode == 201 && response.body['success'] == true) {
        return Customer.fromJson(asMap(response.body['data']));
      }
      throw Exception(response.body?['message'] ?? 'Failed to create customer');
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'create',
          endpoint: _baseUrl,
          payload: payload,
        );
        return Customer(
          id: clientOperationId,
          shopId: shopId,
          name: name,
          phone: phone,
          email: email,
          createdAt: DateTime.now(),
        );
      }
      throw Exception(e.toString());
    }
  }
}
