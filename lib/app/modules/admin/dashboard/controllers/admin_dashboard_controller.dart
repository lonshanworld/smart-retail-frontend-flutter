import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/modules/admin/dashboard/models/admin_dashboard_summary_model.dart'; // <<< CORRECTED IMPORT
import 'package:smart_retail/app/data/services/admin_dashboard_service.dart';

class AdminDashboardController extends GetxController {
  final AdminDashboardApiService _apiService =
      Get.find<AdminDashboardApiService>();

  // Observable for loading state
  final RxBool isLoading = true.obs;

  // Observable for the dashboard summary data
  final Rx<AdminDashboardSummaryModel?> summaryData =
      Rx<AdminDashboardSummaryModel?>(null);

  // Observable for error messages
  final RxnString errorMessage = RxnString(null);

  @override
  void onInit() {
    super.onInit();
    fetchDashboardSummary();
  }

  Future<void> fetchDashboardSummary() async {
    try {
      isLoading.value = true;
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Added delay for mock
      errorMessage.value = null; // Clear previous errors
      final data = await _apiService.getAdminDashboardSummary();
      if (data != null) {
        summaryData.value = data;
      } else {
        errorMessage.value =
            "Failed to load dashboard data. Service returned null.";
      }
    } catch (e) {
      print(
        'Error in AdminDashboardController fetching summary: ${e.toString()}',
      );
      errorMessage.value = 'An unexpected error occurred: ${e.toString()}';
      DialogUtils.showError(
        'Failed to load dashboard summary: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void refreshDashboard() {
    fetchDashboardSummary();
  }
}
