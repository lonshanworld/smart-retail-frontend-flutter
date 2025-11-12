import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/admin_staff_api_service.dart';

class AdminStaffController extends GetxController {
  final AdminStaffApiService _apiService = Get.find<AdminStaffApiService>();

  final RxList<User> staff = <User>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchAllStaff();
  }

  Future<void> fetchAllStaff() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final result = await _apiService.getAllStaff();
      staff.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
