// lib/app/modules/admin/users/users_admin_binding.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/users/users_admin_controller.dart';

class UsersAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UsersAdminController>(
      () => UsersAdminController(),
    );
  }
}
