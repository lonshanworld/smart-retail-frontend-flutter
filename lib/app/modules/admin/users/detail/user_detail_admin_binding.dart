import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/users/detail/user_detail_admin_controller.dart';

class UserDetailAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserDetailAdminController>(
      () => UserDetailAdminController(),
    );
  }
}
