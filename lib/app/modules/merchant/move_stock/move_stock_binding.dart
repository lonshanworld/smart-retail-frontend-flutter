import 'package:get/get.dart';
import './move_stock_controller.dart';

class MoveStockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MoveStockController>(() => MoveStockController());
  }
}
