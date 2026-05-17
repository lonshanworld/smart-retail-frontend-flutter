import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/cart_item_model.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/data/services/bluetooth_printer_service.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import 'package:smart_retail/app/data/services/shop_pos_api_service.dart';
import 'package:smart_retail/app/modules/shared/code_scanner/code_scanner_view.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'dart:convert';
import 'package:smart_retail/app/utils/app_logger.dart';

class ShopPosController extends GetxController {
  final ShopPosApiService _apiService = Get.find<ShopPosApiService>();
  final ShopApiService _shopApiService = Get.find<ShopApiService>();
  final BluetoothPrinterService _printerService =
      Get.find<BluetoothPrinterService>();
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final InventoryApiService _inventoryApi = Get.find<InventoryApiService>();

  var cartItems = <CartItem>[].obs;
  var isCheckingOut = false.obs;
  var errorMessage = RxnString();
  final TextEditingController deliveryChargeController =
      TextEditingController();
  final RxDouble deliveryChargeAmount = 0.0.obs;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();
  var searchResults = <InventoryItem>[].obs;
  var isSearching = false.obs;

  final RxList<CategoryWithSubcategories> categories =
      <CategoryWithSubcategories>[].obs;
  final RxList<BrandRef> brands = <BrandRef>[].obs;
  final RxList<SubcategoryRef> filteredSubcategories = <SubcategoryRef>[].obs;
  final RxnString selectedCategoryId = RxnString();
  final RxnString selectedSubcategoryId = RxnString();
  final RxnString selectedBrandId = RxnString();
  final RxDouble shopTaxRate = 5.0.obs;

  // Promotion state
  var availablePromotions = <Promotion>[].obs;
  var selectedPromotion = Rxn<Promotion>();
  var isLoadingPromotions = false.obs;

  late final String shopId;

  // Computed properties for totals
  double get cartSubtotal =>
      cartItems.fold(0, (sum, item) => sum + item.subtotal);

  double get discountAmount {
    if (selectedPromotion.value == null ||
        cartSubtotal < selectedPromotion.value!.minSpend) {
      return 0.0;
    }
    final promo = selectedPromotion.value!;
    final type = promo.type.toLowerCase();
    if (type == 'percentage' || type == 'percent') {
      return cartSubtotal * (promo.value / 100);
    } else if (type == 'fixed_amount' || type == 'fixed' || type == 'amount') {
      return promo.value;
    }
    if (promo.value > 0) {
      return promo.value;
    }
    return 0.0;
  }

  double get effectiveTaxRatePercent => shopTaxRate.value;

  String get taxRateLabel {
    final rate = effectiveTaxRatePercent;
    final isWhole = rate.truncateToDouble() == rate;
    return isWhole ? rate.toStringAsFixed(0) : rate.toStringAsFixed(2);
  }

  double get taxAmount =>
      (cartSubtotal - discountAmount) * (effectiveTaxRatePercent / 100);
  double get deliveryCharge => deliveryChargeAmount.value;
  double get cartTotal =>
      cartSubtotal - discountAmount + taxAmount + deliveryCharge;

  @override
  void onInit() {
    super.onInit();
    // Get shopId from route parameters
    shopId = Get.parameters['shopId'] ?? '';
    if (shopId.isEmpty) {
      DialogUtils.showError('Shop ID is required');
      return;
    }
    _loadCatalogOptions();
    _loadShopContext();
    fetchActivePromotions();
    searchProducts(initialLoad: true);
    debounce(
      searchController.obs,
      (_) => searchProducts(),
      time: const Duration(milliseconds: 500),
    );
  }

  Future<void> _loadCatalogOptions() async {
    final opts = await _inventoryApi.getCatalogOptions();
    if (opts == null) return;
    categories.assignAll(opts.categories);
    brands.assignAll(opts.brands);
  }

  Future<void> _loadShopContext() async {
    if (!_appConfig.localStorageOnly) {
      shopTaxRate.value = _authService.currentShop.value?.taxRate ?? 5.0;
      _setDeliveryCharge(_authService.currentShop.value?.deliveryCharge ?? 0.0);
      return;
    }

    final freshShop = await _shopApiService.getShopById(shopId);
    if (freshShop == null) {
      shopTaxRate.value = 5.0;
      _setDeliveryCharge(0.0);
      return;
    }

    shopTaxRate.value = freshShop.taxRate;
    _setDeliveryCharge(freshShop.deliveryCharge);
  }

  void setCategoryFilter(String? categoryId) {
    selectedCategoryId.value = categoryId;
    selectedSubcategoryId.value = null;
    final cat = categories.firstWhereOrNull((c) => c.id == categoryId);
    filteredSubcategories.assignAll(cat?.subcategories ?? const []);
  }

  void clearFilters() {
    selectedCategoryId.value = null;
    selectedSubcategoryId.value = null;
    selectedBrandId.value = null;
    filteredSubcategories.clear();
    searchProducts(initialLoad: true);
  }

  Future<void> fetchActivePromotions() async {
    isLoadingPromotions.value = true;
    try {
      final promotions = await _apiService.getActivePromotions(shopId: shopId);
      availablePromotions.assignAll(promotions);
    } catch (e) {
      DialogUtils.showError(e.toString(), title: 'Error Loading Promotions');
    } finally {
      isLoadingPromotions.value = false;
    }
  }

  void selectPromotion(Promotion? promotion) {
    selectedPromotion.value = promotion;
  }

  void updateDeliveryCharge(String value) {
    final parsedValue =
        double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;
    deliveryChargeAmount.value = parsedValue;
  }

  void _setDeliveryCharge(double value) {
    deliveryChargeAmount.value = value;
    deliveryChargeController.text = value.toStringAsFixed(2);
  }

  CartItem? getCartItemByProductId(String productId) {
    try {
      return cartItems.firstWhere((item) => item.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  void searchProducts({bool initialLoad = false}) async {
    final searchTerm = searchController.text;
    if (searchTerm.isEmpty && !initialLoad) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;
    try {
      final results = await _apiService.searchProducts(
        shopId,
        searchTerm,
        categoryId: selectedCategoryId.value,
        subcategoryId: selectedSubcategoryId.value,
        brandId: selectedBrandId.value,
      );
      searchResults.assignAll(results);
    } catch (e) {
      DialogUtils.showError(e.toString(), title: 'Error Searching Products');
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> scanAndSearchProducts() async {
    final scannedCode = await Get.to<String>(() => const CodeScannerView());
    if (scannedCode == null || scannedCode.isEmpty) {
      return;
    }

    searchController.text = scannedCode;
    searchProducts();
  }

  int? _availableStockForProduct(InventoryItem product) {
    final stockInfo = product.stockInfo;

    if (stockInfo != null && stockInfo.isNotEmpty) {
      final matchedStock = stockInfo.firstWhereOrNull(
        (stock) => stock.shopId == shopId,
      );
      if (matchedStock != null) {
        return matchedStock.quantity;
      }

      if (stockInfo.length == 1) {
        return stockInfo.first.quantity;
      }
    }

    return null;
  }

  void _showStockLimitWarning(InventoryItem product, int available) {
    final message = available <= 0
        ? '${product.name} is out of stock for this shop.'
        : 'Only $available unit${available == 1 ? '' : 's'} of ${product.name} left in this shop.';
    DialogUtils.showWarning(
      message,
      title: 'Stock is gone',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  bool _canIncreaseQuantity(InventoryItem product, int requestedQuantity) {
    final available = _availableStockForProduct(product);
    return available == null || requestedQuantity <= available;
  }

  void addToCart(InventoryItem product) {
    final existingIndex = cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );
    final requestedQuantity = existingIndex != -1
        ? cartItems[existingIndex].quantity.value + 1
        : 1;
    if (!_canIncreaseQuantity(product, requestedQuantity)) {
      _showStockLimitWarning(product, _availableStockForProduct(product) ?? 0);
      return;
    }
    if (existingIndex != -1) {
      cartItems[existingIndex].quantity.value++;
      cartItems[existingIndex].quantity.refresh();
    } else {
      cartItems.add(CartItem(product: product, initialQuantity: 1));
    }
    cartItems.refresh();
    update();
  }

  void clearCart() {
    cartItems.clear();
  }

  void incrementCartItem(CartItem cartItem) {
    final requestedQuantity = cartItem.quantity.value + 1;
    if (!_canIncreaseQuantity(cartItem.product, requestedQuantity)) {
      _showStockLimitWarning(
        cartItem.product,
        _availableStockForProduct(cartItem.product) ?? 0,
      );
      return;
    }
    cartItem.quantity.value++;
    cartItems.refresh();
  }

  void decrementCartItem(CartItem cartItem) {
    if (cartItem.quantity.value > 1) {
      cartItem.quantity.value--;
    } else {
      cartItems.remove(cartItem);
    }
    cartItems.refresh();
  }

  Future<void> handleCheckout() async {
    if (cartItems.isEmpty) {
      DialogUtils.showError('Cannot checkout with an empty cart.');
      return;
    }

    for (final item in cartItems) {
      final available = _availableStockForProduct(item.product);
      if (available != null && item.quantity.value > available) {
        _showStockLimitWarning(item.product, available);
        errorMessage.value = 'Cart quantity exceeds available stock.';
        return;
      }
    }

    isCheckingOut.value = true;
    errorMessage.value = null;

    final saleData = {
      'items': cartItems
          .map(
            (item) => {
              'productId': item.product.id,
              'quantity': item.quantity.value,
              'sellingPriceAtSale': item.product.sellingPrice,
            },
          )
          .toList(),
      'totalAmount': cartTotal,
      'taxAmount': taxAmount,
      'deliveryCharge': deliveryCharge,
      'paymentType': 'cash',
      if (customerNameController.text.isNotEmpty)
        'customerName': customerNameController.text,
      if (selectedPromotion.value != null && discountAmount > 0) ...{
        'discountAmount': discountAmount,
        'appliedPromotionId': selectedPromotion.value!.id,
      },
    };

    // Debug: log checkout payload
    try {
      final payloadJson = jsonEncode(saleData);
      getLogger('app').info('DEBUG: Shop POS checkout payload: $payloadJson');
    } catch (e) {
      getLogger('app').info('DEBUG: Failed to encode checkout payload: $e');
    }

    try {
      final Sale result = await _apiService.checkout(shopId, saleData);
      getLogger('app').info(
        'DEBUG: Shop POS checkout response received: saleId=${result.id} total=${result.totalAmount}',
      );
      if (Get.width < 800 && (Get.isBottomSheetOpen ?? false)) {
        Get.back();
      }
      _showSuccessDialog(result);
      clearCart();
      customerNameController.clear();
    } catch (e) {
      errorMessage.value = e.toString();
      DialogUtils.showError(e.toString(), title: 'Checkout Failed');
    } finally {
      isCheckingOut.value = false;
    }
  }

  void _showSuccessDialog(Sale sale) {
    DialogUtils.showCustomDialog(
      dialog: AlertDialog(
        title: const Text('Thank You!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your purchase has been completed successfully.'),
            const SizedBox(height: 20),
            Text('Sale ID: ${sale.id}'),
            if (sale.discountAmount != null && sale.discountAmount! > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Discount: -\$${sale.discountAmount!.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.success),
              ),
            ],
            Text(
              'Total: \$${sale.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sale.deliveryCharge > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Delivery Charge: \$${sale.deliveryCharge.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.success),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          TextButton(
            onPressed: () => _printerService.downloadSaleVoucherPdf(sale),
            child: const Text('Download PDF'),
          ),
          TextButton(
            onPressed: () => _printVoucher(sale),
            child: const Text('Print Voucher'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  String _buildVoucherText(Sale sale) {
    String voucherText =
        '''Sale Voucher\nSale ID: ${sale.id}\nDate: ${sale.saleDate.toLocal().toString().substring(0, 16)}\n--------------------------\nItems:\n''';
    for (var item in sale.items) {
      voucherText += ' - ${item.itemName} x${item.quantitySold}\n';
    }
    if (sale.deliveryCharge > 0) {
      voucherText +=
          'Delivery Charge: \$${sale.deliveryCharge.toStringAsFixed(2)}\n';
    }
    voucherText +=
        '\n--------------------------\nTotal: \$${sale.totalAmount.toStringAsFixed(2)}\n\nThank you for your purchase!';
    return voucherText;
  }

  void _printVoucher(Sale sale) {
    _printerService.printSaleVoucher(sale);
  }

  @override
  void onClose() {
    searchController.dispose();
    customerNameController.dispose();
    deliveryChargeController.dispose();
    super.onClose();
  }
}
