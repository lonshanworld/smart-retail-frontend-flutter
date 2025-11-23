import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/user_api_service.dart';

class UserDetailAdminController extends GetxController {
  final UserApiService _userApiService = Get.find<UserApiService>();

  final RxBool isLoading = true.obs;
  final Rxn<User> user = Rxn<User>(); // Using Rxn for nullable User
  final RxnString errorMessage = RxnString(); // For displaying errors

  late String _userId;

  @override
  void onInit() {
    super.onInit();
    // Get userId from arguments passed during navigation
    if (Get.arguments is String) {
      _userId = Get.arguments as String;
      fetchUserDetails();
    } else if (Get.arguments is User) {
      // If a full User object is passed (e.g., from list item directly)
      User passedUser = Get.arguments as User;
      _userId = passedUser.id;
      user.value = passedUser; // Use the passed user directly
      isLoading.value = false; // No need to fetch if we have it
      // Optionally, still call fetchUserDetails() to ensure data is fresh if needed
      // fetchUserDetails();
    } else {
      printError(
        info:
            "UserDetailAdminController: userId not provided or invalid argument type.",
      );
      errorMessage.value = "User ID not found. Cannot load details.";
      isLoading.value = false;
    }
  }

  Future<void> fetchUserDetails() async {
    isLoading.value = true;
    errorMessage.value = null; // Clear previous error
    try {
      final fetchedUser = await _userApiService.getUserById(_userId);
      user.value = fetchedUser;
    } catch (e) {
      printError(info: "Error fetching user details: $e");
      errorMessage.value = e.toString();
      user.value = null; // Clear user data on error
    } finally {
      isLoading.value = false;
    }
  }

  // Placeholder for edit navigation
  // void goToEditUserPage() {
  //   if (user.value != null) {
  //     Get.toNamed(Routes.ADMIN_EDIT_USER, arguments: user.value); // Example route
  //   } else {
  //     DialogUtils.showError("User data not available to edit.");
  //   }
  // }
}
