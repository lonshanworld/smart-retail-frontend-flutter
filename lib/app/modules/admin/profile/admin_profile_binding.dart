import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/admin_profile_api_service.dart';
import 'package:smart_retail/app/modules/admin/profile/admin_profile_controller.dart';

class AdminProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminProfileApiService>(() => AdminProfileApiService());
    Get.lazyPut<AdminProfileController>(() => AdminProfileController());
  }
}
