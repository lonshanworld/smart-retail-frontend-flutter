import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/dashboard/admin_dashboard_controller.dart';

class AdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDashboardController>(() => AdminDashboardController());
    // UserApiService and UsersAdminController will be handled by UsersAdminBinding
    // when the ADMIN_USERS route is accessed.
  }
}
