// lib/app/modules/admin/merchants/detail/admin_merchant_detail_binding.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/merchants/detail/admin_merchant_detail_controller.dart';
// AdminMerchantService should already be available

class AdminMerchantDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminMerchantDetailController>(
      () => AdminMerchantDetailController(
        adminMerchantService:
            Get.find(), // Relies on AdminMerchantService being found
      ),
    );
  }
}
