import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class ShopLoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final formKey = GlobalKey<FormState>();
  final shopIdController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var selectedRole = 'Staff'.obs;

  String get _defaultShopId =>
      dotenv.env['MOCK_SHOP_ID'] ?? '944e9452-197e-4ce1-8c6a-1ea36f0bdacc';

  void login() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      try {
        bool success = false;
        if (selectedRole.value == 'Staff') {
          shopIdController.text = _defaultShopId;
          success = await _authService.loginToShop(
            shopIdController.text,
            emailController.text,
            passwordController.text,
          );
          if (success) {
            // Both staff and merchant access the same shop, so pass shopId for both
            Get.offAllNamed(
              Routes.SHOP_DASHBOARD,
              parameters: {'shopId': shopIdController.text},
            );
          }
        } else {
          // Merchant Login
          // Login as merchant and verify shop ownership
          success = await _authService.loginMerchantToShop(
            _defaultShopId,
            emailController.text,
            passwordController.text,
          );

          if (success) {
            // Navigate to shop dashboard with shopId parameter
            final shopId = _defaultShopId;
            Get.offAllNamed(
              Routes.SHOP_DASHBOARD,
              parameters: {'shopId': shopId},
            );
          }
        }

        if (!success) {
          DialogUtils.showError(
            _authService.errorMessage.value.isNotEmpty
                ? _authService.errorMessage.value
                : 'Invalid credentials for the selected role.',
            title: 'Login Failed',
          );
        }
      } catch (e) {
        DialogUtils.showError('An unexpected error occurred: $e');
      } finally {
        isLoading.value = false;
      }
    }
  }
}
