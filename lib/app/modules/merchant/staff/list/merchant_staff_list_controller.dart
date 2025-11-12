import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/merchant_staff_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class MerchantStaffListController extends GetxController {
  final MerchantStaffApiService _apiService = Get.find<MerchantStaffApiService>();

  final RxList<User> staffList = <User>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final response = await _apiService.listStaff();
      staffList.assignAll(response.staff);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void goToAddStaff() {
    Get.toNamed(Routes.MERCHANT_STAFF_ADD)?.then((result) {
      // If a result is returned (e.g., a new staff was created), refresh the list
      if (result == true) {
        fetchStaff();
      }
    });
  }

  void goToEditStaff(User staff) {
    Get.toNamed(Routes.MERCHANT_STAFF_EDIT, arguments: staff)?.then((result) {
      if (result == true) {
        fetchStaff();
      }
    });
  }

  void goToStaffDetails(User staff) {
    Get.toNamed(Routes.MERCHANT_STAFF_DETAIL, arguments: staff);
  }

  Future<void> deleteStaff(String staffId) async {
    try {
      // Show a confirmation dialog
      await Get.defaultDialog(
        title: 'Confirm Deletion',
        middleText: 'Are you sure you want to delete this staff member?',
        textConfirm: 'Delete',
        textCancel: 'Cancel',
        onConfirm: () async {
          Get.back(); // Close dialog
          await _apiService.deleteStaff(staffId);
          staffList.removeWhere((staff) => staff.id == staffId);
          Get.snackbar('Success', 'Staff member deleted.');
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete staff member: ${e.toString()}');
    }
  }
}
