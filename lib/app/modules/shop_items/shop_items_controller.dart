import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_inventory_item.dart';
import 'package:smart_retail/app/data/services/shop_items_api_service.dart';

class ShopItemsController extends GetxController {
  final ShopItemsApiService _apiService = Get.find<ShopItemsApiService>();

  final RxBool isLoading = true.obs;
  final RxList<ShopInventoryItem> inventoryItems = <ShopInventoryItem>[].obs;
  late final String shopId;

  @override
  void onInit() {
    super.onInit();
    // Get shopId from route parameters
    shopId = Get.parameters['shopId'] ?? '';
    if (shopId.isEmpty) {
      Get.snackbar('Error', 'Shop ID is required');
      return;
    }
    fetchInventoryItems();
  }

  Future<void> fetchInventoryItems() async {
    try {
      isLoading.value = true;
      final items = await _apiService.getShopItems(shopId: shopId);
      // Convert InventoryItem to ShopInventoryItem
      final shopItems = items.map((item) {
        final stock = item.stockInfo?.firstOrNull;
        return ShopInventoryItem(
          id: item.id ?? '',
          productId: item.id ?? '',
          name: item.name,
          sku: item.sku,
          quantity: stock?.quantity ?? 0,
          sellingPrice: item.sellingPrice,
        );
      }).toList();
      inventoryItems.assignAll(shopItems);
    } catch (e) {
      Get.snackbar('Error', 'Could not load inventory items: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void showStockAdjustmentDialog(ShopInventoryItem item) {
    final currentQuantity = item.quantity.obs;

    Get.dialog(
      AlertDialog(
        title: Text('Adjust Stock for ${item.name}'),
        content: Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (currentQuantity.value > 0) {
                    currentQuantity.value--;
                  }
                },
              ),
              Text('${currentQuantity.value}', style: Get.textTheme.headlineMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => currentQuantity.value++,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              updateStock(item.id, currentQuantity.value);
              Get.back();
            },
          ),
        ],
      ),
    );
  }

  Future<void> updateStock(String itemId, int newQuantity) async {
    try {
      await _apiService.updateStockQuantity(itemId, newQuantity);
      await fetchInventoryItems(); // Refresh the list
      Get.snackbar('Success', 'Stock updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update stock: $e');
    }
  }
}
