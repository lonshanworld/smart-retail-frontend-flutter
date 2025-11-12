import 'package:get/get.dart';
import 'package:smart_retail/app/modules/shop_items/shop_items_controller.dart';

class ShopItemsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopItemsController>(
      () => ShopItemsController(),
    );
  }
}
