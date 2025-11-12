import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/salary_model.dart';
import 'package:smart_retail/app/data/services/staff_api_service.dart';

class StaffSalaryController extends GetxController {
  final StaffApiService _apiService = Get.find<StaffApiService>();

  final RxBool isLoading = true.obs;
  final RxList<Salary> salaryHistory = <Salary>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSalaryHistory();
  }

  Future<void> fetchSalaryHistory() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final history = await _apiService.getSalaryHistory();
      salaryHistory.assignAll(history);
    } catch (e) {
      errorMessage.value = 'Failed to load salary history: $e';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }
}
