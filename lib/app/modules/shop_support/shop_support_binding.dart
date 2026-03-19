import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/shop_support_api_service.dart';
import 'package:smart_retail/app/modules/shop_support/shop_support_controller.dart';

class ShopSupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopSupportApiService>(() => ShopSupportApiService());
    Get.lazyPut<ShopSupportController>(() => ShopSupportController());
  }
}
