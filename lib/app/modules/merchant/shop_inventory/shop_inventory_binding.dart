import 'package:get/get.dart';
import 'package:smart_retail/app/modules/merchant/shop_inventory/shop_inventory_controller.dart';
import 'package:smart_retail/app/data/services/shop_inventory_api_service.dart';

class ShopInventoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopInventoryApiService>(() => ShopInventoryApiService(), fenix: true);


    Get.lazyPut<ShopInventoryController>(
      () => ShopInventoryController(),
    );
  }
}
