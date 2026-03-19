import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/staff_items_api_service.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';

class StaffItemsController extends GetxController {
  final StaffItemsApiService _apiService = Get.find<StaffItemsApiService>();

  final RxBool isLoading = true.obs;
  final RxList<InventoryItem> items = <InventoryItem>[].obs;
  final RxList<InventoryItem> filteredItems = <InventoryItem>[].obs;
  final RxString errorMessage = ''.obs;

  // Catalog options
  final InventoryApiService _inventoryApi = Get.find<InventoryApiService>();
  final RxList<CategoryWithSubcategories> categories =
      <CategoryWithSubcategories>[].obs;
  final RxList<BrandRef> brands = <BrandRef>[].obs;
  final RxList<SubcategoryRef> subcategories = <SubcategoryRef>[].obs;

  final RxnString selectedCategoryId = RxnString();
  final RxnString selectedSubcategoryId = RxnString();
  final RxnString selectedBrandId = RxnString();

  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadCatalogOptions();
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
      final result = await _apiService.getItems(
        categoryId: selectedCategoryId.value,
        subcategoryId: selectedSubcategoryId.value,
        brandId: selectedBrandId.value,
      );
      // DEBUG: print stockInfo for each item in development to help diagnose missing quantities
      for (var it in result) {
        try {
          debugPrint(
            '[StaffItems] item ${it.id ?? it.name} stockInfo: ${it.stockInfo}',
          );
        } catch (e) {
          debugPrint('[StaffItems] failed to print stockInfo: $e');
        }
      }
      items.assignAll(result);
      filteredItems.assignAll(result);
    } catch (e) {
      errorMessage.value = "Failed to load items: ${e.toString()}";
      DialogUtils.showError(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCatalogOptions() async {
    try {
      final opts = await _inventoryApi.getCatalogOptions();
      if (opts != null) {
        categories.assignAll(opts.categories);
        brands.assignAll(opts.brands);
      }
    } catch (e) {
      debugPrint('Failed to load catalog options: $e');
    }
  }

  void setCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
    // update subcategories list
    final cat = categories.firstWhereOrNull((c) => c.id == categoryId);
    if (cat != null) {
      subcategories.assignAll(cat.subcategories);
    } else {
      subcategories.clear();
    }
  }

  void clearFilters() {
    selectedCategoryId.value = null;
    selectedSubcategoryId.value = null;
    selectedBrandId.value = null;
    subcategories.clear();
    fetchItems();
  }

  void _onSearchChanged() {
    final searchTerm = searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      filteredItems.assignAll(items);
    } else {
      filteredItems.assignAll(
        items.where((item) {
          final nameMatch = item.name.toLowerCase().contains(searchTerm);
          final skuMatch =
              item.sku?.toLowerCase().contains(searchTerm) ?? false;
          return nameMatch || skuMatch;
        }).toList(),
      );
    }
  }

  void clearSearch() {
    searchController.clear();
    filteredItems.assignAll(items);
  }
}
