import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/merchant_stock_in_request_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/utils/api_exception.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class StockInService extends GetxService {
  final AppConfig _appConfig = Get.find<AppConfig>();
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();

  // REMOVED: getMasterInventoryItems is no longer needed.

  /// Submits a stock-in record for a specific shop.
  /// The backend will handle creating a new item or updating the quantity of an existing one.
  Future<void> stockInItem(
    String shopId,
    MerchantStockInRequest requestData,
  ) async {
    // Local-only mode: persist stock-in in local DB and update shop stock
    if (_appConfig.localStorageOnly) {
      try {
        final localDb = Get.find<LocalDatabaseService>();
        final actorId = await _authService.getUserId() ?? 'local-user';
        final storedShop = await localDb.getShopById(shopId);
        final merchantId =
            _authService.user.value?.merchantId ??
            _authService.userId.value ??
            await _authService.getUserId() ??
            storedShop?['merchant_id']?.toString() ??
            storedShop?['merchantId']?.toString();
        if (merchantId == null || merchantId.isEmpty) {
          throw Exception('Merchant ID not available in local mode');
        }
        final clientOperationId = const Uuid().v4();

        // Upsert a minimal inventory item record so shop_stock has a reference
        final productId = const Uuid().v4();
        final itemMap = {
          'id': productId,
          'merchant_id': merchantId,
          'name': requestData.itemName,
          'sku': requestData.sku,
          'selling_price': requestData.unitPrice,
          'original_price': requestData.costPrice ?? requestData.unitPrice,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await localDb.upsertInventoryItem(itemMap);

        // Apply stock to the shop locally (idempotent via clientOperationId)
        await localDb.addStockToShopLocal(
          shopId: shopId,
          productId: productId,
          quantity: requestData.quantityReceived,
          actorId: actorId,
          clientOperationId: clientOperationId,
        );

        return;
      } catch (e) {
        if (kDebugMode) {
          getLogger('app').info('[StockInService] Local stock-in failed: $e');
        }
        return;
      }
    }
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      if (kDebugMode) {
        getLogger('app').info(
          "Mock Stock-In Success for Shop ID: $shopId with data: ${requestData.toJson()}",
        );
      }
      // In a real scenario, you might get validation errors here.
      // For example, if a SKU already exists with a different name.
      // We will simulate a simple success case.
      return;
    }

    final token = await _authService.getToken();
    final response = await _connect.post(
      '${ApiConstants.baseUrl}/merchant/shops/$shopId/stock-in',
      requestData.toJson(),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      // Use the custom exception model for better error handling in the controller.
      final message =
          response.body?['message'] as String? ?? 'Failed to record stock-in';
      if (response.statusCode == 400) {
        throw ApiValidationException(message);
      } else if (response.statusCode == 401) {
        throw ApiAuthException(message);
      } else if (response.statusCode == 403) {
        throw ApiForbiddenException(message);
      } else if (response.statusCode == 404) {
        throw ApiNotFoundException(message);
      } else {
        throw ApiException(message);
      }
    }
  }
}

