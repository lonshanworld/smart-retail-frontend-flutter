import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/staff_items_api_service.dart';

class StaffItemsController extends GetxController {
  final StaffItemsApiService _apiService = Get.find<StaffItemsApiService>();

  final RxBool isLoading = true.obs;
  final RxList<InventoryItem> items = <InventoryItem>[].obs;
  final RxList<InventoryItem> filteredItems = <InventoryItem>[].obs;
  final RxString errorMessage = ''.obs;

  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    fetchItems();
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchItems() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _apiService.getItems();
      items.assignAll(result);
      filteredItems.assignAll(result);
    } catch (e) {
      errorMessage.value = "Failed to load items: ${e.toString()}";
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  void _onSearchChanged() {
    final searchTerm = searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      filteredItems.assignAll(items);
    } else {
      filteredItems.assignAll(items.where((item) {
        final nameMatch = item.name.toLowerCase().contains(searchTerm);
        final skuMatch = item.sku?.toLowerCase().contains(searchTerm) ?? false;
        return nameMatch || skuMatch;
      }).toList());
    }
  }

  void clearSearch() {
    searchController.clear();
    filteredItems.assignAll(items);
  }
}
