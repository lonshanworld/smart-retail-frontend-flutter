import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/data/services/shop_profile_api_service.dart';

class ShopProfileController extends GetxController {
  final ShopProfileApiService _apiService = Get.find<ShopProfileApiService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxBool isLoading = true.obs;
  final Rxn<User> user = Rxn<User>();
  final Rxn<Shop> shop = Rxn<Shop>();

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      final result = await _apiService.getUserProfile(); 
      user.value = result;
      shop.value = _authService.currentShop.value;
    } catch (e) {
      Get.snackbar('Error', 'Could not load profile: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
