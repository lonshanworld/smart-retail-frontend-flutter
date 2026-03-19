import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/shop_inventory_item.dart';
import 'package:smart_retail/app/data/services/shop_items_api_service.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';

class ShopItemsController extends GetxController {
  final ShopItemsApiService _apiService = Get.find<ShopItemsApiService>();

  final RxBool isLoading = true.obs;
  final RxList<ShopInventoryItem> inventoryItems = <ShopInventoryItem>[].obs;
  final RxList<CategoryWithSubcategories> categories =
      <CategoryWithSubcategories>[].obs;
  final RxList<SubcategoryRef> filteredSubcategories = <SubcategoryRef>[].obs;
  final RxList<BrandRef> brands = <BrandRef>[].obs;
  final RxnString selectedCategoryId = RxnString();
  final RxnString selectedSubcategoryId = RxnString();
  final RxnString selectedBrandId = RxnString();
  late final String shopId;

  @override
  void onInit() {
    super.onInit();
    // Get shopId from route parameters
    shopId = Get.parameters['shopId'] ?? '';
    if (shopId.isEmpty) {
      DialogUtils.showError('Shop ID is required');
      return;
    }
    _loadCatalogOptions();
    fetchInventoryItems();
  }

  Future<void> _loadCatalogOptions() async {
    final inv = Get.find<InventoryApiService>();
    final catalog = await inv.getCatalogOptions();
    if (catalog == null) return;
    categories.assignAll(catalog.categories);
    brands.assignAll(catalog.brands);
    filteredSubcategories.clear();
  }

  Future<void> fetchInventoryItems() async {
    try {
      isLoading.value = true;
      final items = await _apiService.getShopItems(
        shopId: shopId,
        categoryId: selectedCategoryId.value,
        subcategoryId: selectedSubcategoryId.value,
        brandId: selectedBrandId.value,
      );
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
      DialogUtils.showError('Could not load inventory items: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void showStockAdjustmentDialog(ShopInventoryItem item) {
    final currentQuantity = item.quantity.obs;

    DialogUtils.showCustomDialog(
      dialog: AlertDialog(
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
              Text(
                '${currentQuantity.value}',
                style: Get.textTheme.headlineMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => currentQuantity.value++,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Get.back()),
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
      DialogUtils.showSuccess('Stock updated successfully');
    } catch (e) {
      DialogUtils.showError('Failed to update stock: $e');
    }
  }
}
