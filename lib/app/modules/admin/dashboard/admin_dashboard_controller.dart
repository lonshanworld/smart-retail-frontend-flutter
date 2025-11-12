import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/admin_dashboard_summary_model.dart';
import 'package:smart_retail/app/services/admin_api_service.dart';

class AdminDashboardController extends GetxController {
  final AdminApiService _apiService = Get.put(AdminApiService());

  // Observables for dashboard summary data
  final RxBool isLoadingSummary = true.obs;
  final Rx<AdminDashboardSummary?> summary = Rx<AdminDashboardSummary?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchDashboardSummary();
  }

  Future<void> fetchDashboardSummary() async {
    try {
      isLoadingSummary.value = true;
      final result = await _apiService.getAdminDashboardSummary();
      summary.value = result;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not load dashboard summary. ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingSummary.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await fetchDashboardSummary();
  }
}
