import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/enums/user_role.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/models/user_selection_item.dart'; // Verified import
import 'package:smart_retail/app/data/services/admin_user_service.dart';
import 'package:smart_retail/app/utils/string_extensions.dart'; // <<< ADDED GLOBAL EXTENSION IMPORT

class AdminUsersController extends GetxController {
  final AdminUserService adminUserService;

  AdminUsersController({required this.adminUserService});

  // --- State Variables ---
  var isLoading = true.obs;
  var userList = <User>[].obs;
  var merchantSelectionList =
      <UserSelectionItem>[].obs; // Uses UserSelectionItem
  var errorMessage = RxnString();

  // Pagination
  var currentPage = 1.obs;
  var pageSize = 10.obs;
  var totalItems = 0.obs;
  int get totalPages => (totalItems.value / pageSize.value).ceil();

  // Filtering & Search
  var selectedRoleFilter = Rxn<UserRole>();
  var selectedStatusFilter = Rxn<bool>();
  var searchTerm = ''.obs;
  TextEditingController searchController = TextEditingController();

  // For Create/Edit User Form
  final GlobalKey<FormState> userFormKey = GlobalKey<FormState>();
  var isEditMode = false.obs;
  var editableUser = Rxn<User>();

  // Form fields observables
  var nameController = TextEditingController().obs;
  var emailController = TextEditingController().obs;
  var passwordController = TextEditingController().obs;
  var selectedRole = Rxn<UserRole>();
  var selectedMerchantId = RxnString();
  var isActive = true.obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchTerm.value = searchController.text;
    });
    debounce(
      searchTerm,
      (_) => fetchUsers(page: 1),
      time: const Duration(milliseconds: 500),
    );
    fetchUsers();
    fetchMerchantsForSelection();
  }

  @override
  void onClose() {
    searchController.dispose();
    nameController.value.dispose();
    emailController.value.dispose();
    passwordController.value.dispose();
    super.onClose();
  }

  // --- Core Data Fetching ---
  Future<void> fetchUsers({int page = 1}) async {
    isLoading.value = true;
    errorMessage.value = null;
    currentPage.value = page;

    try {
      final paginatedResponse = await adminUserService.listUsers(
        page: currentPage.value,
        pageSize: pageSize.value,
        role: selectedRoleFilter.value != null
            ? userRoleToString(selectedRoleFilter.value!)
            : null,
        isActive: selectedStatusFilter.value,
        searchTerm: searchTerm.value,
      );

      if (paginatedResponse != null) {
        userList.value = paginatedResponse.users;
        totalItems.value = paginatedResponse.totalCount; // CORRECTED HERE
      } else {
        errorMessage.value = "Failed to load users. Please try again.";
        userList.clear();
        totalItems.value = 0;
      }
    } catch (e) {
      printError(info: e.toString());
      errorMessage.value = "Error fetching users: ${e.toString()}";
      userList.clear();
      totalItems.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMerchantsForSelection() async {
    try {
      final merchantList = await adminUserService.getMerchantsForSelection();
      if (merchantList != null) {
        merchantSelectionList.value = merchantList;
      }
    } catch (e) {
      printError(info: e.toString());
      DialogUtils.showError(
        "Could not load merchants for selection: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // --- CRUD Operations ---
  void prepareCreateUserForm() {
    isEditMode.value = false;
    editableUser.value = null;
    nameController.value.clear();
    emailController.value.clear();
    passwordController.value.clear();
    selectedRole.value = null;
    selectedMerchantId.value = null;
    isActive.value = true;
  }

  void prepareEditUserForm(User user) {
    isEditMode.value = true;
    editableUser.value = user;
    nameController.value.text = user.name;
    emailController.value.text = user.email;
    passwordController.value.clear();
    selectedRole.value = user.roleAsEnum;
    selectedMerchantId.value = user.merchantId;
    isActive.value = user.isActive;
  }

  Future<void> saveUser() async {
    if (!userFormKey.currentState!.validate()) {
      DialogUtils.showError(
        "Please correct the errors in the form.",
        title: "Validation Error",
      );
      return;
    }

    if (selectedRole.value == null) {
      DialogUtils.showError(
        "Please select a role for the user.",
        title: "Validation Error",
      );
      return;
    }

    final Map<String, dynamic> userData = {
      'name': nameController.value.text,
      'email': emailController.value.text,
      'role': userRoleToString(selectedRole.value!),
    };
    if (selectedRole.value == UserRole.staff) {
      userData['merchantId'] = selectedMerchantId.value;
    } else {
      userData['merchantId'] = null;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (isEditMode.value) {
        if (editableUser.value == null) {
          errorMessage.value = "Error: No user selected for editing.";
          isLoading.value = false;
          return;
        }

        Map<String, dynamic> updatePayload = {};
        if (nameController.value.text != editableUser.value!.name) {
          updatePayload['name'] = nameController.value.text;
        }
        if (emailController.value.text != editableUser.value!.email) {
          updatePayload['email'] = emailController.value.text;
        }
        if (selectedRole.value != editableUser.value!.roleAsEnum) {
          updatePayload['role'] = userRoleToString(selectedRole.value!);
        }

        if (selectedRole.value == UserRole.staff) {
          if (selectedMerchantId.value != editableUser.value!.merchantId) {
            updatePayload['merchantId'] = selectedMerchantId.value;
          }
        } else {
          if (editableUser.value!.merchantId != null) {
            updatePayload['merchantId'] = null;
          }
        }
        if (isActive.value != editableUser.value!.isActive) {
          updatePayload['isActive'] = isActive.value;
        }

        if (updatePayload.isEmpty && passwordController.value.text.isEmpty) {
          DialogUtils.showInfo("No changes detected.");
          isLoading.value = false;
          return;
        }

        if (passwordController.value.text.isNotEmpty) {
          updatePayload['password'] = passwordController.value.text;
        }

        final updatedUser = await adminUserService.updateUser(
          editableUser.value!.id,
          updatePayload,
        );
        if (updatedUser != null) {
          fetchUsers(page: currentPage.value);
          DialogUtils.showSuccess(
            "User updated successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          if (Get.isDialogOpen ?? false) Get.back();
          if (Get.isBottomSheetOpen ?? false) Get.back();
        } else {
          errorMessage.value = "Failed to update user.";
        }
      } else {
        // Create User
        if (passwordController.value.text.isEmpty) {
          DialogUtils.showError(
            "Password is required for new user.",
            title: "Validation Error",
          );
          isLoading.value = false;
          return;
        }
        userData['password'] = passwordController.value.text;
        userData['isActive'] = isActive.value;
        final createdUser = await adminUserService.createUser(userData);
        if (createdUser != null) {
          fetchUsers(page: 1);
          DialogUtils.showSuccess(
            "User created successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          if (Get.isDialogOpen ?? false) Get.back();
          if (Get.isBottomSheetOpen ?? false) Get.back();
        } else {
          errorMessage.value = "Failed to create user.";
        }
      }
    } catch (e) {
      printError(info: e.toString());
      errorMessage.value = "Error saving user: ${e.toString()}";
      DialogUtils.showError(
        "Failed to save user: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleUserActivation(User user) async {
    bool confirmed = false;
    String actionText = user.isActive ? "deactivate" : "activate";
    Color actionColor = user.isActive ? Colors.red : Colors.green;

    confirmed =
        await DialogUtils.showCustomDialog<bool>(
          dialog: AlertDialog(
            title: Text("Confirm ${actionText.capitalizeFirstLetter()}"),
            content: Text(
              "Are you sure you want to $actionText user '${user.name}'?",
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text(
                  actionText.capitalizeFirstLetter(),
                  style: TextStyle(color: actionColor),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    isLoading.value = true;
    try {
      if (user.isActive) {
        // CORRECTED HERE: Changed deactivateUser to deleteUser
        final success = await adminUserService.deleteUser(user.id);
        if (success) {
          fetchUsers(page: currentPage.value);
          DialogUtils.showSuccess(
            "User deactivated successfully.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          errorMessage.value =
              "Failed to deactivate user."; // Service already shows a snackbar
        }
      } else {
        final activatedUser = await adminUserService.activateUser(user.id);
        if (activatedUser != null) {
          fetchUsers(page: currentPage.value);
          DialogUtils.showSuccess(
            "User activated successfully.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          errorMessage.value =
              "Failed to activate user."; // Service already shows a snackbar
        }
      }
    } catch (e) {
      printError(info: e.toString());
      DialogUtils.showError(
        "Failed to update user status: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> hardDeleteUser(String userId) async {
    bool confirmed =
        await DialogUtils.showCustomDialog<bool>(
          dialog: AlertDialog(
            title: const Text("Confirm Permanent Deletion"),
            content: const Text(
              "Are you sure you want to PERMANENTLY DELETE this user? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text(
                  "DELETE PERMANENTLY",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    isLoading.value = true;
    try {
      final success = await adminUserService.hardDeleteUser(userId);
      if (success) {
        fetchUsers(
          page: currentPage.value,
        ); // Consider fetching page 1 or staying on current
        DialogUtils.showSuccess(
          "User permanently deleted.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        errorMessage.value =
            "Failed to permanently delete user."; // Service will show specific error
        // DialogUtils.showError(errorMessage.value!); // Service handles this
      }
    } catch (e) {
      printError(info: e.toString());
      errorMessage.value = "Error deleting user: ${e.toString()}";
      DialogUtils.showError(errorMessage.value!);
    } finally {
      isLoading.value = false;
    }
  }

  // --- UI Helpers / Event Handlers ---
  void onPageChanged(int newPage) {
    if (newPage > 0 && newPage <= totalPages && newPage != currentPage.value) {
      fetchUsers(page: newPage);
    }
  }

  void applyFilters() {
    fetchUsers(page: 1);
  }

  void clearFilters() {
    selectedRoleFilter.value = null;
    selectedStatusFilter.value = null;
    searchController.clear();
    fetchUsers(page: 1);
  }

  String userRoleToString(UserRole role) {
    return role.name.toUpperCase();
  }
}
