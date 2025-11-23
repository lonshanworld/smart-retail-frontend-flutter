import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/shop_inventory_item.dart';
import 'package:smart_retail/app/data/services/staff_inventory_api_service.dart';

class StaffInventoryController extends GetxController {
  final StaffInventoryApiService _apiService =
      Get.find<StaffInventoryApiService>();

  final RxBool isLoading = true.obs;
  final RxList<ShopInventoryItem> inventoryItems = <ShopInventoryItem>[].obs;
  final RxList<ShopInventoryItem> filteredItems = <ShopInventoryItem>[].obs;
  final RxString errorMessage = ''.obs;

  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Register a listener for the search controller
    searchController.addListener(_onSearchChanged);
    // Fetch the initial list of inventory items.
    fetchInventoryItems();
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.onClose();
  }

  /// Fetches the list of inventory items from the API service.
  Future<void> fetchInventoryItems() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final items = await _apiService.getInventoryItems();
      inventoryItems.assignAll(items);
      // Initially, the filtered list is the full list.
      filteredItems.assignAll(items);
    } catch (e) {
      errorMessage.value = "Failed to load inventory: ${e.toString()}";
      DialogUtils.showError(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Callback function that filters the inventory list based on search text.
  void _onSearchChanged() {
    final searchTerm = searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      // If search is empty, show all items.
      filteredItems.assignAll(inventoryItems);
    } else {
      // Otherwise, filter by name or SKU.
      filteredItems.assignAll(
        inventoryItems.where((item) {
          final nameMatch = item.name.toLowerCase().contains(searchTerm);
          final skuMatch =
              item.sku?.toLowerCase().contains(searchTerm) ?? false;
          return nameMatch || skuMatch;
        }).toList(),
      );
    }
  }

  /// Clears the search input and resets the filtered list.
  void clearSearch() {
    searchController.clear();
    filteredItems.assignAll(inventoryItems);
  }
}
