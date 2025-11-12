import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import './edit_inventory_item_controller.dart';

class EditInventoryItemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryApiService>(() => InventoryApiService());
    Get.lazyPut<EditInventoryItemController>(
      () => EditInventoryItemController(),
    );
  }
}
