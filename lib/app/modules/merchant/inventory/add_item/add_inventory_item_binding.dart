import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import './add_inventory_item_controller.dart';

class AddInventoryItemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryApiService>(() => InventoryApiService());
    Get.lazyPut<AddInventoryItemController>(
      () => AddInventoryItemController(),
    );
  }
}
