import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/supplier_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:uuid/uuid.dart';

class SupplierApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/merchant/suppliers';

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
      'entity_type': 'supplier',
      'action': action,
      'method': action == 'delete' ? 'DELETE' : (action == 'update' ? 'PUT' : 'POST'),
      'endpoint': endpoint,
      'payload': payload,
      'headers': {'X-Client-Operation-Id': clientOperationId},
    });
  }

  /// Fetches a list of suppliers.
  ///
  /// __Request:__
  /// - __Method:__ GET
  /// - __Endpoint:__ `/api/v1/merchant/suppliers`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__ (A list of supplier objects)
  Future<List<Supplier>> getSuppliers() async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return [
        Supplier(
          id: '1',
          merchantId: '1',
          name: 'Supplier A',
          contactName: 'John A',
          contactEmail: 'john.a@supplier.com',
        ),
        Supplier(
          id: '2',
          merchantId: '1',
          name: 'Supplier B',
          contactName: 'John B',
          contactEmail: 'john.b@supplier.com',
        ),
      ];
    }

    final response = await _connect.get(_baseUrl, headers: await _getHeaders());

    if (response.isOk && response.body['data'] != null) {
      final rawList = asList(response.body['data']);
      return rawList
          .map((json) => Supplier.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } else {
      throw Exception(response.body?['message'] ?? 'Failed to load suppliers');
    }
  }

  /// Creates a new supplier.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/suppliers`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__ (Supplier data)
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 201
  /// - __Body (JSON):__ (The newly created supplier object)
  Future<Supplier> createSupplier(Map<String, dynamic> data) async {
    final clientOperationId = data['clientOperationId']?.toString() ?? const Uuid().v4();
    final payload = Map<String, dynamic>.from(data)..['clientOperationId'] = clientOperationId;
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return Supplier.fromJson(
        data
          ..['id'] = 'new-supplier-id'
          ..['merchantId'] = '1',
      );
    }

    try {
      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.post(_baseUrl, payload, headers: headers);

      if (response.statusCode == 201 && response.body['data'] != null) {
        return Supplier.fromJson(asMap(response.body['data']));
      }
      throw Exception(response.body?['message'] ?? 'Failed to create supplier');
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'create',
          endpoint: _baseUrl,
          payload: payload,
        );
        return Supplier.fromJson({
          ...payload,
          'id': clientOperationId,
          'merchantId': 'pending',
        });
      }
      throw Exception(e.toString());
    }
  }

  /// Deletes a supplier by ID.
  ///
  /// __Request:__ DELETE `/api/v1/merchant/suppliers/{supplierId}`
  /// Returns true on success.
  Future<bool> deleteSupplier(String supplierId) async {
    final clientOperationId = const Uuid().v4();
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    try {
      final headers = await _getHeaders();
      headers['X-Client-Operation-Id'] = clientOperationId;
      final response = await _connect.delete(
        '$_baseUrl/$supplierId',
        headers: headers,
      );
      if ((response.statusCode == 200 || response.statusCode == 204) &&
          (response.body == null || response.body['status'] == 'success')) {
        return true;
      }
      print(
        'Error deleting supplier $supplierId: ${response.statusCode} - ${response.bodyString}',
      );
      return false;
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueMutation(
          clientOperationId: clientOperationId,
          action: 'delete',
          endpoint: '$_baseUrl/$supplierId',
          payload: {'supplierId': supplierId},
        );
        return true;
      }
      rethrow;
    }
  }
}
