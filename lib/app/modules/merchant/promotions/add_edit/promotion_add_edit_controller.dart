import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/promotion_api_service.dart';

class PromotionAddEditController extends GetxController {
  final PromotionApiService _apiService = Get.find<PromotionApiService>();

  // Form state
  final formKey = GlobalKey<FormState>();
  var isSaving = false.obs;
  var isEditing = false.obs;
  Promotion? existingPromotion;

  // Dropdown lists
  var shopList = <Shop>[].obs;
  var productList = <InventoryItem>[].obs;
  var isLoadingShops = true.obs;
  var isLoadingProducts = false.obs;

  // Selected values
  var selectedShop = Rxn<Shop>();
  var selectedProduct = Rxn<InventoryItem>();
  var selectedPromotionType = 'percentage'.obs;
  var promotionAppliesTo = 'all'.obs; // 'all' or 'specific'

  // Dates
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();

  // Text editing controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final valueController = TextEditingController();
  final minSpendController = TextEditingController();

  String get formattedStartDate => startDate.value != null ? DateFormat('yyyy-MM-dd').format(startDate.value!) : 'Select Date';
  String get formattedEndDate => endDate.value != null ? DateFormat('yyyy-MM-dd').format(endDate.value!) : 'Select Date';

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();

    if (Get.arguments is Promotion) {
      isEditing.value = true;
      existingPromotion = Get.arguments as Promotion;
      loadPromotionData(existingPromotion!);
    }
  }

  void fetchInitialData() async {
    try {
      isLoadingShops.value = true;
      shopList.value = await _apiService.getShops();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load shops: $e');
    } finally {
      isLoadingShops.value = false;
    }
  }

  void onShopSelected(Shop? shop) async {
    if (shop == null || shop.id == null) return;
    selectedShop.value = shop;
    selectedProduct.value = null;
    productList.clear();
    await fetchProductsForShop(shop.id!);
  }

  Future<void> fetchProductsForShop(String shopId) async {
    try {
      isLoadingProducts.value = true;
      productList.value = await _apiService.getProductsForShop(shopId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load products: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  void onProductSelected(InventoryItem? product) {
    selectedProduct.value = product;
  }

  void loadPromotionData(Promotion promo) async {
    nameController.text = promo.name;
    descriptionController.text = promo.description;
    selectedPromotionType.value = promo.type;
    valueController.text = promo.value.toString();
    startDate.value = promo.startDate;
    endDate.value = promo.endDate;
    minSpendController.text = promo.minSpend.toString();

    if (promo.shopId != null) {
      await until(() => !isLoadingShops.value);
      selectedShop.value = shopList.firstWhereOrNull((s) => s.id == promo.shopId);
      if (selectedShop.value != null && selectedShop.value!.id != null) {
        await fetchProductsForShop(selectedShop.value!.id!);
      }
    }
  }

  Future<void> selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? startDate.value : endDate.value) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      if (isStartDate) {
        startDate.value = picked;
      } else {
        endDate.value = picked;
      }
    }
  }

  void savePromotion() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar('Invalid Input', 'Please correct the errors in the form.');
      return;
    }

    // Validate specific product selection if needed
    if (promotionAppliesTo.value == 'specific' && selectedProduct.value == null) {
      Get.snackbar('Invalid Input', 'Please select at least one product for this promotion.');
      return;
    }

    isSaving.value = true;

    final promotionData = <String, dynamic>{
      'name': nameController.text,
      'description': descriptionController.text,
      'type': selectedPromotionType.value,
      'value': double.tryParse(valueController.text) ?? 0,
      'minSpend': double.tryParse(minSpendController.text.isEmpty ? '0' : minSpendController.text) ?? 0,
      'shopId': selectedShop.value?.id,
      'isActive': true,
      'conditions': {},
    };

    // Only add dates if they are selected (send null instead of empty string)
    if (startDate.value != null) {
      promotionData['startDate'] = startDate.value!.toIso8601String();
    }
    if (endDate.value != null) {
      promotionData['endDate'] = endDate.value!.toIso8601String();
    }

    // Product-specific promotion support
    if (promotionAppliesTo.value == 'specific' && selectedProduct.value != null) {
      promotionData['productIds'] = [selectedProduct.value!.id];
    }

    try {
      if (isEditing.value) {
        await _apiService.updatePromotion(existingPromotion!.id, promotionData);
        Get.back(result: true);
        Get.snackbar('Success', 'Promotion updated successfully!');
      } else {
        await _apiService.createPromotion(promotionData);
        Get.back(result: true);
        Get.snackbar('Success', 'Promotion created successfully!');
      }
    } catch (e) {
      Get.snackbar('Save Failed', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> until(bool Function() condition) async {
    while (!condition()) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
