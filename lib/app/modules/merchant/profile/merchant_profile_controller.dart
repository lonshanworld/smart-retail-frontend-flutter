import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/merchant_profile_api_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class MerchantProfileController extends GetxController {
  final MerchantProfileApiService _apiService =
      Get.find<MerchantProfileApiService>();

  // Form
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Observables
  final Rxn<User> userProfile = Rxn<User>();
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final profile = await _apiService.getMyProfile();
      userProfile.value = profile;
      nameController.text = profile.name;
    } catch (e) {
      errorMessage.value = "Failed to load profile: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isSaving.value = true;
    try {
      final updates = <String, dynamic>{'name': nameController.text.trim()};
      if (passwordController.text.isNotEmpty) {
        updates['password'] = passwordController.text;
      }

      final updatedUser = await _apiService.updateMyProfile(updates);
      userProfile.value = updatedUser; // Refresh local profile data
      passwordController.clear();
      confirmPasswordController.clear();

      DialogUtils.showSuccess('Your profile has been updated.');
    } catch (e) {
      DialogUtils.showError("Update failed: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
