import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/report_api_service.dart';
import './report_controller.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportApiService>(() => ReportApiService());
    Get.lazyPut<ReportController>(
      () => ReportController(),
    );
  }
}
