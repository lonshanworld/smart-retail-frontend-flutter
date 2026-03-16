import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';

import 'package:smart_retail/app/utils/dialog_utils.dart';

class EditInventoryItemController extends GetxController {
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
  final Rxn<InventoryItem> itemToEdit = Rxn<InventoryItem>();
  final RxBool isCheckingDelete = false.obs;
  final RxBool isDeletable = false.obs;
  final RxMap<String, int> deleteBlockers = <String, int>{}.obs;
  // (service is declared above)

  @override
  void onInit() {
    super.onInit();
    itemToEdit.value = Get.arguments as InventoryItem?;

    nameController = TextEditingController(text: itemToEdit.value?.name);
    skuController = TextEditingController(text: itemToEdit.value?.sku);
    descriptionController = TextEditingController(
      text: itemToEdit.value?.description,
    );
    originalPriceController = TextEditingController(
      text: itemToEdit.value?.originalPrice?.toString(),
    );
    sellingPriceController = TextEditingController(
      text: itemToEdit.value?.sellingPrice.toString(),
    );
    brandController = TextEditingController(
      text: itemToEdit.value?.brandObj?.name,
    );

    selectedCategoryId.value = itemToEdit.value?.categoryId;
    selectedSubcategoryId.value = itemToEdit.value?.subcategoryId;
    selectedBrandId.value = itemToEdit.value?.brandId;

    _loadCatalogOptions();
  }

  Future<void> _loadCatalogOptions() async {
    final catalog = await _inventoryApiService.getCatalogOptions();
    if (catalog == null) return;

    categories.assignAll(catalog.categories);
    brands.assignAll(catalog.brands);

    setSelectedCategory(selectedCategoryId.value, preserveSubcategory: true);
  }

  void setSelectedCategory(
    String? categoryId, {
    bool preserveSubcategory = false,
  }) {
    selectedCategoryId.value = categoryId;

    if (categoryId == null) {
      filteredSubcategories.clear();
      selectedSubcategoryId.value = null;
      return;
    }

    final category = categories.firstWhereOrNull((c) => c.id == categoryId);
    filteredSubcategories.assignAll(category?.subcategories ?? const []);

    if (!preserveSubcategory) {
      selectedSubcategoryId.value = null;
    }
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

  Future<void> updateInventoryItem() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final updates = <String, dynamic>{
        'name': nameController.text,
        'sku': skuController.text,
        'description': descriptionController.text,
        'originalPrice': double.tryParse(originalPriceController.text) ?? 0.0,
        'sellingPrice': double.tryParse(sellingPriceController.text) ?? 0.0,
        'categoryId': selectedCategoryId.value,
        'subcategoryId': selectedSubcategoryId.value,
        'brandId': selectedBrandId.value,
      };

      final updatedItem = await _inventoryApiService.updateInventoryItem(
        itemToEdit.value!.id!,
        updates,
      );

      if (updatedItem != null) {
        Get.back(result: true);
        DialogUtils.showSuccess('Inventory item updated successfully');
      } else {
        DialogUtils.showError('Failed to update inventory item');
      }
    } catch (e) {
      DialogUtils.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkAndDeleteItem({bool skipFinalConfirm = false}) async {
    final item = itemToEdit.value;
    if (item == null || item.id == null) return;
    if (isCheckingDelete.value) return;
    isCheckingDelete.value = true;
    deleteBlockers.clear();
    try {
      final result = await _inventoryApiService.checkInventoryItemDeletable(
        item.id!,
      );
      if (result == null) {
        DialogUtils.showError('Failed to check deletion status.');
        return;
      }
      final bool deletable = result['deletable'] == true;
      final Map<String, dynamic> blockers = result['blockers'] ?? {};
      blockers.forEach((k, v) {
        if (v is int) {
          deleteBlockers[k] = v;
        } else if (v is String){
           deleteBlockers[k] = int.tryParse(v) ?? 0;
        }else{
          
        }        
      });
      isDeletable.value = deletable;
      if (!deletable) {
        final entries = deleteBlockers.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
        DialogUtils.showError(
          'Cannot delete item. References found:\n$entries',
        );
        return;
      }

      bool confirm = true;
      if (!skipFinalConfirm) {
        confirm =
            await DialogUtils.showConfirmDialog(
              title: 'Delete Item',
              message:
                  'Are you sure you want to permanently delete "${item.name}"? This action cannot be undone.',
              confirmText: 'Delete',
              cancelText: 'Cancel',
              isDanger: true,
            ) ??
            false;
      }
      if (confirm != true) return;

      final success = await _inventoryApiService.deleteInventoryItem(item.id!);
      if (success) {
        DialogUtils.showSuccess('Item deleted');
        Get.back(result: true);
      } else {
        DialogUtils.showError('Failed to delete item');
      }
    } catch (e) {
      DialogUtils.showError('Error: ${e.toString()}');
    } finally {
      isCheckingDelete.value = false;
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
