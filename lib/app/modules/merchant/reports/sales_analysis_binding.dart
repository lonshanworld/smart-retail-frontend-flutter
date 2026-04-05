import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/data/services/merchant_stocks_api_service.dart';
import 'package:smart_retail/app/data/services/sales_analysis_api_service.dart';
import 'package:smart_retail/app/modules/merchant/reports/sales_analysis_controller.dart';

class SalesAnalysisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesAnalysisApiService>(() => SalesAnalysisApiService());
    // The controller also needs the shops service to populate the filter dropdown
    Get.lazyPut<MerchantShopsApiService>(() => MerchantShopsApiService());
    Get.lazyPut<MerchantStocksApiService>(() => MerchantStocksApiService());
    Get.lazyPut<SalesAnalysisController>(() => SalesAnalysisController());
  }
}
