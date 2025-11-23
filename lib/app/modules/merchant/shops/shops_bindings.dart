import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import 'package:smart_retail/app/modules/merchant/shops/shops_controller.dart';
import './shop_add_edit_controller.dart';

// Binding for the main list of shops
class ShopsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MerchantShopsApiService>(() => MerchantShopsApiService());
    // Correcting the type to match the actual class name from shops_controller.dart
    Get.lazyPut<MerchantShopsController>(() => MerchantShopsController());
  }
}

// Separate binding for the Add/Edit page
class ShopAddEditBinding extends Bindings {
  @override
  void dependencies() {
    // This controller requires the ShopApiService for creating/updating a single shop
    Get.lazyPut<ShopApiService>(() => ShopApiService());
    Get.lazyPut<ShopAddEditController>(() => ShopAddEditController());
  }
}
