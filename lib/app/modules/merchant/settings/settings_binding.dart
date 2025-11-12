import 'package:get/get.dart';
import 'package:smart_retail/app/modules/merchant/settings/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
