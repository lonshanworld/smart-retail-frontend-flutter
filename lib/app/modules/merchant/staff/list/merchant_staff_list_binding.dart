import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/merchant_staff_api_service.dart';
import 'package:smart_retail/app/modules/merchant/staff/list/merchant_staff_list_controller.dart';

class MerchantStaffListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MerchantStaffApiService>(() => MerchantStaffApiService());
    Get.lazyPut<MerchantStaffListController>(() => MerchantStaffListController());
  }
}
