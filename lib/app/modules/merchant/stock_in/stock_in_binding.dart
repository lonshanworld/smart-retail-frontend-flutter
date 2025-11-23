import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/data/services/shop_inventory_api_service.dart';
import './stock_in_controller.dart';

class StockInBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryApiService>(() => InventoryApiService());
    Get.lazyPut<ShopInventoryApiService>(() => ShopInventoryApiService());
    Get.lazyPut<StockInController>(() => StockInController());
  }
}
