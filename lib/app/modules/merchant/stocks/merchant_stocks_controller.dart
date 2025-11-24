import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class MerchantStocksController extends GetxController {
  final InventoryApiService _inventoryApiService =
      Get.find<InventoryApiService>();

  final RxList<InventoryItem> inventoryItems = <InventoryItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchInventoryItems();
  }

  Future<void> fetchInventoryItems() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      print('[MerchantStocks] Fetching inventory items...');
      final response = await _inventoryApiService.listInventoryItems();
      print(
        '[MerchantStocks] Response received: ${response != null ? '${response.items.length} items' : 'null'}',
      );
      if (response != null) {
        inventoryItems.assignAll(response.items);
        print('[MerchantStocks] Items assigned: ${inventoryItems.length}');
      } else {
        inventoryItems.assignAll([]);
      }
    } catch (e) {
      print('[MerchantStocks] Error: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToAddItemPage() async {
    final result = await Get.toNamed(Routes.MERCHANT_INVENTORY_ADD);
    // Refresh the list if item was created
    if (result == true) {
      await fetchInventoryItems();
    }
  }

  void goToMoveStockPage() {
    Get.toNamed(Routes.MERCHANT_STOCK_MOVE);
  }
}
