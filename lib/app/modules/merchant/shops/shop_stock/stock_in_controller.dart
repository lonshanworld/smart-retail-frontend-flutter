import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import './shop_stock_controller.dart'; // To refresh the previous screen

class StockInController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>();

  late final String shopId;
  late final String inventoryItemId;
  late final String itemName;
  late final int currentQuantity;
  // late final String shopName; // Can be passed if needed for display

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController quantityAddedController = TextEditingController();

  var isSaving = false.obs;
  var errorMessage = RxnString();

  StockInController() {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    shopId = args['shopId'] as String;
    inventoryItemId = args['inventoryItemId'] as String;
    itemName = args['itemName'] as String? ?? 'Selected Item';
    currentQuantity = args['currentQuantity'] as int? ?? 0;
    // shopName = args['shopName'] as String? ?? '';
  }

  Future<void> performStockIn() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (isSaving.value) return;

    isSaving.value = true;
    errorMessage.value = null;

    try {
      final quantityAdded = int.tryParse(quantityAddedController.text);
      if (quantityAdded == null || quantityAdded <= 0) {
        errorMessage.value = "Please enter a valid quantity greater than 0.";
        isSaving.value = false;
        return;
      }

      final stockedItem = await _shopApiService.stockInItem(
        shopId,
        inventoryItemId,
        quantityAdded,
      );

      if (stockedItem != null) {
        Get.back(); // Go back to the shop stock list view

        // Notify ShopStockController to refresh its list
        if (Get.isRegistered<ShopStockController>()) {
          final shopStockCtrl = Get.find<ShopStockController>();
          // Check if the controller instance is the one for the current shopId
          if (shopStockCtrl.shopId == shopId) {
            await shopStockCtrl.fetchShopStock(showLoading: false);
          }
        }
        DialogUtils.showInfo(
          'Successfully added $quantityAdded to ${itemName}. New quantity: ${stockedItem.quantity}'
        );
      } else {
        errorMessage.value = 'Failed to stock in item. Please try again.';
        DialogUtils.showError(errorMessage.value!);
      }
    } catch (e) {
      print("Error stocking in item: $e");
      errorMessage.value = 'An error occurred: ${e.toString()}';
      DialogUtils.showError(errorMessage.value!);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    quantityAddedController.dispose();
    super.onClose();
  }
}
