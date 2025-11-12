import 'package:get/get.dart';
import './salary_controller.dart';

class SalaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalaryController>(() => SalaryController());
  }
}
