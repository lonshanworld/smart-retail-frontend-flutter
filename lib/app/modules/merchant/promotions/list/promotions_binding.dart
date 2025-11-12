import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/promotion_api_service.dart';
import 'package:smart_retail/app/modules/merchant/promotions/list/promotions_controller.dart';

class PromotionsBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure the correct, new service is used here.
    Get.lazyPut<PromotionApiService>(() => PromotionApiService());
    Get.lazyPut<PromotionsController>(() => PromotionsController());
  }
}
