import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/report_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/data/services/report_api_service.dart'; // CORRECTED IMPORT
import 'package:smart_retail/app/routes/app_pages.dart';

enum ReportPeriod { daily, weekly, monthly, yearly, custom }

class SalesAnalysisController extends GetxController {
  // CORRECTED: Changed to the correct API service for reports
  final ReportApiService _apiService = Get.find<ReportApiService>();
  final MerchantShopsApiService _shopsApiService = Get.find<MerchantShopsApiService>();

  // --- State ---
  final RxList<Sale> sales = <Sale>[].obs;
  final RxList<Shop> shops = <Shop>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  // --- Filters ---
  final Rx<ReportPeriod> selectedPeriod = ReportPeriod.daily.obs;
  final Rxn<DateTime> customStartDate = Rxn<DateTime>();
  final Rxn<DateTime> customEndDate = Rxn<DateTime>();
  final Rxn<Shop> selectedShop = Rxn<Shop>();
  final RxString selectedGroupBy = 'daily'.obs;

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
      Get.snackbar('Error', 'Could not load shops: $e');
    }
  }

  Future<void> applyFilters() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      var (start, end) = _calculateDateRange();
      
      print('📊 [SALES REPORT] Fetching report...');
      print('   Period: ${selectedPeriod.value}');
      print('   Start: $start');
      print('   End: $end');
      print('   Shop: ${selectedShop.value?.name ?? "All Shops"}');
      print('   Group by: ${selectedGroupBy.value}');

      // CORRECTED: Called the correct method on the correct service
      final SalesReportResponse response = await _apiService.getSalesReport(
        startDate: start,
        endDate: end,
        shopId: selectedShop.value?.id,
        groupBy: selectedGroupBy.value,
      );
      
      print('✅ [SALES REPORT] Received ${response.sales.length} sales');
      sales.assignAll(response.sales);
    } catch (e, stackTrace) {
      print('❌ [SALES REPORT] Error: $e');
      print('   Stack trace: $stackTrace');
      errorMessage.value = e.toString();
      Get.snackbar(
        'Report Error',
        'Failed to load sales report: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
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
        return (customStartDate.value ?? now.subtract(const Duration(days: 1)), customEndDate.value ?? now);
    }
  }

  Future<void> selectCustomDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? customStartDate.value : customEndDate.value) ?? DateTime.now(),
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
