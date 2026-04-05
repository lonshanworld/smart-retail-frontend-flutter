import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/data/services/shop_sales_api_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class ShopSalesController extends GetxController {
  final ShopSalesApiService _apiService = Get.find<ShopSalesApiService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<Sale> sales = <Sale>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;

  late String shopId;
  String? userRole;

  @override
  void onInit() {
    super.onInit();
    shopId = Get.parameters['shopId'] ?? '';
    userRole = _authService.user.value?.role;

    if (shopId.isEmpty) {
      errorMessage.value = 'Shop ID is required';
      isLoading.value = false;
      return;
    }

    fetchSales();
  }

  Future<void> fetchSales({int page = 1}) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      getLogger('app').info(
        'ðŸ”„ [SHOP SALES CONTROLLER] Fetching sales for shop: $shopId, page: $page',
      );

      final response = await _apiService.listShopSales(
        shopId,
        page: page,
        pageSize: 20,
      );

      getLogger('app').info('ðŸ“Š [SHOP SALES CONTROLLER] Response received:');
      getLogger('app').info('   - Total items in response: ${response.items.length}');
      getLogger('app').info('   - Total pages: ${response.totalPages}');
      getLogger('app').info('   - Current page: ${response.currentPage}');
      getLogger('app').info('   - Total count: ${response.totalItems}');

      for (int i = 0; i < response.items.length; i++) {
        final sale = response.items[i];
        getLogger('app').info('   ðŸ“‹ Sale #${i + 1}:');
        getLogger('app').info('      ID: ${sale.id}');
        getLogger('app').info('      Date: ${sale.saleDate}');
        getLogger('app').info('      Total: \$${sale.totalAmount}');
        getLogger('app').info('      Items count: ${sale.items.length}');
        getLogger('app').info('      Discount: \$${sale.discountAmount}');
        getLogger('app').info('      Payment Status: ${sale.paymentStatus}');

        for (int j = 0; j < sale.items.length; j++) {
          final item = sale.items[j];
          getLogger('app').info(
            '        Item #${j + 1}: Qty=${item.quantitySold}, SellingPrice=\$${item.sellingPriceAtSale}, OriginalPrice=\$${item.originalPriceAtSale}, Subtotal=\$${item.subtotal}',
          );
        }
      }

      sales.assignAll(response.items);
      currentPage.value = response.currentPage;
      totalPages.value = response.totalPages;
      totalItems.value = response.totalItems;

      getLogger('app').info('âœ… [SHOP SALES CONTROLLER] Loaded ${response.items.length} sales');
    } catch (e) {
      getLogger('app').info('âŒ [SHOP SALES CONTROLLER] Error: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void nextPage() {
    if (currentPage.value < totalPages.value) {
      fetchSales(page: currentPage.value + 1);
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      fetchSales(page: currentPage.value - 1);
    }
  }

  bool get isMerchant => userRole == 'merchant';
  bool get isStaff => userRole == 'staff';
}

