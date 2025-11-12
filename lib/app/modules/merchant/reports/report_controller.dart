import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/report_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/data/services/report_api_service.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';

class ReportController extends GetxController {
  final ReportApiService _reportApiService = Get.find<ReportApiService>();
  final ShopApiService _shopApiService = Get.find<ShopApiService>();
  final InventoryApiService _inventoryApiService = Get.find<InventoryApiService>();

  var shops = <Shop>[].obs;
  var inventoryItems = <InventoryItem>[].obs;
  var selectedShop = Rxn<Shop>();
  var selectedItem = Rxn<InventoryItem>();
  var isLoading = false.obs;
  var isLoadingShops = true.obs;
  var isLoadingItems = false.obs;

  var forecastResponse = Rxn<SalesForecastResponse>();

  @override
  void onInit() {
    super.onInit();
    fetchShops();
  }

  Future<void> fetchShops() async {
    try {
      isLoadingShops.value = true;
      final result = await _shopApiService.listShops();
      shops.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', 'Could not load shops: $e');
    } finally {
      isLoadingShops.value = false;
    }
  }

  Future<void> fetchInventoryItems() async {
    if (selectedShop.value == null) return;
    try {
      isLoadingItems.value = true;
      final result = await _inventoryApiService.listInventoryItems(page: 1, pageSize: 500);
      if (result != null) { // Corrected: Added null check
        inventoryItems.assignAll(result.items);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not load inventory items: $e');
    } finally {
      isLoadingItems.value = false;
    }
  }

  Future<void> generateReport() async {
    if (selectedShop.value == null || selectedItem.value == null) {
      Get.snackbar('Missing Selection', 'Please select both a shop and an item.');
      return;
    }
    try {
      isLoading.value = true;
      // Corrected: Added null assertions
      final result = await _reportApiService.getSalesForecast(selectedShop.value!.id!, selectedItem.value!.id!);
      forecastResponse.value = result;
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate report: $e');
      forecastResponse.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
