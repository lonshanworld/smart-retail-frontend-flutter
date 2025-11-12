import 'package:get/get.dart';
import './shop_stock_controller.dart';
import './stock_in_controller.dart';
import './stock_adjustment_controller.dart'; // Import the new controller

class ShopStockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopStockController>(() => ShopStockController());
  }
}

class StockInBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StockInController>(() => StockInController());
  }
}

class StockAdjustmentBinding extends Bindings {
  @override
  void dependencies() {
    // StockAdjustmentController handles arguments in its constructor.
    Get.lazyPut<StockAdjustmentController>(() => StockAdjustmentController());
  }
}
