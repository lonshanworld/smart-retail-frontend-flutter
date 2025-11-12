import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/staff_items_api_service.dart';
import './staff_items_controller.dart';

class StaffItemsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffItemsApiService>(() => StaffItemsApiService());
    Get.lazyPut<StaffItemsController>(() => StaffItemsController());
  }
}
