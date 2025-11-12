import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/shop_pos_api_service.dart';
import 'package:smart_retail/app/modules/shop_pos/shop_pos_controller.dart';

class ShopPosBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopPosApiService>(() => ShopPosApiService());
    Get.lazyPut<ShopPosController>(() => ShopPosController());
  }
}
