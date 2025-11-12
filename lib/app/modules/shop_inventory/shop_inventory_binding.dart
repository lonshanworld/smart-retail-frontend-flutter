import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/shop_inventory_api_service.dart';
import './shop_inventory_controller.dart';

class ShopInventoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopInventoryApiService>(() => ShopInventoryApiService());
    Get.lazyPut<ShopInventoryController>(
      () => ShopInventoryController(),
    );
  }
}
