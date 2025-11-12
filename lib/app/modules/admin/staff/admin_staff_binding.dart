import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/admin_staff_api_service.dart';
import 'package:smart_retail/app/modules/admin/staff/admin_staff_controller.dart';

class AdminStaffBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminStaffApiService>(() => AdminStaffApiService());
    Get.lazyPut<AdminStaffController>(() => AdminStaffController());
  }
}
