import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/staff_api_service.dart';

class StaffProfileController extends GetxController {
  final StaffApiService _apiService = Get.find<StaffApiService>();

  final RxBool isLoading = true.obs;
  final Rxn<User> userProfile = Rxn<User>();
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final profile = await _apiService.getStaffProfile();
      userProfile.value = profile;
    } catch (e) {
      errorMessage.value = 'Failed to load profile: $e';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }
}
