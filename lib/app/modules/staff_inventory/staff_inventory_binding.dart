import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/staff_inventory_api_service.dart';
import 'package:smart_retail/app/modules/staff_inventory/staff_inventory_controller.dart';

class StaffInventoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffInventoryApiService>(() => StaffInventoryApiService());
    Get.lazyPut<StaffInventoryController>(() => StaffInventoryController());
  }
}
