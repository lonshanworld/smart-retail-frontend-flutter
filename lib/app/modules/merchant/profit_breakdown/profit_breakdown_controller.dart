import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/constants/currency.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/report_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/data/services/merchant_stocks_api_service.dart';
import 'package:smart_retail/app/data/services/report_api_service.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

enum ProfitPeriod { day, week, month, year }

class ProfitBreakdownController extends GetxController {
  final ReportApiService _reportApiService = Get.find<ReportApiService>();
  final ShopApiService _shopApiService = Get.find<ShopApiService>();
  final MerchantShopsApiService _shopsApiService =
      Get.find<MerchantShopsApiService>();
  final MerchantStocksApiService _stocksApiService =
      Get.find<MerchantStocksApiService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxInt currentPage = 1.obs;
  final RxInt pageSize = 10.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalPages = 0.obs;
  final RxList<Sale> allSales = <Sale>[].obs;
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
      final page = currentPage.value;
      getLogger(
        'app',
      ).info('[ProfitBreakdown] Fetching sales for ${selectedPeriod.value}');

      final results = await Future.wait([
        _reportApiService.getSalesReport(
          startDate: range.$1,
          endDate: range.$2,
          allowMockData: false,
        ),
        _reportApiService.getSalesReportPage(
          startDate: range.$1,
          endDate: range.$2,
          page: page,
          pageSize: pageSize.value,
          allowMockData: false,
        ),
        _stocksApiService.getCombinedStocks(page: 1, pageSize: 1000),
      ]);

      final fullResult = results[0] as SalesReportResponse;
      final pagedResult = results[1] as PaginatedSalesResponse;
      final stockResult = results[2] as PaginatedStockResponse;

      allSales.assignAll(
        fullResult.sales
          ..sort((left, right) => right.saleDate.compareTo(left.saleDate)),
      );
      sales.assignAll(
        pagedResult.items
          ..sort((left, right) => right.saleDate.compareTo(left.saleDate)),
      );
      if (!_appConfig.localStorageOnly) {
        await _hydrateMissingSaleItems();
      }
      totalItems.value = pagedResult.totalItems;
      totalPages.value = pagedResult.totalPages;
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
    currentPage.value = 1;
    applyFilters();
  }

  Future<void> goToPage(int page) async {
    if (page <= 0 || page == currentPage.value) {
      return;
    }
    if (totalPages.value > 0 && page > totalPages.value) {
      return;
    }
    currentPage.value = page;
    await applyFilters();
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
      allSales.fold(0.0, (sum, sale) => sum + sale.totalAmount);

  double get totalDiscounts =>
      allSales.fold(0.0, (sum, sale) => sum + (sale.discountAmount ?? 0.0));

  double get totalDeliveryCharges =>
      allSales.fold(0.0, (sum, sale) => sum + sale.deliveryCharge);

  double get totalGrossProfit =>
      allSales.fold(0.0, (sum, sale) => sum + orderGrossProfit(sale));

  double get averageOrderProfit =>
      allSales.isEmpty ? 0.0 : totalGrossProfit / allSales.length;

  double get averageOrderValue =>
      allSales.isEmpty ? 0.0 : totalRevenue / allSales.length;

  int get totalSalesCount => allSales.length;

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

  Future<void> _hydrateMissingSaleItems() async {
    final missingSaleIds = <String>{
      ...allSales.where((sale) => sale.items.isEmpty).map((sale) => sale.id),
      ...sales.where((sale) => sale.items.isEmpty).map((sale) => sale.id),
    };

    if (missingSaleIds.isEmpty) {
      return;
    }

    final details = await Future.wait(
      missingSaleIds.map((saleId) async {
        final sale = await _shopApiService.getSaleById(saleId);
        return MapEntry(saleId, sale);
      }),
    );

    final hydratedById = <String, Sale>{};
    for (final entry in details) {
      final sale = entry.value;
      if (sale != null && sale.items.isNotEmpty) {
        hydratedById[entry.key] = sale;
      }
    }

    if (hydratedById.isEmpty) {
      return;
    }

    allSales.assignAll(
      allSales.map((sale) => hydratedById[sale.id] ?? sale).toList(),
    );
    sales.assignAll(
      sales.map((sale) => hydratedById[sale.id] ?? sale).toList(),
    );
  }

  String formatMoney(double value) {
    return NumberFormat.currency(symbol: currencySymbol).format(value);
  }
}
