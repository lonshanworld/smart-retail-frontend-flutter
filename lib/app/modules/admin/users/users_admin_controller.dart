// lib/app/modules/admin/users/users_admin_controller.dart
import 'package:flutter/material.dart'; // Added for AlertDialog
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/user_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/utils/string_extensions.dart'; // Provides Routes class
import 'package:smart_retail/app/utils/app_logger.dart';

class UsersAdminController extends GetxController {
  final UserApiService _userApiService = Get.find<UserApiService>();

  final RxList<User> users = <User>[].obs;
  final RxBool isLoading = true.obs; // General loading for the list
  final RxBool isUpdatingStatus =
      false.obs; // Specific loading for status update
  final RxnString errorMessage = RxnString();
  final RxString selectedRoleFilter = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers({String? role}) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final roleToFetch =
          role ??
          (selectedRoleFilter.value.isEmpty ? null : selectedRoleFilter.value);
      getLogger('app').info(
        "UsersAdminController: Fetching users with role filter: $roleToFetch",
      );
      final fetchedUsers = await _userApiService.getUsers(
        roleFilter: roleToFetch,
      );
      users.assignAll(fetchedUsers);
      getLogger('app').info("UsersAdminController: Fetched ${users.length} users.");
    } catch (e) {
      getLogger('app').info("UsersAdminController: Error fetching users: $e");
      errorMessage.value = "Error fetching users: ${e.toString()}";
      users.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void applyRoleFilter(String? role) {
    selectedRoleFilter.value = role ?? '';
    fetchUsers();
  }

  void goToAddUserPage() {
    getLogger('app').info("UsersAdminController: Navigating to Add/Edit User Page in ADD mode");
    Get.toNamed(Routes.ADMIN_ADD_EDIT_USER);
  }

  void goToEditUserPage(User user) {
    getLogger('app').info(
      "UsersAdminController: Navigating to Add/Edit User Page for ${user.name} in EDIT mode",
    );
    Get.toNamed(Routes.ADMIN_ADD_EDIT_USER, arguments: user);
  }

  void goToUserDetailsPage(User user) {
    getLogger('app').info(
      "UsersAdminController: Navigating to User Details Page for ${user.name}",
    );
    Get.toNamed(Routes.ADMIN_USER_DETAIL, arguments: user.id);
  }

  Future<void> deleteUser(String userId, String userName) async {
    bool? confirmDelete = await DialogUtils.showCustomDialog<bool>(
      dialog: AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete user "$userName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      getLogger('app').info("UsersAdminController: Attempting to delete user $userId");
      isLoading.value = true;
      try {
        await _userApiService.deleteUser(userId);
        DialogUtils.showSuccess("User $userName deleted successfully.");
        fetchUsers(); // Refresh the list
      } catch (e) {
        getLogger('app').info("UsersAdminController: Error deleting user $userId: $e");
        DialogUtils.showError(
          "Failed to delete user $userName: ${e.toString()}",
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  // --- NEW METHOD TO TOGGLE USER STATUS ---
  Future<void> toggleUserStatus(User user) async {
    final newStatus = !user.isActive;
    final actionText = newStatus ? "activate" : "deactivate";

    bool? confirmToggle = await DialogUtils.showCustomDialog<bool>(
      dialog: AlertDialog(
        title: Text('Confirm ${actionText.capitalizeFirstLetter()}'),
        content: Text(
          'Are you sure you want to $actionText user "${user.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              actionText.capitalizeFirstLetter(),
              style: TextStyle(color: newStatus ? Colors.green : Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmToggle == true) {
      getLogger('app').info("UsersAdminController: Attempting to $actionText user ${user.id}");
      isUpdatingStatus.value = true;
      try {
        await _userApiService.updateUser(user.id, {'isActive': newStatus});
        DialogUtils.showSuccess(
          "User ${user.name} ${actionText}d successfully.",
        );
        fetchUsers();
      } catch (e) {
        getLogger('app').info(
          "UsersAdminController: Error ${actionText}ing user ${user.id}: $e",
        );
        DialogUtils.showError(
          "Failed to $actionText user ${user.name}: ${e.toString()}",
        );
      } finally {
        isUpdatingStatus.value = false;
      }
    }
  }
}

// Helper extension if not already globally available
// Ensure this is not duplicated if you have it elsewhere
// extension StringExtension on String {
//   String capitalizeFirstLetter() {
//     if (isEmpty) return this;
//     return "${this[0].toUpperCase()}${substring(1)}";
//   }
// }

