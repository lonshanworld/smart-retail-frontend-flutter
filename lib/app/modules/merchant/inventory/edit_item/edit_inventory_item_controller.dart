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
  late TextEditingController categoryController;

  final RxBool isLoading = false.obs;
  final Rxn<InventoryItem> itemToEdit = Rxn<InventoryItem>();

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
    categoryController = TextEditingController(
      text: itemToEdit.value?.category,
    );
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
        'category': categoryController.text,
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

  @override
  void onClose() {
    nameController.dispose();
    skuController.dispose();
    descriptionController.dispose();
    originalPriceController.dispose();
    sellingPriceController.dispose();
    categoryController.dispose();
    super.onClose();
  }
}
