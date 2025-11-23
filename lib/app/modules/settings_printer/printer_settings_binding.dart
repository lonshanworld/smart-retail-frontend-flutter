import 'package:get/get.dart';
import 'package:smart_retail/app/modules/settings_printer/printer_settings_controller.dart';

class PrinterSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrinterSettingsController>(() => PrinterSettingsController());
  }
}
