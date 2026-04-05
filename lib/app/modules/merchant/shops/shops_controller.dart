import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class MerchantShopsController extends GetxController {
  final MerchantShopsApiService _apiService =
      Get.find<MerchantShopsApiService>();

  final RxList<Shop> shopList = <Shop>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchShops();
  }

  Future<void> fetchShops() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final shops = await _apiService.listShops();
      try { getLogger('app').info('[MerchantShopsController] fetchShops returned ${shops.length} shops'); } catch (_) {}
      // Additionally dump raw local DB rows for troubleshooting localStorageOnly flows
      try {
        final localDb = Get.find<LocalDatabaseService>();
        final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
        final merchantId = auth?.user.value?.merchantId ?? '';
        final rawRows = await localDb.listShopsForMerchant(merchantId);
        try { getLogger('app').info('[MerchantShopsController] Raw local DB shops for merchantId=$merchantId: $rawRows'); } catch (_) {}
      } catch (_) {}
      shopList.assignAll(shops);
    } catch (e) {
      errorMessage.value = e.toString();
      DialogUtils.showError('Could not fetch shops: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void goToAddShop() {
    Get.toNamed(Routes.MERCHANT_SHOPS_ADD_EDIT)?.then((result) {
      if (result == true) {
        fetchShops(); // Refresh the list if a shop was added
      }
    });
  }

  void goToEditShop(Shop shop) {
    Get.toNamed(Routes.MERCHANT_SHOPS_ADD_EDIT, arguments: shop)?.then((
      result,
    ) {
      if (result == true) {
        fetchShops(); // Refresh the list if a shop was updated
      }
    });
  }

  Future<void> deleteShop(String shopId) async {
    try {
      // Optional: Show a confirmation dialog
      await _apiService.deleteShop(shopId);
      fetchShops(); // Refresh the list
      DialogUtils.showSuccess('Shop deleted successfully');
    } catch (e) {
      DialogUtils.showError('Failed to delete shop: $e');
    }
  }

  void goToShopInventory(Shop shop) {
    // Navigate to a new page showing the inventory for the selected shop
    Get.toNamed(Routes.MERCHANT_SHOP_INVENTORY, arguments: shop);
  }
}
