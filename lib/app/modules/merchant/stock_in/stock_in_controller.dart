import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/data/services/shop_inventory_api_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class StockInController extends GetxController {
  final InventoryApiService _inventoryApiService =
      Get.find<InventoryApiService>();
  final ShopInventoryApiService _shopInventoryApiService =
      Get.find<ShopInventoryApiService>();

  final RxList<InventoryItem> masterItems = <InventoryItem>[].obs;
  final Rxn<InventoryItem> selectedItem = Rxn<InventoryItem>();
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  late String shopId;
  final TextEditingController quantityController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    shopId = Get.arguments as String;
    fetchMasterInventory();
  }

  Future<void> fetchMasterInventory() async {
    try {
      isLoading.value = true;
      final response = await _inventoryApiService.listInventoryItems();
      if (response != null) {
        masterItems.assignAll(response.items);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void selectItem(InventoryItem? item) {
    selectedItem.value = item;
  }

  Future<void> addStockToShop() async {
    if (selectedItem.value == null || quantityController.text.isEmpty) {
      DialogUtils.showError('Please select an item and enter a quantity.');
      return;
    }

    final quantity = int.tryParse(quantityController.text);
    if (quantity == null || quantity <= 0) {
      DialogUtils.showError('Please enter a valid quantity.');
      return;
    }

    isSaving.value = true;
    try {
      final success = await _shopInventoryApiService.addStockToShop(
        shopId,
        selectedItem.value!.id!,
        quantity,
      );
      getLogger('app').info('check stock in succes or not $success');
      if (success) {
        Get.back(result: true);
        DialogUtils.showSuccess('Stock added successfully.');
      } else {
        DialogUtils.showError('Failed to add stock.');
      }
    } catch (e) {
      DialogUtils.showError(e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    quantityController.dispose();
    super.onClose();
  }
}

