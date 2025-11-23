import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/promotion_api_service.dart';
import 'package:smart_retail/app/modules/merchant/promotions/add_edit/promotion_add_edit_controller.dart';

class PromotionAddEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PromotionApiService>(() => PromotionApiService());
    Get.lazyPut<PromotionAddEditController>(() => PromotionAddEditController());
  }
}
