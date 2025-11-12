import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/shop_customers_api_service.dart';
import 'package:smart_retail/app/modules/shop_customers/shop_customers_controller.dart';
// CORRECTED: Import the controller with the correct plural name.

class ShopCustomersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopCustomersApiService>(() => ShopCustomersApiService());
    // CORRECTED: Register the controller with the correct plural name that the view expects.
    Get.lazyPut<ShopCustomersController>(
      () => ShopCustomersController(),
    );
  }
}
