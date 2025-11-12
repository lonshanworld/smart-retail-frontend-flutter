import 'package:get/get.dart';
import './staff_shop_controller.dart';

class StaffShopBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffShopController>(() => StaffShopController());
  }
}
