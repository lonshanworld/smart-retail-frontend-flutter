import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/supplier_api_service.dart';
import 'package:smart_retail/app/modules/merchant/supplier_management/supplier_management_controller.dart';

class SupplierManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupplierApiService>(() => SupplierApiService());
    Get.lazyPut<SupplierManagementController>(() => SupplierManagementController());
  }
}
