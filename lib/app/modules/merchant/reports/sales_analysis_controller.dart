import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/report_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/merchant_stocks_api_service.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/data/services/report_api_service.dart'; // CORRECTED IMPORT
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/utils/app_logger.dart';
import 'package:smart_retail/app/modules/merchant/reports/report_analysis_utils.dart';

enum ReportPeriod { daily, weekly, monthly, yearly, custom }

class SalesAnalysisController extends GetxController {
  // CORRECTED: Changed to the correct API service for reports
  final ReportApiService _apiService = Get.find<ReportApiService>();
  final MerchantShopsApiService _shopsApiService =
      Get.find<MerchantShopsApiService>();
  final MerchantStocksApiService _stocksApiService =
      Get.find<MerchantStocksApiService>();

  // --- State ---
  final RxList<Sale> sales = <Sale>[].obs;
  final RxList<Shop> shops = <Shop>[].obs;
  final RxList<InventoryItem> inventoryItems = <InventoryItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxInt currentPage = 1.obs;
  final RxInt pageSize = 10.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalPages = 0.obs;

  // --- Filters ---
  final Rx<ReportPeriod> selectedPeriod = ReportPeriod.daily.obs;
  final Rxn<DateTime> customStartDate = Rxn<DateTime>();
  final Rxn<DateTime> customEndDate = Rxn<DateTime>();
  final Rxn<Shop> selectedShop = Rxn<Shop>();
  final RxString selectedGroupBy = 'daily'.obs;
  final Rxn<BusinessAnalysisSnapshot> analysisSnapshot =
      Rxn<BusinessAnalysisSnapshot>();
  final Rxn<BusinessAnalysisSnapshot> pagedAnalysisSnapshot =
      Rxn<BusinessAnalysisSnapshot>();

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    await fetchShops();
    await applyFilters();
  }

  Future<void> fetchShops() async {
    try {
      final result = await _shopsApiService.listShops();
      shops.assignAll(result);
    } catch (e) {
      DialogUtils.showError('Could not load shops: $e');
    }
  }

  Future<void> applyFilters({bool resetPage = true}) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      if (resetPage) {
        currentPage.value = 1;
      }

      var (start, end) = _calculateDateRange();

      getLogger('app').info('ðŸ“Š [SALES REPORT] Fetching report...');
      getLogger('app').info('   Period: ${selectedPeriod.value}');
      getLogger('app').info('   Start: $start');
      getLogger('app').info('   End: $end');
      getLogger(
        'app',
      ).info('   Shop: ${selectedShop.value?.name ?? "All Shops"}');
      getLogger('app').info('   Group by: ${selectedGroupBy.value}');

      final results = await Future.wait([
        _apiService.getSalesReport(
          startDate: start,
          endDate: end,
          shopId: selectedShop.value?.id,
          groupBy: selectedGroupBy.value,
        ),
        _apiService.getSalesReportPage(
          startDate: start,
          endDate: end,
          page: currentPage.value,
          pageSize: pageSize.value,
          shopId: selectedShop.value?.id,
          groupBy: selectedGroupBy.value,
        ),
        _stocksApiService.getCombinedStocks(page: 1, pageSize: 500),
        _stocksApiService.getCombinedStocks(
          page: currentPage.value,
          pageSize: pageSize.value,
        ),
      ]);

      final SalesReportResponse response = results[0] as SalesReportResponse;
      final PaginatedSalesResponse pagedResponse =
          results[1] as PaginatedSalesResponse;
      final stocks = results[2] as PaginatedStockResponse;
      final pagedStocks = results[3] as PaginatedStockResponse;

      getLogger(
        'app',
      ).info('âœ… [SALES REPORT] Received ${response.sales.length} sales');
      sales.assignAll(response.sales);
      inventoryItems.assignAll(stocks.items);
      analysisSnapshot.value = buildBusinessAnalysisSnapshot(
        sales: sales,
        inventoryItems: inventoryItems,
        startDate: start,
        endDate: end,
        shopId: selectedShop.value?.id,
        groupBy: selectedGroupBy.value,
      );
      totalItems.value = pagedResponse.totalItems;
      totalPages.value = pagedResponse.totalPages;
      pagedAnalysisSnapshot.value = buildBusinessAnalysisSnapshot(
        sales: pagedResponse.items,
        inventoryItems: pagedStocks.items,
        startDate: start,
        endDate: end,
        shopId: selectedShop.value?.id,
        groupBy: selectedGroupBy.value,
      );
    } catch (e, stackTrace) {
      getLogger('app').info('âŒ [SALES REPORT] Error: $e');
      getLogger('app').info('   Stack trace: $stackTrace');
      errorMessage.value = e.toString();
      analysisSnapshot.value = null;
      pagedAnalysisSnapshot.value = null;
      DialogUtils.showInfo('Failed to load sales report: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToPage(int page) async {
    if (page <= 0 || page == currentPage.value) {
      return;
    }
    if (totalPages.value > 0 && page > totalPages.value) {
      return;
    }
    currentPage.value = page;
    await applyFilters(resetPage: false);
  }

  void onPeriodChanged(ReportPeriod? period) {
    if (period != null) {
      selectedPeriod.value = period;
      if (period != ReportPeriod.custom) {
        applyFilters();
      }
    }
  }

  void onGroupByChanged(String? groupBy) {
    if (groupBy != null) {
      selectedGroupBy.value = groupBy;
      applyFilters();
    }
  }

  void onShopChanged(Shop? shop) {
    selectedShop.value = shop;
    applyFilters();
  }

  void goToSaleDetail(Sale sale) {
    Get.toNamed(Routes.MERCHANT_SALE_DETAIL, arguments: sale.id);
  }

  (DateTime, DateTime) _calculateDateRange() {
    final now = DateTime.now();
    switch (selectedPeriod.value) {
      case ReportPeriod.daily:
        return (now.subtract(const Duration(days: 1)), now);
      case ReportPeriod.weekly:
        return (now.subtract(const Duration(days: 7)), now);
      case ReportPeriod.monthly:
        return (DateTime(now.year, now.month - 1, now.day), now);
      case ReportPeriod.yearly:
        return (DateTime(now.year - 1, now.month, now.day), now);
      case ReportPeriod.custom:
        // Ensure custom dates are not null before returning
        return (
          customStartDate.value ?? now.subtract(const Duration(days: 1)),
          customEndDate.value ?? now,
        );
    }
  }

  Future<void> selectCustomDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (isStart ? customStartDate.value : customEndDate.value) ??
          DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      if (isStart) {
        customStartDate.value = picked;
      } else {
        customEndDate.value = picked;
      }
      // Automatically apply if both dates are set
      if (customStartDate.value != null && customEndDate.value != null) {
        applyFilters();
      }
    }
  }
}
