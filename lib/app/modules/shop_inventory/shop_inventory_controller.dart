import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_inventory_item.dart';
import 'package:smart_retail/app/data/services/shop_inventory_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class ShopInventoryController extends GetxController {
  final ShopInventoryApiService _apiService =
      Get.find<ShopInventoryApiService>();

  final RxList<ShopInventoryItem> inventoryItems = <ShopInventoryItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  late String shopId;

  @override
  void onInit() {
    super.onInit();
    // Try to get shopId from route parameters first, then from arguments
    shopId =
        Get.parameters['shopId'] ??
        (Get.arguments is String ? Get.arguments as String : '');

    if (shopId.isEmpty) {
      errorMessage.value = 'Shop ID is required';
      isLoading.value = false;
      return;
    }

    fetchInventory();
  }

  Future<void> fetchInventory() async {
    try {
      isLoading.value = true;
      errorMessage.value = null; // Clear any previous errors
      final items = await _apiService.getShopInventory(shopId);
      inventoryItems.assignAll(items);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToAddItemToStockPage() async {
    // Navigate to the stock-in page with the shop ID
    final result = await Get.toNamed(
      Routes.MERCHANT_SHOP_STOCK_IN,
      arguments: shopId,
    );

    // If stock was added successfully, refresh the inventory
    if (result == true) {
      await fetchInventory();
    }
  }
}
