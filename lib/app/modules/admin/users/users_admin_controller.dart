// lib/app/modules/admin/users/users_admin_controller.dart
import 'package:flutter/material.dart'; // Added for AlertDialog
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/user_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/utils/string_extensions.dart'; // Provides Routes class

class UsersAdminController extends GetxController {
  final UserApiService _userApiService = Get.find<UserApiService>();

  final RxList<User> users = <User>[].obs;
  final RxBool isLoading = true.obs; // General loading for the list
  final RxBool isUpdatingStatus = false.obs; // Specific loading for status update
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
      final roleToFetch = role ?? (selectedRoleFilter.value.isEmpty ? null : selectedRoleFilter.value);
      print("UsersAdminController: Fetching users with role filter: $roleToFetch");
      final fetchedUsers = await _userApiService.getUsers(roleFilter: roleToFetch);
      users.assignAll(fetchedUsers);
      print("UsersAdminController: Fetched ${users.length} users.");
    } catch (e) {
      print("UsersAdminController: Error fetching users: $e");
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
    print("UsersAdminController: Navigating to Add/Edit User Page in ADD mode");
    Get.toNamed(Routes.ADMIN_ADD_EDIT_USER);
  }

  void goToEditUserPage(User user) {
    print("UsersAdminController: Navigating to Add/Edit User Page for ${user.name} in EDIT mode");
    Get.toNamed(Routes.ADMIN_ADD_EDIT_USER, arguments: user);
  }

  void goToUserDetailsPage(User user) {
    print("UsersAdminController: Navigating to User Details Page for ${user.name}");
    Get.toNamed(Routes.ADMIN_USER_DETAIL, arguments: user.id);
  }

  Future<void> deleteUser(String userId, String userName) async {
    bool? confirmDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete user "$userName"? This action cannot be undone.'),
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
      print("UsersAdminController: Attempting to delete user $userId");
      isLoading.value = true; 
      try {
        await _userApiService.deleteUser(userId);
        Get.snackbar("Success", "User $userName deleted successfully.", snackPosition: SnackPosition.BOTTOM);
        fetchUsers(); // Refresh the list
      } catch (e) {
        print("UsersAdminController: Error deleting user $userId: $e");
        Get.snackbar("Error", "Failed to delete user $userName: ${e.toString()}", backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      } finally {
        isLoading.value = false;
      }
    }
  }

  // --- NEW METHOD TO TOGGLE USER STATUS ---
  Future<void> toggleUserStatus(User user) async {
    final newStatus = !user.isActive;
    final actionText = newStatus ? "activate" : "deactivate";

    bool? confirmToggle = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirm ${actionText.capitalizeFirstLetter()}'),
        content: Text('Are you sure you want to $actionText user "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(actionText.capitalizeFirstLetter(), style: TextStyle(color: newStatus ? Colors.green : Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmToggle == true) {
      print("UsersAdminController: Attempting to $actionText user ${user.id}");
      isUpdatingStatus.value = true; 
      try {
        await _userApiService.updateUser(user.id, {'isActive': newStatus});
        Get.snackbar(
          "Success",
          "User ${user.name} ${actionText}d successfully.",
          snackPosition: SnackPosition.BOTTOM,
        );
        fetchUsers(); 
      } catch (e) {
        print("UsersAdminController: Error ${actionText}ing user ${user.id}: $e");
        Get.snackbar(
          "Error",
          "Failed to $actionText user ${user.name}: ${e.toString()}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
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
