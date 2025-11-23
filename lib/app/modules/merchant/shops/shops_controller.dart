import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
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
