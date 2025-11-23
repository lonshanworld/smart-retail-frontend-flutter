import 'package:get/get.dart';
import './shop_stock_adjust_controller.dart';

class ShopStockAdjustBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopStockAdjustController>(() => ShopStockAdjustController());
  }
}
