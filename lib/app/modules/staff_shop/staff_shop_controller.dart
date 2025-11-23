import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
// CORRECTED: Import the unified StaffApiService which now handles fetching shop details.
import 'package:smart_retail/app/data/services/staff_api_service.dart';

class StaffShopController extends GetxController {
  // CORRECTED: Use the unified StaffApiService.
  final StaffApiService _apiService = Get.find<StaffApiService>();
  // The AuthService is no longer directly needed here as the api service handles the token.
  // final AuthService _authService = Get.find<AuthService>();

  final RxBool isLoading = true.obs;
  final Rxn<Shop> shop = Rxn<Shop>();
  // ADDED: For providing better error feedback on the UI.
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAssignedShop();
  }

  /// Fetches the full details of the staff member's assigned shop.
  Future<void> fetchAssignedShop() async {
    try {
      isLoading.value = true;
      errorMessage.value = ''; // Reset error on retry

      // PREVIOUS LOGIC (for context):
      // final assignedShopId = _authService.user.value?.assignedShopId;
      // if (assignedShopId != null) {
      //   shop.value = Shop(id: assignedShopId, ...)
      // }

      // CORRECTED LOGIC:
      // The API service now gets the shop directly via the user's auth token.
      shop.value = await _apiService.getAssignedShop();
    } catch (e) {
      errorMessage.value = "Error fetching assigned shop: ${e.toString()}";
      shop.value = null; // Clear shop data on error
      DialogUtils.showError(errorMessage.value, title: "Loading Error");
    } finally {
      isLoading.value = false;
    }
  }
}
