import 'package:get/get.dart';
import 'package:smart_retail/app/modules/shop_profile/shop_profile_controller.dart';

class ShopProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopProfileController>(() => ShopProfileController());
  }
}
