import 'package:get/get.dart';
import 'package:smart_retail/app/modules/merchant/staff/detail/staff_detail_controller.dart';

class StaffDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffDetailController>(() => StaffDetailController());
  }
}
