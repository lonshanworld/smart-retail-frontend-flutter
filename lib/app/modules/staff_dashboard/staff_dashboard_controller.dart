import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/staff_dashboard_model.dart';
import 'package:smart_retail/app/data/services/staff_api_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class StaffDashboardController extends GetxController {
  final StaffApiService _apiService = Get.put(StaffApiService());

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<StaffDashboardSummaryResponse?> dashboardSummary =
      Rx<StaffDashboardSummaryResponse?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchDashboardSummary();
  }

  Future<void> fetchDashboardSummary() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      getLogger('app').info('ðŸ” [STAFF DASHBOARD] Fetching dashboard summary...');
      final summary = await _apiService.getStaffDashboardSummary();
      getLogger('app').info('âœ… [STAFF DASHBOARD] Summary received: $summary');
      dashboardSummary.value = summary;
    } catch (e, stackTrace) {
      getLogger('app').info('âŒ [STAFF DASHBOARD] Error: $e');
      getLogger('app').info('ðŸ“‹ [STAFF DASHBOARD] Stack trace: $stackTrace');
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await fetchDashboardSummary();
  }
}

