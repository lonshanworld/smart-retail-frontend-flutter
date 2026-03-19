import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/stock_movement_model.dart';
import 'package:smart_retail/app/data/services/shop_inventory_api_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class ShopInventoryController extends GetxController {
  final ShopInventoryApiService _apiService =
      Get.find<ShopInventoryApiService>();

  var shops = <Shop>[].obs;
  var shopInventoryList = <InventoryItem>[].obs;
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
      final result = await _apiService.getShops();
      shops.assignAll(result);

      // Find and select the specific shop
      final shop = shops.firstWhereOrNull((s) => s.id == shopId);
      if (shop != null) {
        onShopSelected(shop);
      } else if (shops.isNotEmpty) {
        onShopSelected(shops.first);
      }
    } catch (e) {
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
    if (selectedShop.value?.id == null) return;
    try {
      if (showLoading) isLoadingInventory.value = true;
      final result = await _apiService.getInventoryForShop(
        selectedShop.value!.id!,
      );
      shopInventoryList.assignAll(result);
    } catch (e) {
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
    } catch (e) {
      DialogUtils.showError('Failed to adjust stock: $e');
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
