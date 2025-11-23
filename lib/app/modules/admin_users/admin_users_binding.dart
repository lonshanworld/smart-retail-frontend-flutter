import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/admin_user_service.dart';
import 'package:smart_retail/app/modules/admin_users/admin_users_controller.dart';

class AdminUsersBinding extends Bindings {
  @override
  void dependencies() {
    // Register AdminUserService.
    // It's a GetxService, so 'permanent: true' is typical if you want it to persist.
    // If it's only used within this module and its children, permanent: false might be okay,
    // but services are often permanent.
    Get.lazyPut<AdminUserService>(
      () => AdminUserService(),
      fenix:
          true, // fenix: true allows recreation if Get.find() fails after it's disposed
    );

    Get.lazyPut<AdminUsersController>(
      () =>
          AdminUsersController(adminUserService: Get.find<AdminUserService>()),
    );
  }
}
