import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/admin_admins_api_service.dart';
import 'package:smart_retail/app/modules/admin/admins/admins_admin_controller.dart';

class AdminsAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminAdminsApiService>(() => AdminAdminsApiService());
    Get.lazyPut<AdminsAdminController>(() => AdminsAdminController());
  }
}
