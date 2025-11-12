import 'package:get/get.dart';
import './inventory_controller.dart';

class InventoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryController>(() => InventoryController());
  }
}
