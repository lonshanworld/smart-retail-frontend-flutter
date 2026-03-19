import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/merchant_dashboard_summary_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/admin_dashboard_service.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';

import 'package:smart_retail/app/utils/dialog_utils.dart';

class MerchantDashboardController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>();
  final AdminDashboardApiService _dashboardApiService =
      Get.find<AdminDashboardApiService>();

  // Observable for Shop List
  var shopList = <Shop>[].obs;
  var selectedShop = Rx<Shop?>(null);
  var isLoadingShops = true.obs;
  var shopError = Rx<String?>(null);

  // Observable for Dashboard Summary
  var dashboardSummary = Rx<MerchantDashboardSummaryModel?>(null);
  var isLoadingDashboard = false.obs; // Initially false, true when fetching
  var dashboardError = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchShops();
  }

  Future<void> fetchShops() async {
    try {
      isLoadingShops.value = true;
      shopError.value = null;
      final shops = await _shopApiService.listShops();

      shopList.assignAll(shops);
      if (shops.isNotEmpty) {
        selectedShop.value = shops.firstWhere(
          (s) => s.isPrimary == true,
          orElse: () => shops.first,
        );
      }
      await fetchDashboardData(); // Fetch data after shops are loaded and selection is made
    } catch (e) {
      shopError.value = "Failed to load shops: ${e.toString()}";
      DialogUtils.showError(shopError.value!);
      print("Error fetching shops: $e");
    } finally {
      isLoadingShops.value = false;
    }
  }

  void onShopSelected(Shop? shop) {
    selectedShop.value = shop;
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoadingDashboard.value = true;
      dashboardError.value = null;
      print(
        '[MerchantDashboardController] Fetching dashboard data for shop: ${selectedShop.value?.id}',
      );

      // Directly await the service and populate the summary. No delayed
      // slow-warning is shown on slow machines to avoid noisy popups.
      final summary = await _dashboardApiService.getMerchantDashboardSummary(
        shopId: selectedShop.value?.id,
      );
      print(
        '[MerchantDashboardController] Dashboard service returned: ${summary != null}',
      );
      dashboardSummary.value = summary;
      // Service handles snackbars for API errors.
    } catch (e, st) {
      dashboardError.value = "Failed to load dashboard data: ${e.toString()}";
      DialogUtils.showError(dashboardError.value!);
      print("Error fetching dashboard data: $e");
      print(st);
    } finally {
      isLoadingDashboard.value = false;
    }
  }
}
