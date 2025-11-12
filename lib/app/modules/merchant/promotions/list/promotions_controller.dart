import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';
import 'package:smart_retail/app/data/services/promotion_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class PromotionsController extends GetxController {
  final PromotionApiService _apiService = Get.find<PromotionApiService>();

  var promotions = <Promotion>[].obs;
  var isLoading = true.obs;
  var error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchPromotions();
  }

  void fetchPromotions() async {
    try {
      isLoading.value = true;
      error.value = null;
      final response = await _apiService.getPromotions();
      promotions.assignAll(response.items);
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Failed to fetch promotions: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void goToAddPromotion() async {
    // Corrected Route
    final result = await Get.toNamed(Routes.MERCHANT_PROMOTIONS_ADD);
    if (result == true) {
      fetchPromotions(); // Refresh list if a promotion was added/edited
    }
  }

  void goToEditPromotion(Promotion promotion) async {
    // Corrected Route
    final result = await Get.toNamed(Routes.MERCHANT_PROMOTIONS_EDIT, arguments: promotion);
    if (result == true) {
      fetchPromotions(); // Refresh list
    }
  }

  void deletePromotion(Promotion promotion, {bool skipConfirmation = false}) async {
    bool? confirm = true;
    
    if (!skipConfirmation) {
      confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Promotion'),
          content: Text('Are you sure you want to delete "${promotion.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }

    if (confirm != true) return;

    try {
      await _apiService.deletePromotion(promotion.id);
      promotions.remove(promotion);
      Get.snackbar('Success', 'Promotion deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete promotion: ${e.toString()}');
      // Re-fetch to restore the list if delete failed
      fetchPromotions();
    }
  }

  void togglePromotionStatus(Promotion promotion) async {
    final newStatus = !promotion.isActive;
    
    try {
      final updatedPromotion = await _apiService.togglePromotionStatus(promotion.id, newStatus);
      
      // Update the promotion in the list
      final index = promotions.indexWhere((p) => p.id == promotion.id);
      if (index != -1) {
        promotions[index] = updatedPromotion;
        promotions.refresh();
      }
      
      Get.snackbar(
        'Success', 
        'Promotion ${newStatus ? 'activated' : 'deactivated'} successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update promotion status: ${e.toString()}');
    }
  }
}
