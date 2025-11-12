import 'package:get/get.dart';
import 'package:smart_retail/app/modules/shop_dashboard/shop_dashboard_controller.dart';

class ShopDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopDashboardController>(() => ShopDashboardController());
  }
}
