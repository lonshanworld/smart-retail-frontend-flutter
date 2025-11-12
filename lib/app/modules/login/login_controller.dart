import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // No longer needed for super admin check
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';

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
      Get.snackbar(
        "Input Error",
        "Email and password cannot be empty.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange, // Changed to orange for input errors
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    // Clear previous error messages from authService, if any
    authService.errorMessage.value = ''; 

    print("[LoginController] Attempting login. Role: ${loginType ?? 'merchant'}, Email: $email");
    // For security, avoid printing the actual password here or in other frontend logs.
    // print("[LoginController] Password: $password"); 

    try {
      // All login types will now go through AuthService to call the backend
      // The 'role' parameter in authService.login corresponds to 'user_type' in the backend payload.
      bool loginSuccess = await authService.login(email, password, role: loginType ?? 'merchant');
      print('checking if reach here');
      print(loginSuccess);
      if (loginSuccess) {
        String successMessage = "Login successful!";
        String routeToNavigate = Routes.MERCHANT_DASHBOARD; // Default route

        // Determine route and success message based on the role confirmed by authService
        // It's safer to use authService.userRole.value after successful login
        // as the backend confirms the actual role.
        String? confirmedRole = authService.userRole.value;
        print("[LoginController] Login success. Role from AuthService: $confirmedRole");


        if (confirmedRole == 'admin') {
          successMessage = "Admin login successful!";
          routeToNavigate = Routes.ADMIN_DASHBOARD;
        } else if (confirmedRole == 'staff') { // Assuming 'staff_placeholder' is resolved to 'staff' by backend or during save
          successMessage = "Staff login successful!";
          // TODO: Define Routes.STAFF_DASHBOARD if it exists and is different
          routeToNavigate = Routes.STAFF_DASHBOARD; // Or Routes.STAFF_DASHBOARD
          print("[LoginController] Staff login successful, navigating to: $routeToNavigate");
        } else if (confirmedRole == 'merchant') {
          successMessage = "Merchant login successful!";
          routeToNavigate = Routes.MERCHANT_DASHBOARD;
        } else {
           // Fallback if role is somehow unexpected after successful login
          print("[LoginController] Login successful but role '$confirmedRole' has no specific route. Defaulting.");
        }

        Get.offAllNamed(routeToNavigate);
        Get.snackbar(
          "Success",
          successMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // authService.login() returned false, show error message from authService
        print("[LoginController] Login failed. Error from AuthService: ${authService.errorMessage.value}");
        Get.snackbar(
          "Login Failed",
          authService.errorMessage.value.isNotEmpty
              ? authService.errorMessage.value
              : "Invalid credentials or an unexpected error occurred.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e, stackTrace) {
      print("[LoginController] Login exception: $e");
      print("[LoginController] StackTrace: $stackTrace");
      Get.snackbar(
        "Error",
        "An unexpected error occurred during login: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
