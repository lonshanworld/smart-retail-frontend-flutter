import 'package:get/get.dart';
import 'package:smart_retail/app/modules/merchant/shops/shop_add_edit_controller.dart';

class ShopAddEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopAddEditController>(
      () => ShopAddEditController(),
    );
  }
}
