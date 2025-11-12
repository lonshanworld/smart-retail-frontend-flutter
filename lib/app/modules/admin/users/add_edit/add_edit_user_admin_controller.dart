import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/admin_user_service.dart'; // <<< CORRECTED IMPORT
import 'package:smart_retail/app/modules/admin/users/users_admin_controller.dart'; // To refresh list
import 'package:smart_retail/app/data/enums/user_role.dart';
import 'package:smart_retail/app/data/models/user_selection_item.dart';

class AddEditUserAdminController extends GetxController {
  final AdminUserService _adminUserService = Get.find<AdminUserService>(); // <<< CORRECTED SERVICE

  // Form
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final shopNameController = TextEditingController(); // For merchant role

  // Observables
  final RxBool isEditMode = false.obs;
  final Rx<UserRole> selectedRole = UserRole.staff.obs; // Default role
  final RxBool isPasswordObscured = true.obs;
  final RxList<UserSelectionItem> merchantsForSelection = <UserSelectionItem>[].obs;
  final RxnString selectedMerchantId = RxnString(); // For staff role
  final RxBool isFetchingMerchants = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isActive = true.obs; // Default for new users
  final RxnString formError = RxnString();

  User? _editingUser;

  @override
  void onInit() {
    super.onInit();
    // When the view is loaded, check if a User object was passed as an argument
    if (Get.arguments is User) {
      _editingUser = Get.arguments as User;
      isEditMode.value = true;
      // Pre-fill form fields with the existing user's data
      nameController.text = _editingUser!.name;
      emailController.text = _editingUser!.email;
      selectedRole.value = _editingUser!.roleAsEnum;
      isActive.value = _editingUser!.isActive;
      shopNameController.text = _editingUser!.shopName ?? '';
      selectedMerchantId.value = _editingUser!.merchantId;
    } else {
      isEditMode.value = false;
    }
    
    // Add a listener to the role dropdown to react to changes
    selectedRole.listen((role) {
      _handleRoleChange(role);
    });

    // Initial setup based on the role (for both new and edit modes)
    _handleRoleChange(selectedRole.value);
  }

  // This method is called when the role is changed by the user.
  void _handleRoleChange(UserRole role) {
    formError.value = null; // Clear previous errors
    // If the role is changed to Staff and the merchants list is empty, fetch it.
    if (role == UserRole.staff && merchantsForSelection.isEmpty && !isFetchingMerchants.value) {
      fetchMerchantsForSelection();
    }
  }

  // Fetches the list of merchants from the API service to populate the dropdown.
  Future<void> fetchMerchantsForSelection() async {
    if (isFetchingMerchants.value) return; // Prevent multiple simultaneous calls
    isFetchingMerchants.value = true;
    try {
      final merchants = await _adminUserService.getMerchantsForSelection(); // <<< CORRECTED CALL
      if (merchants != null) {
        merchantsForSelection.assignAll(merchants);
      } else {
        merchantsForSelection.clear(); // Clear list on failure
      }
    } catch (e) {
      printError(info: "Error fetching merchants: $e");
      Get.snackbar('Error', 'Could not load merchants: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      merchantsForSelection.clear();
    } finally {
      isFetchingMerchants.value = false;
    }
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  void onRoleChanged(UserRole? newRole) {
    if (newRole != null) {
      selectedRole.value = newRole;
    }
  }

  // Main logic to save the user (either create a new one or update an existing one)
  Future<void> saveUser() async {
    formError.value = null; // Reset error message
    if (!formKey.currentState!.validate()) {
      formError.value = "Please correct the errors in the form.";
      return;
    }

    isSaving.value = true;
    try {
      Map<String, dynamic> userData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole.value.name.toUpperCase(),
        'isActive': isActive.value,
      };

      if (!isEditMode.value && passwordController.text.isNotEmpty) {
        userData['password'] = passwordController.text;
      } else if (!isEditMode.value && passwordController.text.isEmpty) {
        formError.value = "Password is required for new users.";
        isSaving.value = false;
        return;
      }

      if (selectedRole.value == UserRole.merchant) {
        if (shopNameController.text.trim().isEmpty) {
          formError.value = "Shop Name is required for Merchant role.";
          isSaving.value = false;
          return;
        }
        userData['shopName'] = shopNameController.text.trim();
        userData['merchantId'] = null; 
      } else if (selectedRole.value == UserRole.staff) {
        if (selectedMerchantId.value == null || selectedMerchantId.value!.isEmpty) {
          formError.value = "Associated Merchant is required for Staff role.";
          isSaving.value = false;
          return;
        }
        userData['merchantId'] = selectedMerchantId.value;
        userData['shopName'] = null;
      } else {
        userData['shopName'] = null;
        userData['merchantId'] = null;
      }

      User? savedUser;
      if (isEditMode.value && _editingUser != null) {
        savedUser = await _adminUserService.updateUser(_editingUser!.id, userData); // <<< CORRECTED CALL
      } else {
        savedUser = await _adminUserService.createUser(userData); // <<< CORRECTED CALL
      }

      if (savedUser != null) {
        // Try to find the UsersAdminController to refresh its list after saving.
        try {
          Get.find<UsersAdminController>().fetchUsers();
        } catch (e) {
          print("AddEditUserAdminController: Could not find UsersAdminController to refresh: $e");
        }
        Get.back(); // Go back to the previous screen
        Get.snackbar('Success', 'User "${savedUser.name}" ${isEditMode.value ? "updated" : "created"} successfully!',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        formError.value = "Failed to save user. The operation returned no result.";
      }
    } catch (e) {
      printError(info: "Error saving user: $e");
      String errorMessage = e.toString().replaceFirst("Exception: ", "");
      formError.value = "Failed to save user: $errorMessage";
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    shopNameController.dispose();
    super.onClose();
  }
}
