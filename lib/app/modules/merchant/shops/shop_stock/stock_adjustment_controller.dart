import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import './shop_stock_controller.dart'; // To refresh the previous screen

class StockAdjustmentController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>();

  // Item and Shop Info
  late final String shopId;
  late final String inventoryItemId;
  late final String itemName;
  late final String? itemSku;
  late final int initialQuantity;
  // late final String shopName; // Can be passed if needed for display

  // Form State
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController quantityChangeController =
      TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  var selectedAdjustmentType =
      RxnString(); // Holds the key of the adjustment type
  var isSaving = false.obs;
  var errorMessage = RxnString();

  // Predefined Adjustment Types (value: display name)
  final Map<String, String> adjustmentTypes = {
    'correction_add': 'Correction (Add Stock)',
    'correction_remove': 'Correction (Remove Stock)',
    'found_item': 'Found Item(s)',
    'spoilage': 'Spoilage/Expired',
    'damage': 'Damaged Item(s)',
    'theft': 'Theft/Loss',
    'return_to_supplier': 'Return to Supplier',
    'other_add': 'Other (Add)',
    'other_remove': 'Other (Remove)',
  };

  StockAdjustmentController() {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    shopId = args['shopId'] as String;
    inventoryItemId = args['inventoryItemId'] as String;
    itemName = args['itemName'] as String? ?? 'Selected Item';
    itemSku = args['itemSku'] as String?;
    initialQuantity = args['currentQuantity'] as int? ?? 0;
    // shopName = args['shopName'] as String? ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    // Set a default adjustment type if desired
    // selectedAdjustmentType.value = adjustmentTypes.keys.first;
  }

  Future<void> performAdjustment() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (isSaving.value) return;
    if (selectedAdjustmentType.value == null) {
      DialogUtils.showWarning('Please select an adjustment type.');
      return;
    }

    isSaving.value = true;
    errorMessage.value = null;

    try {
      final quantityChange = int.tryParse(quantityChangeController.text);
      if (quantityChange == null || quantityChange == 0) {
        errorMessage.value = "Please enter a valid, non-zero quantity change.";
        isSaving.value = false;
        DialogUtils.showWarning(errorMessage.value!);
        return;
      }

      final adjustedItem = await _shopApiService.adjustStockItem(
        shopId: shopId,
        inventoryItemId: inventoryItemId,
        adjustmentType: selectedAdjustmentType.value!,
        quantityChange: quantityChange,
        reason: reasonController.text.isNotEmpty ? reasonController.text : null,
      );

      if (adjustedItem != null) {
        Get.back(); // Go back to the shop stock list view

        if (Get.isRegistered<ShopStockController>()) {
          final shopStockCtrl = Get.find<ShopStockController>();
          if (shopStockCtrl.shopId == shopId) {
            await shopStockCtrl.fetchShopStock(showLoading: false);
          }
        }
        DialogUtils.showInfo(
          'Successfully adjusted stock for ${itemName}. New quantity: ${adjustedItem.quantity}',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Error snackbar is already shown by ShopApiService on failure
        // errorMessage.value = 'Failed to adjust stock. Please try again.';
      }
    } catch (e) {
      print("Error adjusting stock: $e");
      errorMessage.value = 'An error occurred: ${e.toString()}';
      DialogUtils.showError(errorMessage.value!);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    quantityChangeController.dispose();
    reasonController.dispose();
    super.onClose();
  }
}
