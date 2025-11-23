import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/services/admin_api_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class UserEditAdminController extends GetxController {
  final AdminApiService _apiService = Get.find<AdminApiService>();

  // Get user from arguments
  final User user = Get.arguments as User;

  // Form state
  final formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  var isActive = false.obs;

  // UI state
  var isLoading = false.obs;
  var isSaving = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: user.name);
    isActive.value = user.isActive;
  }

  Future<void> saveUser() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isSaving.value = true;
    try {
      final updateData = {
        'name': nameController.text,
        'isActive': isActive.value,
      };

      final updatedUser = await _apiService.adminUpdateUser(
        user.id,
        updateData,
      );

      if (updatedUser != null) {
        Get.back(result: true); // Go back and indicate success
        DialogUtils.showSuccess('User details updated successfully.');
      } else {
        DialogUtils.showError('Failed to update user. Please try again.');
      }
    } catch (e) {
      DialogUtils.showError(e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }
}
