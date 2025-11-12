// lib/app/modules/admin/shops/admin_shops_binding.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/shops/admin_shops_controller.dart';
// import 'package:smart_retail/app/data/services/shop_api_service.dart'; // Optional

class AdminShopsBinding extends Bindings {
  @override
  void dependencies() {
    // Assuming ShopApiService is globally registered (e.g., in main.dart or a global AppBinding)
    // If not, and it's needed by AdminShopsController directly via Get.find() in constructor,
    // ensure it's available. For now, AdminShopsController doesn't auto-find it in constructor.
    
    Get.lazyPut<AdminShopsController>(
      () => AdminShopsController(),
    );
  }
}
