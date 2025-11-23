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
  late TextEditingController categoryController;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    skuController = TextEditingController();
    descriptionController = TextEditingController();
    originalPriceController = TextEditingController();
    sellingPriceController = TextEditingController();
    categoryController = TextEditingController();
  }

  Future<void> createInventoryItem() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final newItem = InventoryItem(
        merchantId: 'your-merchant-id', // Replace with actual merchant ID
        name: nameController.text,
        sku: skuController.text,
        description: descriptionController.text,
        originalPrice: double.tryParse(originalPriceController.text) ?? 0.0,
        sellingPrice: double.tryParse(sellingPriceController.text) ?? 0.0,
        category: categoryController.text,
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
    categoryController.dispose();
    super.onClose();
  }
}
