import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/data/services/shop_inventory_api_service.dart';

class MoveStockController extends GetxController {
  final InventoryApiService _inventoryApiService = Get.find<InventoryApiService>();
  final ShopInventoryApiService _shopInventoryApiService = Get.find<ShopInventoryApiService>();

  final RxList<InventoryItem> inventoryItems = <InventoryItem>[].obs;
  final RxList<Shop> shops = <Shop>[].obs;
  final Rxn<InventoryItem> selectedItem = Rxn<InventoryItem>();
  final Rxn<Shop> fromShop = Rxn<Shop>();
  final Rxn<Shop> toShop = Rxn<Shop>();
  
  final quantityController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool isLoadingData = true.obs;
  final RxnString errorMessage = RxnString();

  // Available stock in the selected source shop
  final RxInt availableStock = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      isLoadingData.value = true;
      errorMessage.value = null;

      // Load inventory items and shops in parallel
      final results = await Future.wait([
        _inventoryApiService.listInventoryItems(pageSize: 100),
        _shopInventoryApiService.getShops(),
      ]);

      if (results[0] != null) {
        inventoryItems.assignAll((results[0] as PaginatedInventoryResponse).items);
      }
      
      if (results[1] != null) {
        shops.assignAll(results[1] as List<Shop>);
      }

      if (inventoryItems.isEmpty) {
        errorMessage.value = 'No inventory items found. Please add items first.';
      } else if (shops.isEmpty) {
        errorMessage.value = 'No shops found. Please add shops first.';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load data: $e';
    } finally {
      isLoadingData.value = false;
    }
  }

  void selectInventoryItem(InventoryItem? item) {
    selectedItem.value = item;
    _updateAvailableStock();
  }

  void selectFromShop(Shop? shop) {
    fromShop.value = shop;
    
    // If toShop is same as fromShop, clear it
    if (toShop.value?.id == shop?.id) {
      toShop.value = null;
    }
    
    _updateAvailableStock();
  }

  void selectToShop(Shop? shop) {
    toShop.value = shop;
    
    // If fromShop is same as toShop, clear it
    if (fromShop.value?.id == shop?.id) {
      fromShop.value = null;
    }
  }

  void _updateAvailableStock() {
    if (selectedItem.value == null || fromShop.value == null) {
      availableStock.value = 0;
      return;
    }

    // Find stock info for the selected shop
    final stockInfo = selectedItem.value!.stockInfo?.firstWhereOrNull(
      (stock) => stock.shopId == fromShop.value!.id,
    );

    availableStock.value = stockInfo?.quantity ?? 0;
  }

  String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter quantity';
    }

    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) {
      return 'Please enter a valid positive number';
    }

    if (quantity > availableStock.value) {
      return 'Not enough stock (available: ${availableStock.value})';
    }

    return null;
  }

  Future<void> moveStock() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedItem.value == null) {
      Get.snackbar('Error', 'Please select an item', backgroundColor: Colors.red.shade100);
      return;
    }

    if (fromShop.value == null) {
      Get.snackbar('Error', 'Please select source shop', backgroundColor: Colors.red.shade100);
      return;
    }

    if (toShop.value == null) {
      Get.snackbar('Error', 'Please select destination shop', backgroundColor: Colors.red.shade100);
      return;
    }

    if (fromShop.value!.id == toShop.value!.id) {
      Get.snackbar('Error', 'Source and destination shops must be different', backgroundColor: Colors.red.shade100);
      return;
    }

    final quantity = int.parse(quantityController.text);

    try {
      isLoading.value = true;

      final success = await _inventoryApiService.moveStock(
        itemId: selectedItem.value!.id!,
        fromShopId: fromShop.value!.id!,
        toShopId: toShop.value!.id!,
        quantity: quantity,
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Stock moved successfully',
          backgroundColor: Colors.green.shade100,
          snackPosition: SnackPosition.BOTTOM,
        );
        
        // Clear form
        _resetForm();
        
        // Reload data to get updated stock levels
        await _loadInitialData();
      } else {
        Get.snackbar(
          'Error',
          'Failed to move stock. Please try again.',
          backgroundColor: Colors.red.shade100,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        backgroundColor: Colors.red.shade100,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _resetForm() {
    selectedItem.value = null;
    fromShop.value = null;
    toShop.value = null;
    quantityController.clear();
    availableStock.value = 0;
  }

  List<Shop> getAvailableFromShops() {
    if (selectedItem.value == null) return shops;
    
    // Only show shops that have stock of the selected item
    return shops.where((shop) {
      final stockInfo = selectedItem.value!.stockInfo?.firstWhereOrNull(
        (stock) => stock.shopId == shop.id,
      );
      return stockInfo != null && stockInfo.quantity > 0;
    }).toList();
  }

  List<Shop> getAvailableToShops() {
    if (fromShop.value == null) {
      return shops.where((shop) => shop.id != fromShop.value?.id).toList();
    }
    
    // Show all shops except the source shop
    return shops.where((shop) => shop.id != fromShop.value!.id).toList();
  }

  @override
  void onClose() {
    quantityController.dispose();
    super.onClose();
  }
}
