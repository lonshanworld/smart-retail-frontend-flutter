import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';
import 'package:smart_retail/app/data/services/promotion_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

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
      print('[PromotionsController] fetchPromotions start');
      final response = await _apiService.getPromotions();
      print('[PromotionsController] fetchPromotions got ${response.items.length} items');
      promotions.assignAll(response.items);
      print('[PromotionsController] fetchPromotions finished');
    } catch (e) {
      error.value = e.toString();
      print('[PromotionsController] fetchPromotions error: $e');
      DialogUtils.showError('Failed to fetch promotions: ${e.toString()}');
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
    final result = await Get.toNamed(
      Routes.MERCHANT_PROMOTIONS_EDIT,
      arguments: promotion,
    );
    if (result == true) {
      fetchPromotions(); // Refresh list
    }
  }

  void deletePromotion(
    Promotion promotion, {
    bool skipConfirmation = false,
  }) async {
    bool? confirm = true;

    if (!skipConfirmation) {
      confirm = await DialogUtils.showConfirmDialog(
        title: 'Delete Promotion',
        message: 'Are you sure you want to delete "${promotion.name}"?',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDanger: true,
      );
    }

    if (confirm != true) return;

    try {
      await _apiService.deletePromotion(promotion.id);
      promotions.remove(promotion);
      DialogUtils.showSuccess('Promotion deleted successfully');
    } catch (e) {
      DialogUtils.showError('Failed to delete promotion: ${e.toString()}');
      // Re-fetch to restore the list if delete failed
      fetchPromotions();
    }
  }

  void togglePromotionStatus(Promotion promotion) async {
    final newStatus = !promotion.isActive;

    try {
      final updatedPromotion = await _apiService.togglePromotionStatus(
        promotion.id,
        newStatus,
      );

      // Update the promotion in the list
      final index = promotions.indexWhere((p) => p.id == promotion.id);
      if (index != -1) {
        promotions[index] = updatedPromotion;
        promotions.refresh();
      }

      DialogUtils.showSuccess(
        'Promotion ${newStatus ? 'activated' : 'deactivated'} successfully',
      );
    } catch (e) {
      DialogUtils.showError(
        'Failed to update promotion status: ${e.toString()}',
      );
    }
  }
}
