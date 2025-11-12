import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import './merchant_stocks_controller.dart';

class MerchantStocksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryApiService>(() => InventoryApiService());
    Get.lazyPut<MerchantStocksController>(
      () => MerchantStocksController(),
    );
  }
}
