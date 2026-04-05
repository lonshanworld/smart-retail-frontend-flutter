import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/data/services/merchant_stocks_api_service.dart';
import 'package:smart_retail/app/data/services/report_api_service.dart';
import 'package:smart_retail/app/modules/merchant/business_analysis/business_analysis_controller.dart';

class BusinessAnalysisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportApiService>(() => ReportApiService());
    Get.lazyPut<MerchantShopsApiService>(() => MerchantShopsApiService());
    Get.lazyPut<MerchantStocksApiService>(() => MerchantStocksApiService());
    Get.lazyPut<BusinessAnalysisController>(() => BusinessAnalysisController());
  }
}
