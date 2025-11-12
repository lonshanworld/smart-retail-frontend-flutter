import 'package:get/get.dart';
import './merchant_dashboard_controller.dart';

class MerchantDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MerchantDashboardController>(
      () => MerchantDashboardController(),
    );
    // We might also put an ApiService here if it's specific or heavily used by this module
    // Get.lazyPut<ApiService>(() => ApiService());
  }
}
