import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';

class InvoiceApiService extends GetxService {
  final GetConnect _connect = GetConnect(timeout: const Duration(seconds: 30));
  final AuthService _authService = Get.find<AuthService>();

  Future<String?> _getAuthToken() async {
    return await _authService.getToken();
  }

  final String _invoicesBaseUrl = "${ApiConstants.baseUrl}/merchant/invoices";

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
    final token = await _getAuthToken();
    if (token == null) {
      print('[InvoiceApiService] Auth token is null when listing invoices');
      return null;
    }

    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (shopId != null && shopId.isNotEmpty) 'shopId': shopId,
    };

    try {
      final response = await _connect.get(
        _invoicesBaseUrl,
        headers: {'Authorization': 'Bearer $token'},
        query: queryParams,
      );

      print('[InvoiceApiService] listInvoices response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.body != null) {
        final bodyMap = response.body as Map<String, dynamic>;
        if (bodyMap['status'] == 'success' && bodyMap['data'] != null) {
          return PaginatedInvoicesResponse.fromJson(bodyMap['data']);
        }
      }

      print('[InvoiceApiService] Unexpected response format or status');
      return null;
    } catch (e, stackTrace) {
      print('[InvoiceApiService] Error listing invoices: $e');
      print(stackTrace);
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
    final token = await _getAuthToken();
    if (token == null) {
      print('[InvoiceApiService] Auth token is null when fetching invoice by ID');
      return null;
    }

    try {
      final response = await _connect.get(
        '$_invoicesBaseUrl/$invoiceId',
        headers: {'Authorization': 'Bearer $token'},
      );

      print('[InvoiceApiService] getInvoiceById response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.body != null) {
        final bodyMap = response.body as Map<String, dynamic>;
        if (bodyMap['status'] == 'success' && bodyMap['data'] != null) {
          return Invoice.fromJson(bodyMap['data']);
        }
      }

      print('[InvoiceApiService] Invoice not found or unexpected response');
      return null;
    } catch (e, stackTrace) {
      print('[InvoiceApiService] Error fetching invoice by ID: $e');
      print(stackTrace);
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
    final token = await _getAuthToken();
    if (token == null) {
      print('[InvoiceApiService] Auth token is null when fetching invoice by sale ID');
      return null;
    }

    try {
      final response = await _connect.get(
        '$_invoicesBaseUrl/sale/$saleId',
        headers: {'Authorization': 'Bearer $token'},
      );

      print('[InvoiceApiService] getInvoiceBySaleId response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.body != null) {
        final bodyMap = response.body as Map<String, dynamic>;
        if (bodyMap['status'] == 'success' && bodyMap['data'] != null) {
          return Invoice.fromJson(bodyMap['data']);
        }
      }

      print('[InvoiceApiService] Invoice not found or unexpected response');
      return null;
    } catch (e, stackTrace) {
      print('[InvoiceApiService] Error fetching invoice by sale ID: $e');
      print(stackTrace);
      return null;
    }
  }
}
