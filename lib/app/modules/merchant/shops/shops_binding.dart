import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/modules/merchant/shops/shops_controller.dart';

class ShopsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MerchantShopsApiService>(() => MerchantShopsApiService());
    // Correcting the type to match the actual class name from shops_controller.dart
    Get.lazyPut<MerchantShopsController>(() => MerchantShopsController());
  }
}
