import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/constants/currency.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/data/services/merchant_stocks_api_service.dart';
import 'package:smart_retail/app/data/services/report_api_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

enum ProfitPeriod { day, week, month, year }

class ProfitBreakdownController extends GetxController {
  final ReportApiService _reportApiService = Get.find<ReportApiService>();
  final MerchantShopsApiService _shopsApiService =
      Get.find<MerchantShopsApiService>();
  final MerchantStocksApiService _stocksApiService =
      Get.find<MerchantStocksApiService>();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxList<Sale> sales = <Sale>[].obs;
  final RxList<Shop> shops = <Shop>[].obs;
  final RxList<InventoryItem> inventoryItems = <InventoryItem>[].obs;
  final Rx<ProfitPeriod> selectedPeriod = ProfitPeriod.week.obs;
  final String? focusSaleId = Get.arguments is String
      ? Get.arguments as String
      : null;

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
      getLogger('app').info('[ProfitBreakdown] Could not load shops: $e');
    }
  }

  Future<void> applyFilters() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final range = _calculateDateRange();
      getLogger(
        'app',
      ).info('[ProfitBreakdown] Fetching sales for ${selectedPeriod.value}');

      final result = await _reportApiService.getSalesReport(
        startDate: range.$1,
        endDate: range.$2,
        allowMockData: false,
      );

      final stockResult = await _stocksApiService.getCombinedStocks(
        page: 1,
        pageSize: 1000,
      );

      sales.assignAll(
        result.sales
          ..sort((left, right) => right.saleDate.compareTo(left.saleDate)),
      );
      inventoryItems.assignAll(stockResult.items);
    } catch (e, stackTrace) {
      getLogger('app').info('[ProfitBreakdown] Error: $e');
      getLogger('app').info('[ProfitBreakdown] Stack trace: $stackTrace');
      errorMessage.value = e.toString();
      DialogUtils.showInfo('Failed to load profit breakdown: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onPeriodChanged(ProfitPeriod? period) {
    if (period == null) {
      return;
    }
    selectedPeriod.value = period;
    applyFilters();
  }

  (DateTime, DateTime) _calculateDateRange() {
    final now = DateTime.now();
    switch (selectedPeriod.value) {
      case ProfitPeriod.day:
        return (now.subtract(const Duration(days: 1)), now);
      case ProfitPeriod.week:
        return (now.subtract(const Duration(days: 7)), now);
      case ProfitPeriod.month:
        return (now.subtract(const Duration(days: 30)), now);
      case ProfitPeriod.year:
        return (now.subtract(const Duration(days: 365)), now);
    }
  }

  String periodLabel(ProfitPeriod period) {
    switch (period) {
      case ProfitPeriod.day:
        return '24 Hours';
      case ProfitPeriod.week:
        return '7 Days';
      case ProfitPeriod.month:
        return '30 Days';
      case ProfitPeriod.year:
        return 'Year';
    }
  }

  String shopNameFor(Sale sale) {
    for (final shop in shops) {
      if (shop.id == sale.shopId) {
        return shop.name;
      }
    }
    return sale.shopId;
  }

  double get totalRevenue =>
      sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);

  double get totalDiscounts =>
      sales.fold(0.0, (sum, sale) => sum + (sale.discountAmount ?? 0.0));

  double get totalDeliveryCharges =>
      sales.fold(0.0, (sum, sale) => sum + sale.deliveryCharge);

  double get totalGrossProfit =>
      sales.fold(0.0, (sum, sale) => sum + orderGrossProfit(sale));

  double get averageOrderProfit =>
      sales.isEmpty ? 0.0 : totalGrossProfit / sales.length;

  double get averageOrderValue =>
      sales.isEmpty ? 0.0 : totalRevenue / sales.length;

  Map<String, InventoryItem> get _inventoryById {
    return {
      for (final item in inventoryItems)
        if (item.id != null && item.id!.isNotEmpty) item.id!: item,
    };
  }

  double _fallbackCostForItem(String inventoryItemId) {
    final inventoryItem = _inventoryById[inventoryItemId];
    if (inventoryItem == null) {
      return 0.0;
    }
    return inventoryItem.originalPrice;
  }

  double orderGrossProfit(Sale sale) {
    return sale.items.fold(0.0, (sum, item) => sum + lineProfit(item));
  }

  double lineRevenue(SaleItem item) => item.subtotal;

  double lineCost(SaleItem item) {
    final costPerUnit =
        item.originalPriceAtSale ?? _fallbackCostForItem(item.inventoryItemId);
    return costPerUnit * item.quantitySold;
  }

  double lineProfit(SaleItem item) {
    final costPerUnit =
        item.originalPriceAtSale ?? _fallbackCostForItem(item.inventoryItemId);
    return (item.sellingPriceAtSale - costPerUnit) * item.quantitySold;
  }

  double lineMargin(SaleItem item) {
    final revenue = lineRevenue(item);
    if (revenue <= 0) {
      return 0.0;
    }
    return lineProfit(item) / revenue;
  }

  String formatMoney(double value) {
    return NumberFormat.currency(symbol: currencySymbol).format(value);
  }
}
