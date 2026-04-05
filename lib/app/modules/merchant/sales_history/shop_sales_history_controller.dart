import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class ShopSalesHistoryController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>();

  late final String shopId;
  late final String shopName;

  var sales = <Sale>[].obs;
  var isLoading = true.obs;
  var errorMessage = RxnString();

  // Pagination
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var isLoadingMore = false.obs;
  final int _pageSize = 15; // Number of sales to fetch per page

  ShopSalesHistoryController() {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    shopId = args['shopId'] as String;
    shopName = args['shopName'] as String? ?? 'Sales History';
  }

  @override
  void onInit() {
    super.onInit();
    fetchSalesHistory();
  }

  Future<void> fetchSalesHistory({bool initialLoad = true}) async {
    if (initialLoad) {
      isLoading(true);
      currentPage.value = 1; // Reset to first page for initial load or refresh
      sales.clear(); // Clear existing sales for a fresh load
    } else {
      if (isLoadingMore.value || currentPage.value >= totalPages.value) return;
      isLoadingMore(true);
    }
    errorMessage.value = null;

    try {
      final response = await _shopApiService.listSalesForShop(
        shopId,
        page: currentPage.value,
        pageSize: _pageSize,
      );

      if (response != null) {
        sales.addAll(response.items);
        totalPages.value = response.totalPages;
        if (!initialLoad && response.items.isNotEmpty) {
          currentPage
              .value++; // Increment current page if more items were loaded
        }
      } else {
        errorMessage.value = "Failed to fetch sales history.";
        if (initialLoad) {
          sales.clear(); // Ensure list is empty on error during initial load
        }
      }
    } catch (e) {
      getLogger('app').info("Error fetching sales history for shop $shopId: $e");
      errorMessage.value = "An error occurred. Please try again.";
      if (initialLoad) sales.clear();
    } finally {
      if (initialLoad) isLoading(false);
      isLoadingMore(false);
    }
  }

  // Call this method when user scrolls to the end of the list
  void loadMoreSales() {
    if (!isLoading.value &&
        !isLoadingMore.value &&
        currentPage.value < totalPages.value) {
      fetchSalesHistory(initialLoad: false);
    }
  }

  // Method to refresh the sales history
  Future<void> refreshSalesHistory() async {
    await fetchSalesHistory(initialLoad: true);
  }
}

