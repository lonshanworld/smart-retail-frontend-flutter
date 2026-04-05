import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // No longer needed for super admin check
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/utils/app_logger.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/services/local_database_service.dart';

class LoginController extends GetxController {
  final AuthService authService = Get.find<AuthService>();

  // Text Editing Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Observable for password visibility
  final RxBool isPasswordHidden = true.obs;

  // Observable for loading state
  final RxBool isLoading = false.obs;

  // Method to toggle password visibility
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login({String? loginType}) async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    // Frontend validation for empty fields
    if (email.isEmpty || password.isEmpty) {
      DialogUtils.showWarning(
        "Email and password cannot be empty.",
        title: "Input Error",
      );
      return;
    }

    isLoading.value = true;
    // Clear previous error messages from authService, if any
    authService.errorMessage.value = '';

    getLogger('app').info(
      "[LoginController] Attempting login. Role: ${loginType ?? 'merchant'}, Email: $email",
    );
    // For security, avoid printing the actual password here or in other frontend logs.
    // getLogger('app').info("[LoginController] Password: $password");

    try {
      // Debug: log local-storage-only flag and local DB status
      try {
        final localOnly = Get.find<AppConfig>().localStorageOnly;
        getLogger('app').info('AppConfig.localStorageOnly: $localOnly');
      } catch (_) {}

      getLogger('app').info('LocalDB registered=${Get.isRegistered<LocalDatabaseService>()}');
      if (Get.isRegistered<LocalDatabaseService>()) {
        try {
          final db = Get.find<LocalDatabaseService>();
          final users = await db.listAllUsers();
          getLogger('app').info('local users count: ${users.length}');
          getLogger('app').info('local users sample: ${users.isNotEmpty ? users.first : null}');
        } catch (e) {
          getLogger('app').info('Failed to list local users: $e');
        }
      }

      // All login types will now go through AuthService to call the backend
      // The 'role' parameter in authService.login corresponds to 'user_type' in the backend payload.
      bool loginSuccess = await authService.login(
        email,
        password,
        role: loginType ?? 'merchant',
      );
      getLogger('app').info('checking if reach here');
      getLogger('app').info(loginSuccess);
      if (loginSuccess) {
        String successMessage = "Login successful!";
        String routeToNavigate = Routes.MERCHANT_DASHBOARD; // Default route

        // Determine route and success message based on the role confirmed by authService
        // It's safer to use authService.userRole.value after successful login
        // as the backend confirms the actual role.
        String? confirmedRole = authService.userRole.value;
        getLogger('app').info(
          "[LoginController] Login success. Role from AuthService: $confirmedRole",
        );

        if (confirmedRole == 'admin') {
          successMessage = "Admin login successful!";
          routeToNavigate = Routes.ADMIN_DASHBOARD;
        } else if (confirmedRole == 'staff') {
          // Assuming 'staff_placeholder' is resolved to 'staff' by backend or during save
          successMessage = "Staff login successful!";
          // TODO: Define Routes.STAFF_DASHBOARD if it exists and is different
          routeToNavigate = Routes.STAFF_DASHBOARD; // Or Routes.STAFF_DASHBOARD
          getLogger('app').info(
            "[LoginController] Staff login successful, navigating to: $routeToNavigate",
          );
        } else if (confirmedRole == 'merchant') {
          successMessage = "Merchant login successful!";
          routeToNavigate = Routes.MERCHANT_DASHBOARD;
        } else {
          // Fallback if role is somehow unexpected after successful login
          getLogger('app').info(
            "[LoginController] Login successful but role '$confirmedRole' has no specific route. Defaulting.",
          );
        }

        Get.offAllNamed(routeToNavigate);
        DialogUtils.showSuccess(successMessage);
      } else {
        // authService.login() returned false, show error message from authService
        getLogger('app').info(
          "[LoginController] Login failed. Error from AuthService: ${authService.errorMessage.value}",
        );
        DialogUtils.showError(
          authService.errorMessage.value.isNotEmpty
              ? authService.errorMessage.value
              : "Invalid credentials or an unexpected error occurred.",
          title: "Login Failed",
        );
      }
    } catch (e, stackTrace) {
      getLogger('app').info("[LoginController] Login exception: $e");
      getLogger('app').info("[LoginController] StackTrace: $stackTrace");
      DialogUtils.showError(
        "An unexpected error occurred during login: ${e.toString()}",
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

