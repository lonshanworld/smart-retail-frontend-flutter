import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/admin_admins_api_service.dart';

class AdminsAdminController extends GetxController {
  final AdminAdminsApiService _apiService = Get.find<AdminAdminsApiService>();

  final RxList<User> admins = <User>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchAdmins();
  }

  Future<void> fetchAdmins() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final result = await _apiService.getAdmins();
      admins.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
