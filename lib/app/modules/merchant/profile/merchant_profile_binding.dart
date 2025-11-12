import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/merchant_profile_api_service.dart';
import 'package:smart_retail/app/modules/merchant/profile/merchant_profile_controller.dart';

class MerchantProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MerchantProfileApiService>(() => MerchantProfileApiService());
    Get.lazyPut<MerchantProfileController>(() => MerchantProfileController());
  }
}
