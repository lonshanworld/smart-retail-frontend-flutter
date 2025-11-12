import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/admin_user_service.dart';
import 'package:smart_retail/app/modules/admin/users/add_edit/add_edit_user_admin_controller.dart';

class AddEditUserAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminUserService>(() => AdminUserService());
    Get.lazyPut<AddEditUserAdminController>(
      () => AddEditUserAdminController(),
    );
  }
}
