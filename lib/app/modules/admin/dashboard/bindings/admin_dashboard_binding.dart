// lib/app/modules/admin/dashboard/bindings/admin_dashboard_binding.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/dashboard/controllers/admin_dashboard_controller.dart';

class AdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDashboardController>(
      () => AdminDashboardController(),
    );
    // AdminDashboardApiService is already registered globally in main.dart
    // So, we don't need to put it here again.
    // The controller will find it using Get.find().
  }
}
