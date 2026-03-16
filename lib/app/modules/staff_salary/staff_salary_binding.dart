import 'package:get/get.dart';
import './staff_salary_controller.dart';

class StaffSalaryBinding extends Bindings {
  @override
  void dependencies() {
    // StaffApiService is already registered by StaffProfileBinding, so we don't re-register it.
    // We can directly use Get.find() in the controller.
    Get.lazyPut<StaffSalaryController>(() => StaffSalaryController());
  }
}
