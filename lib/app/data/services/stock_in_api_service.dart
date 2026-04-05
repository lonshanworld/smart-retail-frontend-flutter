import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

// Represents a single item in a stock-in request
class StockInItem {
  final String productId;
  final int quantity;

  StockInItem({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}

class StockInApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  String get _baseUrl => '${ApiConstants.baseUrl}/merchant/inventory/stock-in';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Performs a stock-in operation for a specific shop.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/inventory/stock-in`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "shopId": "uuid-shop-1",
  ///     "items": [
  ///       { "productId": "uuid-product-1", "quantity": 50 },
  ///       { "productId": "uuid-product-2", "quantity": 30 }
  ///     ]
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200 or 204
  /// - __Body:__ (Potentially a success message or empty)
  Future<void> performStockIn(
    String shopId,
    List<StockInItem> items, {
    String? clientOperationId,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 2));
      // Simulate a successful stock-in
      if (kDebugMode) getLogger('app').info('Mock Stock-In for shop $shopId with ${items.length} items.');
      return;
    }

    final body = {
      'clientOperationId': clientOperationId ?? const Uuid().v4(),
      'shopId': shopId,
      'items': items.map((item) => item.toJson()).toList(),
    };

    // Local-only mode: apply to local DB
    if (_appConfig.localStorageOnly) {
      final db = Get.find<LocalDatabaseService>();
      final actorId = await _authService.getUserId() ?? 'unknown';
      // Ensure items are properly typed for the local DB helper
      final itemsList = (body['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      await db.bulkStockInLocal(
        shopId: shopId,
        items: itemsList,
        actorId: actorId,
        clientOperationId: body['clientOperationId'] as String,
      );
      return;
    }

    // Defensive: if local-only is enabled but the local DB call above failed for
    // some reason, avoid sending network requests.
    if (_appConfig.localStorageOnly) {
      throw Exception('LOCAL_STORAGE_ONLY enabled and local DB unavailable');
    }

    final response = await _connect.post(
      _baseUrl,
      body,
      headers: await _getHeaders(),
    );

    if (!response.isOk) {
      // On network/backend failure, queue operation for retry
      try {
        final db = Get.find<LocalDatabaseService>();
        await db.queueOperation({
          'id': body['clientOperationId'],
          'client_operation_id': body['clientOperationId'],
          'entity_type': 'stock_in',
          'action': 'create',
          'method': 'POST',
          'endpoint': '/merchant/inventory/stock-in',
          'payload': body,
          'headers': await _getHeaders(),
        });
        return;
      } catch (_) {
        throw Exception(
          response.body?['message'] ?? 'Failed to perform stock-in',
        );
      }
    }
  }
}

