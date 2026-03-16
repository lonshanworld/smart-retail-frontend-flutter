import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';

import 'package:smart_retail/app/utils/dialog_utils.dart';

class AddInventoryItemController extends GetxController {
  final InventoryApiService _inventoryApiService =
      Get.find<InventoryApiService>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController skuController;
  late TextEditingController descriptionController;
  late TextEditingController originalPriceController;
  late TextEditingController sellingPriceController;
  late TextEditingController brandController;

  final RxList<CategoryWithSubcategories> categories =
      <CategoryWithSubcategories>[].obs;
  final RxList<SubcategoryRef> filteredSubcategories = <SubcategoryRef>[].obs;
  final RxList<BrandRef> brands = <BrandRef>[].obs;
  final RxnString selectedCategoryId = RxnString();
  final RxnString selectedSubcategoryId = RxnString();
  final RxnString selectedBrandId = RxnString();

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    skuController = TextEditingController();
    descriptionController = TextEditingController();
    originalPriceController = TextEditingController();
    sellingPriceController = TextEditingController();
    brandController = TextEditingController();

    _loadCatalogOptions();
  }

  Future<void> _loadCatalogOptions() async {
    final catalog = await _inventoryApiService.getCatalogOptions();
    if (catalog == null) return;

    categories.assignAll(catalog.categories);
    brands.assignAll(catalog.brands);
    filteredSubcategories.clear();
  }

  void setSelectedCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
    selectedSubcategoryId.value = null;

    if (categoryId == null) {
      filteredSubcategories.clear();
      return;
    }

    final category = categories.firstWhereOrNull((c) => c.id == categoryId);
    filteredSubcategories.assignAll(category?.subcategories ?? const []);
  }

  void setSelectedSubcategory(String? subcategoryId) {
    selectedSubcategoryId.value = subcategoryId;
  }

  void selectBrandByName(String brandName) {
    final brand = brands.firstWhereOrNull(
      (b) => b.name.toLowerCase() == brandName.toLowerCase(),
    );
    selectedBrandId.value = brand?.id;
    brandController.text = brandName;
  }

  Future<void> createInventoryItem() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final newItem = InventoryItem(
        merchantId: '',
        name: nameController.text,
        sku: skuController.text,
        description: descriptionController.text,
        originalPrice: double.tryParse(originalPriceController.text) ?? 0.0,
        sellingPrice: double.tryParse(sellingPriceController.text) ?? 0.0,
        categoryId: selectedCategoryId.value,
        subcategoryId: selectedSubcategoryId.value,
        brandId: selectedBrandId.value,
        category: categories
            .firstWhereOrNull((c) => c.id == selectedCategoryId.value)
            ?.name,
        brandObj: brands.firstWhereOrNull((b) => b.id == selectedBrandId.value),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdItem = await _inventoryApiService.createInventoryItem(
        newItem,
      );

      if (createdItem != null) {
        Get.back(result: true);
        DialogUtils.showSuccess('Inventory item created successfully');
      } else {
        DialogUtils.showError('Failed to create inventory item');
      }
    } catch (e) {
      DialogUtils.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    skuController.dispose();
    descriptionController.dispose();
    originalPriceController.dispose();
    sellingPriceController.dispose();
    brandController.dispose();
    super.onClose();
  }
}
