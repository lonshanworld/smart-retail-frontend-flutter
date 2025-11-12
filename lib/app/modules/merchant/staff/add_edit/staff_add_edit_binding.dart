import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/merchant_staff_api_service.dart';
import 'package:smart_retail/app/modules/merchant/staff/add_edit/staff_add_edit_controller.dart';

class StaffAddEditBinding extends Bindings {
  @override
  void dependencies() {
    // The API service is already registered by the list view, so we just need the controller.
    Get.lazyPut<StaffAddEditController>(() => StaffAddEditController());
  }
}
