import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/staff_pos_api_service.dart';
import './staff_pos_controller.dart';

class StaffPosBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffPosApiService>(() => StaffPosApiService());
    Get.lazyPut<StaffPosController>(() => StaffPosController());
  }
}
