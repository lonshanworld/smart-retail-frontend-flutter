import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/stock_movement_model.dart';
import 'package:smart_retail/app/data/services/shop_inventory_api_service.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class MerchantShopInventoryController extends GetxController {
  final ShopInventoryApiService _apiService =
      Get.find<ShopInventoryApiService>();
  final InventoryApiService _inventoryApiService =
      Get.find<InventoryApiService>();

  var shops = <Shop>[].obs;
  var shopInventoryList = <InventoryItem>[].obs;
  var allMerchantInventory = <InventoryItem>[].obs; // All merchant items
  var stockMovements = <StockMovement>[].obs;

  var selectedShop = Rxn<Shop>();
  var selectedItemForHistory = Rxn<InventoryItem>();
  var isLoadingShops = true.obs;
  var isLoadingInventory = false.obs;
  var isLoadingStockMovements = false.obs;
  var isSubmitting = false.obs;
  final TextEditingController searchController = TextEditingController();
  var searchTerm = ''.obs;

  Rxn<Shop> get selectedShopDetails => selectedShop;

  @override
  void onInit() {
    super.onInit();

    // Check if shop ID was passed as argument
    final String? shopIdArg = Get.arguments as String?;

    if (shopIdArg != null) {
      // Shop ID was passed, fetch shops and select the specific one
      fetchShopsAndSelectById(shopIdArg);
    } else {
      // No shop ID, fetch all shops and select first
      fetchShops();
    }

    searchController.addListener(() {
      onSearchChanged(searchController.text);
    });
  }

  void onSearchChanged(String value) {
    searchTerm.value = value;
  }

  void fetchShopsAndSelectById(String shopId) async {
    try {
      isLoadingShops.value = true;
      print('Fetching shops to select shopId: $shopId');
      final result = await _apiService.getShops();
      shops.assignAll(result);
      print('check here first, shops loaded: ${shops.length}');
      // Find and select the specific shop
      final shop = shops.firstWhereOrNull((s) => s.id == shopId);
      print('check here second, selected shop: $shop');
      if (shop != null) {
        onShopSelected(shop);
      } else if (shops.isNotEmpty) {
        onShopSelected(shops.first);
      }
    } catch (e) {
      print('Error fetching shops: $e');
      DialogUtils.showError('Failed to load shops: $e');
    } finally {
      isLoadingShops.value = false;
    }
  }

  void fetchShops() async {
    try {
      isLoadingShops.value = true;
      final result = await _apiService.getShops();
      shops.assignAll(result);
      if (shops.isNotEmpty) {
        onShopSelected(shops.first);
      }
    } catch (e) {
      DialogUtils.showError('Failed to load shops: $e');
    } finally {
      isLoadingShops.value = false;
    }
  }

  void onShopSelected(Shop? shop) {
    if (shop == null || shop.id == null) return;
    selectedShop.value = shop;
    fetchShopInventory();
  }

  Future<void> fetchShopInventory({bool showLoading = true}) async {
    print('Fetching inventory for shop: ${selectedShop.value?.name}');
    if (selectedShop.value?.id == null) return;
    try {
      if (showLoading) isLoadingInventory.value = true;
      final result = await _apiService.getInventoryForShop(
        selectedShop.value!.id!,
      );
      print('Inventory items fetched: ${result.length}');
      shopInventoryList.assignAll(result);
    } catch (e) {
      print('fetch inventory error: $e');
      DialogUtils.showError(
        'Failed to load inventory for ${selectedShop.value?.name}: $e',
      );
    } finally {
      if (showLoading) isLoadingInventory.value = false;
    }
  }

  Future<void> fetchStockMovementsForItem(InventoryItem item) async {
    if (selectedShop.value?.id == null || item.id == null) return;
    selectedItemForHistory.value = item;
    try {
      isLoadingStockMovements.value = true;
      final result = await _apiService.getMovementHistory(
        selectedShop.value!.id!,
        item.id!,
      );
      stockMovements.assignAll(result);
    } catch (e) {
      DialogUtils.showError('Failed to load history: $e');
    } finally {
      isLoadingStockMovements.value = false;
    }
  }

  Future<void> adjustStock(
    InventoryItem item,
    int quantityChanged,
    String movementType,
    String? reason,
  ) async {
    if (selectedShop.value?.id == null || item.id == null) {
      DialogUtils.showError(
        'Cannot adjust stock without a selected shop and item.',
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final clientOperationId = const Uuid().v4();
      await _apiService.adjustStock(
        shopId: selectedShop.value!.id!,
        itemId: item.id!,
        quantity: quantityChanged,
        reason: reason ?? movementType,
        clientOperationId: clientOperationId,
      );
      DialogUtils.showSuccess('Stock for ${item.name} adjusted successfully.');
      await fetchShopInventory(showLoading: false);
      await fetchAllMerchantInventory(); // Refresh all items list
    } catch (e) {
      DialogUtils.showError('Failed to adjust stock: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Fetches all merchant's inventory items (from API)
  Future<void> fetchAllMerchantInventory() async {
    try {
      print('Fetching all merchant inventory from API...');

      // Fetch all inventory items with a large page size to get all items
      final response = await _inventoryApiService.listInventoryItems(
        page: 1,
        pageSize: 1000, // Large page size to get all items
      );

      if (response != null && response.items.isNotEmpty) {
        allMerchantInventory.value = response.items;
        print(
          'Fetched ${response.items.length} merchant inventory items from API',
        );
      } else {
        allMerchantInventory.value = [];
        print('No inventory items found in API response');
      }
    } catch (e) {
      print('Error fetching merchant inventory from API: $e');
      allMerchantInventory.value = [];
      DialogUtils.showError('Failed to load merchant inventory: $e');
    }
  }

  /// Process bulk stock changes - handles both new items and existing items
  Future<void> processBulkStockChanges(
    List<MapEntry<InventoryItem, int>> changes,
  ) async {
    if (selectedShop.value?.id == null || changes.isEmpty) {
      DialogUtils.showError('Invalid shop or no changes to process');
      return;
    }

    isSubmitting.value = true;
    try {
      final shopId = selectedShop.value!.id!;
      final shopItemIds = shopInventoryList.map((item) => item.id).toSet();

      // Separate new items (need stock-in) from existing items (need adjust)
      final newItems = <Map<String, dynamic>>[];
      final existingAdjustments = <MapEntry<InventoryItem, int>>[];

      for (final change in changes) {
        final item = change.key;
        final quantityChange = change.value;

        if (!shopItemIds.contains(item.id)) {
          // New item - must use positive quantity for stock-in
          if (quantityChange > 0) {
            newItems.add({'productId': item.id, 'quantity': quantityChange});
          } else {
            print(
              'Skipping new item ${item.name} with negative/zero quantity: $quantityChange',
            );
          }
        } else {
          // Existing item - can adjust positive or negative
          existingAdjustments.add(change);
        }
      }

      // Process new items with bulk stock-in
      if (newItems.isNotEmpty) {
        print('Adding ${newItems.length} new items to shop via stock-in');
        await _apiService.bulkStockIn(shopId: shopId, items: newItems);
      }

      // Process existing items with individual adjustments
      for (final adjustment in existingAdjustments) {
        final item = adjustment.key;
        final quantityChange = adjustment.value;
        final movementType = quantityChange > 0
            ? 'stock_in'
            : 'inventory_correction';

        print('Adjusting existing item ${item.name} by $quantityChange');
        final clientOperationId = const Uuid().v4();
        await _apiService.adjustStock(
          shopId: shopId,
          itemId: item.id!,
          quantity: quantityChange,
          reason: movementType,
          clientOperationId: clientOperationId,
        );
      }

      DialogUtils.showSuccess(
        'Stock updated: ${newItems.length} new items added, ${existingAdjustments.length} items adjusted',
      );

      // Refresh both lists
      await fetchShopInventory(showLoading: false);
      await fetchAllMerchantInventory();
    } catch (e) {
      print('Error processing bulk stock changes: $e');
      DialogUtils.showError('Failed to update stock: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
