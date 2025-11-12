import 'package:get/get.dart';
import 'package:smart_retail/app/modules/merchant/ai_sales_analysis/ai_sales_analysis_controller.dart';

class AiSalesAnalysisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiSalesAnalysisController>(
      () => AiSalesAnalysisController(),
    );
  }
}
