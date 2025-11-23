import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/users/edit/user_edit_admin_controller.dart';
import 'package:smart_retail/app/services/admin_api_service.dart';

class UserEditAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminApiService>(() => AdminApiService());
    Get.lazyPut<UserEditAdminController>(() => UserEditAdminController());
  }
}
