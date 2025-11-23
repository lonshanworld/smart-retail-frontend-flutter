// lib/app/modules/staff_dashboard/staff_dashboard_binding.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/staff_dashboard/staff_dashboard_controller.dart';

class StaffDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffDashboardController>(() => StaffDashboardController());
  }
}
