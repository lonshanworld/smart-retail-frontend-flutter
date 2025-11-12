import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class StaffDetailController extends GetxController {
  final Rxn<User> staff = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is User) {
      staff.value = Get.arguments as User;
    } else {
      // Handle error case where staff data is missing
      Get.back();
      Get.snackbar('Error', 'Could not load staff details.');
    }
  }

  void goToEditStaff() {
    if (staff.value != null) {
      Get.toNamed(Routes.MERCHANT_STAFF_EDIT, arguments: staff.value);
    }
  }
}
