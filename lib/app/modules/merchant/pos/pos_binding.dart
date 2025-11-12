import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/data/services/pos_api_service.dart'; // The file remains the same, but the class inside is now MerchantPosApiService
import 'package:smart_retail/app/modules/merchant/pos/pos_controller.dart';

class PosBinding extends Bindings {
  @override
  void dependencies() {
    // UPDATED: To provide the correctly named service
    Get.lazyPut<MerchantPosApiService>(() => MerchantPosApiService());
    
    Get.lazyPut<MerchantShopsApiService>(() => MerchantShopsApiService());
    Get.lazyPut<PosController>(() => PosController());
  }
}
