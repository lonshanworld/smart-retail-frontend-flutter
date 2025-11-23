import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/admin_profile_api_service.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';

import 'package:smart_retail/app/utils/dialog_utils.dart';

class AdminProfileController extends GetxController {
  final AdminProfileApiService _apiService = Get.find<AdminProfileApiService>();
  final AuthService _authService = Get.find<AuthService>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final Rxn<User> userProfile = Rxn<User>();
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString formError = RxnString();

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
    formError.value = null;
    if (!formKey.currentState!.validate()) {
      formError.value = "Please correct the errors in the form.";
      return;
    }

    isSaving.value = true;
    try {
      final updates = <String, dynamic>{'name': nameController.text.trim()};
      if (passwordController.text.isNotEmpty) {
        updates['password'] = passwordController.text;
      }

      final updatedUser = await _apiService.updateMyProfile(updates);

      // IMPORTANT: Update the user in the global AuthService as well
      _authService.user.value = updatedUser;

      userProfile.value = updatedUser; // Refresh local profile data
      passwordController.clear();
      confirmPasswordController.clear();

      DialogUtils.showSuccess('Your profile has been updated.');
    } catch (e) {
      formError.value = "Update failed: ${e.toString()}";
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
