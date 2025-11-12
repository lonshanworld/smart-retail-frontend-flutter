import 'package:get/get.dart';
import 'package:smart_retail/app/modules/shop_settings/shop_settings_controller.dart';

class ShopSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopSettingsController>(
      () => ShopSettingsController(),
    );
  }
}
