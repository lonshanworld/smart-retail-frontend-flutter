import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/staff_api_service.dart';
import './staff_profile_controller.dart';

class StaffProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffApiService>(() => StaffApiService());
    Get.lazyPut<StaffProfileController>(() => StaffProfileController());
  }
}
