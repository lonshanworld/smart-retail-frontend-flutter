// lib/app/modules/admin/merchants/add_edit_merchant/admin_add_edit_merchant_binding.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/merchants/add_edit_merchant/admin_add_edit_merchant_controller.dart';
// AdminMerchantService should already be available via AdminMerchantsBinding or globally.

class AdminAddEditMerchantBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminAddEditMerchantController>(
      () => AdminAddEditMerchantController(
        adminMerchantService: Get.find(), // Relies on AdminMerchantService being found
      ),
    );
  }
}
