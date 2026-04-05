import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import 'package:smart_retail/app/data/services/shop_profile_api_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class ShopProfileController extends GetxController {
  final ShopProfileApiService _apiService = Get.find<ShopProfileApiService>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final ShopApiService _shopApiService = Get.find<ShopApiService>();

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
      if (_appConfig.localStorageOnly) {
        final shopId =
            await _authService.getShopId() ?? result.assignedShopId ?? '';
        if (shopId.isEmpty) {
          shop.value = null;
        } else {
          shop.value = await _shopApiService.getShopById(shopId);
        }
      } else {
        shop.value = _authService.currentShop.value;
      }
    } catch (e) {
      DialogUtils.showError('Could not load profile: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
