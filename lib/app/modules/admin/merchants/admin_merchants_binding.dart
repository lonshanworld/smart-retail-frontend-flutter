// lib/app/modules/admin/merchants/admin_merchants_binding.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/admin_merchant_service.dart';
import 'admin_merchants_controller.dart';

class AdminMerchantsBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure AdminMerchantService is registered, if not already globally
    // If AdminMerchantService is already registered globally (e.g., in main.dart or another binding),
    // this explicit lazyPut might not be necessary, Get.find() would work.
    // However, including it here makes the module more self-contained.
    Get.lazyPut<AdminMerchantService>(() => AdminMerchantService());

    Get.lazyPut<AdminMerchantsController>(() {
      return AdminMerchantsController(adminMerchantService: Get.find());
    });
  }
}
