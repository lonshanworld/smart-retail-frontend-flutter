import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/data/services/merchant_stocks_api_service.dart';
import 'package:smart_retail/app/modules/merchant/profit_breakdown/profit_breakdown_controller.dart';

class ProfitBreakdownBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MerchantShopsApiService>(() => MerchantShopsApiService());
    Get.lazyPut<MerchantStocksApiService>(() => MerchantStocksApiService());
    Get.lazyPut<ProfitBreakdownController>(() => ProfitBreakdownController());
  }
}
