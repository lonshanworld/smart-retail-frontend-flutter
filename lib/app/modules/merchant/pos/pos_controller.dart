import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/cart_item_model.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/bluetooth_printer_service.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/data/services/pos_api_service.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';
import 'package:smart_retail/app/modules/shared/code_scanner/code_scanner_view.dart';
import 'dart:convert';
import 'package:smart_retail/app/utils/app_logger.dart';

class PosController extends GetxController {
  final MerchantPosApiService _posApiService =
      Get.find<MerchantPosApiService>();
  final MerchantShopsApiService _shopsApiService =
      Get.find<MerchantShopsApiService>();
  final InventoryApiService _inventoryApi = Get.find<InventoryApiService>();
  final BluetoothPrinterService _printerService =
      Get.find<BluetoothPrinterService>();

  var selectedShop = Rxn<Shop>();
  var cartItems = <CartItem>[].obs;
  var isCheckingOut = false.obs;
  var errorMessage = RxnString();
  final TextEditingController deliveryChargeController =
      TextEditingController();
  final RxDouble deliveryChargeAmount = 0.0.obs;

  var shopList = <Shop>[].obs;
  var isLoadingShops = true.obs;

  // Promotion support
  var availablePromotions = <Promotion>[].obs;
  var selectedPromotion = Rxn<Promotion>();
  var isLoadingPromotions = false.obs;

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

  // Computed properties for totals
  double get cartSubtotal =>
      cartItems.fold(0, (sum, item) => sum + item.subtotal);
  double get discountAmount {
    if (selectedPromotion.value == null) return 0.0;
    final promo = selectedPromotion.value!;

    // Check if minimum spend is met
    if (cartSubtotal < promo.minSpend) return 0.0;

    final type = promo.type.toLowerCase();
    if (type == 'percentage' || type == 'percent') {
      return cartSubtotal * (promo.value / 100);
    } else if (type == 'fixed_amount' || type == 'fixed' || type == 'amount') {
      return promo.value;
    }

    // Fallback: for unknown type, if value is positive treat as fixed amount
    if (promo.value > 0) {
      return promo.value;
    }

    return 0.0;
  }

  double get effectiveTaxRatePercent => selectedShop.value?.taxRate ?? 5.0;

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
    _loadCatalogOptions();
    fetchShops();
    // Use `ever` to react to shop selection changes.
    ever(selectedShop, (_) {
      searchProducts(initialLoad: true);
      fetchActivePromotions(); // Also fetch promotions when shop changes
    });
    // Use `debounce` to avoid sending too many search requests.
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

  CartItem? getCartItemByProductId(String productId) {
    try {
      return cartItems.firstWhere((item) => item.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  void fetchShops() async {
    try {
      isLoadingShops.value = true;
      final shops = await _shopsApiService.listShops();
      shopList.assignAll(shops);
      final previousShopId = selectedShop.value?.id;
      if (shops.isNotEmpty) {
        final refreshedSelection = previousShopId == null
            ? shops.first
            : shops.firstWhereOrNull((shop) => shop.id == previousShopId) ??
                  shops.first;
        selectedShop.value = refreshedSelection;
        _setDeliveryCharge(refreshedSelection.deliveryCharge);
      }
    } catch (e) {
      DialogUtils.showError('Could not load shops: $e');
    } finally {
      isLoadingShops.value = false;
    }
  }

  void onShopSelected(Shop? shop) async {
    getLogger('app').info('check shop $shop');
    if (shop == null) return;

    getLogger(
      'app',
    ).info('ðŸª [POS CONTROLLER] Shop changed to: ${shop.name} (${shop.id})');
    if (shop.id != selectedShop.value?.id) {
      cartItems.clear();
    }
    final freshShop = shop.id == null
        ? shop
        : await _shopsApiService.getShopById(shop.id!) ?? shop;
    selectedShop.value = freshShop;
    _setDeliveryCharge(freshShop.deliveryCharge);

    // Clear cart when shop changes
    selectedPromotion.value = null; // Clear selected promotion
    searchResults.clear();
    searchController.clear();

    // Wait for promotions to load
    await searchProducts(initialLoad: true); // Search for products
    await fetchActivePromotions(); // Fetch promotions for new shop

    getLogger('app').info(
      'ðŸ [POS CONTROLLER] Shop selection complete. Available promotions: ${availablePromotions.length}',
    );
  }

  Future<void> fetchActivePromotions() async {
    if (selectedShop.value == null || selectedShop.value!.id == null) {
      getLogger('app').info(
        'âš ï¸  [POS CONTROLLER] Cannot fetch promotions - no shop selected',
      );
      return;
    }

    getLogger('app').info(
      'ðŸ”„ [POS CONTROLLER] Fetching promotions for: ${selectedShop.value!.name} (${selectedShop.value!.id})',
    );

    late final Timer promotionsTimeoutTimer;
    var didRespond = false;
    try {
      isLoadingPromotions.value = true;
      getLogger('app').info(
        'ðŸ”„ [POS CONTROLLER] Starting promotions fetch (will warn after 12s if slow)',
      );

      // Use a cancelable Timer guarded by a local flag so the info warning
      // won't fire after a successful response (race conditions on the
      // event loop could otherwise let the callback run).
      promotionsTimeoutTimer = Timer(const Duration(seconds: 12), () {
        if (!didRespond && isLoadingPromotions.value) {
          final msg = 'Promotions load is taking longer than expected';
          getLogger('app').info('âš ï¸ [POS CONTROLLER] $msg');
          DialogUtils.showInfo(msg);
        }
      });

      final promotions = await _posApiService.getActivePromotions(
        selectedShop.value!.id!,
      );
      didRespond = true;
      availablePromotions.assignAll(promotions);
      // Cancel timeout now that we have a response
      try {
        promotionsTimeoutTimer.cancel();
      } catch (_) {}

      // Debug logging
      getLogger('app').info(
        'ðŸ“Š [POS CONTROLLER] Received ${promotions.length} promotion(s)',
      );
      if (promotions.isEmpty) {
        getLogger(
          'app',
        ).info('âš ï¸  [POS CONTROLLER] No active promotions available');
        getLogger('app').info('   Possible reasons:');
        getLogger('app').info('   1. Promotions are inactive (toggle is OFF)');
        getLogger(
          'app',
        ).info('   2. Promotions have not started yet (future start_date)');
        getLogger('app').info('   3. Promotions have expired (past end_date)');
        getLogger(
          'app',
        ).info('   4. Promotions are assigned to a different shop');
        getLogger('app').info('   5. No promotions created yet');
      } else {
        getLogger(
          'app',
        ).info('âœ… [POS CONTROLLER] Promotions loaded successfully:');
        for (var promo in promotions) {
          final typeSymbol = promo.type == 'percentage' ? '%' : '\$';
          final minSpend = promo.minSpend > 0
              ? ', min: \$${promo.minSpend.toStringAsFixed(2)}'
              : ', no minimum';
          getLogger('app').info(
            '   â€¢ ${promo.name}: ${promo.value.toStringAsFixed(0)}$typeSymbol off$minSpend',
          );
        }
      }
    } catch (e) {
      getLogger(
        'app',
      ).info('âŒ [POS CONTROLLER] Error loading promotions: $e');
      DialogUtils.showInfo('Could not load promotions: $e');
      try {
        promotionsTimeoutTimer.cancel();
      } catch (_) {}
    } finally {
      try {
        promotionsTimeoutTimer.cancel();
      } catch (_) {}
      isLoadingPromotions.value = false;
      getLogger('app').info(
        'ðŸ [POS CONTROLLER] Promotion fetch complete. isLoading: ${isLoadingPromotions.value}',
      );
    }
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

  void selectPromotion(Promotion? promo) {
    selectedPromotion.value = promo;
    // cartItems.refresh(); // Trigger UI update for totals
  }

  Future<void> searchProducts({bool initialLoad = false}) async {
    final searchTerm = searchController.text;
    if (selectedShop.value == null || selectedShop.value!.id == null) {
      searchResults.clear();
      return;
    }
    // Prevent searching with an empty term unless it's the initial load for a shop.
    if (searchTerm.isEmpty && !initialLoad) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;
    try {
      final results = await _posApiService.searchProducts(
        selectedShop.value!.id!,
        searchTerm,
        categoryId: selectedCategoryId.value,
        subcategoryId: selectedSubcategoryId.value,
        brandId: selectedBrandId.value,
      );
      searchResults.assignAll(results);
    } catch (e) {
      DialogUtils.showError(e.toString());
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
    await searchProducts();
  }

  int? _availableStockForProduct(InventoryItem product) {
    final shopId = selectedShop.value?.id;
    final stockInfo = product.stockInfo;

    if (stockInfo != null && stockInfo.isNotEmpty) {
      if (shopId != null) {
        final matchedStock = stockInfo.firstWhereOrNull(
          (stock) => stock.shopId == shopId,
        );
        if (matchedStock != null) {
          return matchedStock.quantity;
        }
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
      // cartItems[existingIndex].quantity.refresh();
    } else {
      cartItems.add(CartItem(product: product, initialQuantity: 1));
    }
    // cartItems.refresh();
    // update();
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
    // cartItems.refresh();
  }

  void decrementCartItem(CartItem cartItem) {
    if (cartItem.quantity.value > 1) {
      cartItem.quantity.value--;
    } else {
      cartItems.remove(cartItem);
    }
    // cartItems.refresh();
  }

  Future<void> handleCheckout() async {
    if (cartItems.isEmpty) {
      errorMessage.value = 'The cart cannot be empty.';
      return;
    }
    if (selectedShop.value == null || selectedShop.value!.id == null) {
      errorMessage.value = 'A shop must be selected.';
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
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'deliveryCharge': deliveryCharge,
      'appliedPromotionId': selectedPromotion.value?.id,
      'paymentType': 'cash',
      if (customerNameController.text.isNotEmpty)
        'customerName': customerNameController.text,
    };

    // Debug: log checkout payload and computed promotion details
    try {
      getLogger('app').info(
        'DEBUG: Merchant POS promotion selected: ${selectedPromotion.value?.name} (id: ${selectedPromotion.value?.id})',
      );
      getLogger('app').info(
        'DEBUG: Merchant POS discountAmount: $discountAmount, cartSubtotal: $cartSubtotal, taxAmount: $taxAmount',
      );
      final payloadJson = jsonEncode(saleData);
      getLogger(
        'app',
      ).info('DEBUG: Merchant POS checkout payload: $payloadJson');
    } catch (e) {
      getLogger('app').info('DEBUG: Failed to encode checkout payload: $e');
    }

    try {
      final Sale result = await _posApiService.checkout(
        selectedShop.value!.id!,
        saleData,
      );
      getLogger('app').info(
        'DEBUG: Merchant POS checkout response received: saleId=${result.id} total=${result.totalAmount}',
      );
      if (Get.width < 800 && (Get.isBottomSheetOpen ?? false)) {
        Get.back();
      }
      _showSuccessDialog(result);
      clearCart();
      customerNameController.clear();
      // Refresh product search results to show updated stock quantities
      searchProducts(initialLoad: searchController.text.isEmpty);
    } catch (e) {
      errorMessage.value = e.toString();
      DialogUtils.showError(e.toString());
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
                style: const TextStyle(color: Colors.green),
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
                style: const TextStyle(color: Colors.blueGrey),
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
