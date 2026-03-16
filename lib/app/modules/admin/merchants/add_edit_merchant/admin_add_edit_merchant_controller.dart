// lib/app/modules/admin/merchants/add_edit_merchant/admin_add_edit_merchant_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/merchant_model.dart';
import 'package:smart_retail/app/data/models/user_model.dart'; // Import User model
import 'package:smart_retail/app/data/services/admin_merchant_service.dart';

import 'package:smart_retail/app/utils/dialog_utils.dart';

class AdminAddEditMerchantController extends GetxController {
  final AdminMerchantService adminMerchantService;

  AdminAddEditMerchantController({required this.adminMerchantService});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController shopNameController;
  late TextEditingController phoneController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  final RxBool isActive = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;
  Merchant? _merchantToEdit;

  final RxString pageTitle = "Add New Merchant".obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    emailController = TextEditingController();
    shopNameController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    final dynamic argument = Get.arguments;
    if (argument is Merchant) {
      isEditMode.value = true;
      _merchantToEdit = argument;
      pageTitle.value = "Edit Merchant Details";
      _initializeFormFields(_merchantToEdit!);
    }
  }

  void _initializeFormFields(Merchant merchant) {
    nameController.text = merchant.name;
    emailController.text = merchant.email;
    shopNameController.text = merchant.shopName ?? "";
    phoneController.text = merchant.phone ?? "";
    isActive.value = merchant.isActive;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return "Name is required.";
    if (value.length < 2) return "Name must be at least 2 characters.";
    if (value.length > 100) return "Name cannot exceed 100 characters.";
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required.";
    if (!GetUtils.isEmail(value)) return "Enter a valid email address.";
    return null;
  }

  String? validateShopName(String? value) {
    if (value == null || value.isEmpty) {
      return "Shop name is required for a merchant.";
    }
    if (value.length < 2) return "Shop name must be at least 2 characters.";
    if (value.length > 100) return "Shop name cannot exceed 100 characters.";
    return null;
  }

  String? validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!GetUtils.isPhoneNumber(value)) {
        return "Invalid phone number format.";
      }
      if (value.length < 7 || value.length > 15) {
        return "Phone number seems too short or too long.";
      }
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (!isEditMode.value) {
      if (value == null || value.isEmpty) return "Password is required.";
      if (value.length < 6) return "Password must be at least 6 characters.";
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (!isEditMode.value) {
      if (value == null || value.isEmpty) {
        return "Confirm password is required.";
      }
      if (value != passwordController.text) return "Passwords do not match.";
    }
    return null;
  }

  Future<void> saveMerchant() async {
    if (!formKey.currentState!.validate()) {
      DialogUtils.showError("Please correct the errors in the form.");
      return;
    }

    isLoading.value = true;

    try {
      User? resultUser;

      if (isEditMode.value && _merchantToEdit != null) {
        Map<String, dynamic> updates = {};

        if (nameController.text != _merchantToEdit!.name) {
          updates['name'] = nameController.text;
        }
        if (emailController.text != _merchantToEdit!.email) {
          updates['email'] = emailController.text;
        }
        if (isActive.value != _merchantToEdit!.isActive) {
          updates['isActive'] = isActive.value;
        }

        // Handle shop name
        final currentShopName = shopNameController.text.trim();
        final oldShopName = _merchantToEdit!.shopName ?? "";
        if (currentShopName != oldShopName) {
          updates['shopName'] = currentShopName.isEmpty
              ? null
              : currentShopName;
        }

        // Handle phone
        final currentPhone = phoneController.text.trim();
        final oldPhone = _merchantToEdit!.phone ?? "";
        if (currentPhone != oldPhone) {
          updates['phone'] = currentPhone.isEmpty ? null : currentPhone;
        }

        if (updates.isEmpty) {
          DialogUtils.showInfo("No changes were made.");
          isLoading.value = false;
          return;
        }

        resultUser = await adminMerchantService.updateUserMerchantDetails(
          _merchantToEdit!.id,
          updates,
        );

        if (resultUser != null) {
          Get.back(result: true);
          DialogUtils.showSuccess("Merchant updated successfully.");
        } else {
          DialogUtils.showError("Could not update merchant. Please try again.");
        }
      } else {
        Map<String, dynamic> newUserData = {
          'name': nameController.text,
          'email': emailController.text,
          'password': passwordController.text,
          'role': 'MERCHANT',
          'isActive': isActive.value,
          'shopName': shopNameController.text,
          'phone': phoneController.text.isNotEmpty
              ? phoneController.text
              : null,
        };

        resultUser = await adminMerchantService.createUserAsMerchant(
          newUserData,
        );
        if (resultUser != null) {
          // CORRECTED: Only navigate back with a success result.
          // The previous screen will be responsible for showing the snackbar.
          Get.back(result: true);
        } else {
          DialogUtils.showError("Could not save merchant. Please try again later.");
        }
      }
    } catch (e) {
      printError(info: "Error saving merchant/user: $e");
      DialogUtils.showError("An unexpected error occurred: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    shopNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
