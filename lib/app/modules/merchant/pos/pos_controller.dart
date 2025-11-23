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
import 'package:smart_retail/app/data/services/pos_api_service.dart';
import 'package:smart_retail/app/data/services/merchant_shops_api_service.dart';

class PosController extends GetxController {
  final MerchantPosApiService _posApiService =
      Get.find<MerchantPosApiService>();
  final MerchantShopsApiService _shopsApiService =
      Get.find<MerchantShopsApiService>();
  final BluetoothPrinterService _printerService =
      Get.find<BluetoothPrinterService>();

  var selectedShop = Rxn<Shop>();
  var cartItems = <CartItem>[].obs;
  var isCheckingOut = false.obs;
  var errorMessage = RxnString();

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

  // Computed properties for totals
  double get cartSubtotal =>
      cartItems.fold(0, (sum, item) => sum + item.subtotal);
  double get discountAmount {
    if (selectedPromotion.value == null) return 0.0;
    final promo = selectedPromotion.value!;

    // Check if minimum spend is met
    if (cartSubtotal < promo.minSpend) return 0.0;

    if (promo.type == 'percentage') {
      return cartSubtotal * (promo.value / 100);
    } else if (promo.type == 'fixed_amount') {
      return promo.value;
    }
    return 0.0;
  }

  double get taxAmount =>
      (cartSubtotal - discountAmount) * 0.05; // 5% tax on discounted amount
  double get cartTotal => cartSubtotal - discountAmount + taxAmount;

  @override
  void onInit() {
    super.onInit();
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

  void fetchShops() async {
    try {
      isLoadingShops.value = true;
      final shops = await _shopsApiService.listShops();
      shopList.assignAll(shops);
      if (shops.isNotEmpty) {
        selectedShop.value = shops.first;
      }
    } catch (e) {
      DialogUtils.showError('Could not load shops: $e');
    } finally {
      isLoadingShops.value = false;
    }
  }

  void onShopSelected(Shop? shop) async {
    print('check shop $shop');
    if (shop == null) return;

    print('🏪 [POS CONTROLLER] Shop changed to: ${shop.name} (${shop.id})');
    if (shop.id != selectedShop.value?.id) {
      cartItems.clear();
    }
    selectedShop.value = shop;

    // Clear cart when shop changes
    selectedPromotion.value = null; // Clear selected promotion
    searchResults.clear();
    searchController.clear();

    // Wait for promotions to load
    await searchProducts(initialLoad: true); // Search for products
    await fetchActivePromotions(); // Fetch promotions for new shop

    print(
      '🏁 [POS CONTROLLER] Shop selection complete. Available promotions: ${availablePromotions.length}',
    );
  }

  Future<void> fetchActivePromotions() async {
    if (selectedShop.value == null || selectedShop.value!.id == null) {
      print('⚠️  [POS CONTROLLER] Cannot fetch promotions - no shop selected');
      return;
    }

    print(
      '🔄 [POS CONTROLLER] Fetching promotions for: ${selectedShop.value!.name} (${selectedShop.value!.id})',
    );

    Timer? _promotionsTimeoutTimer;
    var _didRespond = false;
    try {
      isLoadingPromotions.value = true;
      print('🔄 [POS CONTROLLER] Starting promotions fetch (will warn after 12s if slow)');

      // Use a cancelable Timer guarded by a local flag so the info warning
      // won't fire after a successful response (race conditions on the
      // event loop could otherwise let the callback run).
      _promotionsTimeoutTimer = Timer(const Duration(seconds: 12), () {
        if (!_didRespond && isLoadingPromotions.value) {
          final msg = 'Promotions load is taking longer than expected';
          print('⚠️ [POS CONTROLLER] $msg');
          DialogUtils.showInfo(msg);
        }
      });

      final promotions = await _posApiService.getActivePromotions(selectedShop.value!.id!);
      _didRespond = true;
      availablePromotions.assignAll(promotions);
      // Cancel timeout now that we have a response
      try {
        if (_promotionsTimeoutTimer != null) { _promotionsTimeoutTimer!.cancel(); }
      } catch (_) {}

      // Debug logging
      print('📊 [POS CONTROLLER] Received ${promotions.length} promotion(s)');
      if (promotions.isEmpty) {
        print('⚠️  [POS CONTROLLER] No active promotions available');
        print('   Possible reasons:');
        print('   1. Promotions are inactive (toggle is OFF)');
        print('   2. Promotions have not started yet (future start_date)');
        print('   3. Promotions have expired (past end_date)');
        print('   4. Promotions are assigned to a different shop');
        print('   5. No promotions created yet');
      } else {
        print('✅ [POS CONTROLLER] Promotions loaded successfully:');
        for (var promo in promotions) {
          final typeSymbol = promo.type == 'percentage' ? '%' : '\$';
          final minSpend = promo.minSpend > 0
              ? ', min: \$${promo.minSpend.toStringAsFixed(2)}'
              : ', no minimum';
          print(
            '   • ${promo.name}: ${promo.value.toStringAsFixed(0)}$typeSymbol off$minSpend',
          );
        }
      }
    } catch (e) {
      print('❌ [POS CONTROLLER] Error loading promotions: $e');
      DialogUtils.showInfo('Could not load promotions: $e');
      try {
        if (_promotionsTimeoutTimer != null) { _promotionsTimeoutTimer!.cancel(); }
      } catch (_) {}
    } finally {
      try {
        if (_promotionsTimeoutTimer != null) { _promotionsTimeoutTimer!.cancel(); }
      } catch (_) {}
      isLoadingPromotions.value = false;
      print(
        '🏁 [POS CONTROLLER] Promotion fetch complete. isLoading: ${isLoadingPromotions.value}',
      );
    }
  }

  void selectPromotion(Promotion? promo) {
    selectedPromotion.value = promo;
    cartItems.refresh(); // Trigger UI update for totals
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
      );
      searchResults.assignAll(results);
    } catch (e) {
      DialogUtils.showError(e.toString());
    } finally {
      isSearching.value = false;
    }
  }

  void addToCart(InventoryItem product) {
    final existingIndex = cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex != -1) {
      cartItems[existingIndex].quantity.value++;
    } else {
      cartItems.add(CartItem(product: product, initialQuantity: 1));
    }
    cartItems.refresh();
  }

  void clearCart() {
    cartItems.clear();
  }

  void incrementCartItem(CartItem cartItem) {
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
      errorMessage.value = 'The cart cannot be empty.';
      return;
    }
    if (selectedShop.value == null || selectedShop.value!.id == null) {
      errorMessage.value = 'A shop must be selected.';
      return;
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
      'appliedPromotionId': selectedPromotion.value?.id,
      'paymentType': 'cash',
      if (customerNameController.text.isNotEmpty)
        'customerName': customerNameController.text,
    };

    try {
      final Sale result = await _posApiService.checkout(
        selectedShop.value!.id!,
        saleData,
      );
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          TextButton(
            onPressed: () => _printVoucher(sale),
            child: const Text('Print Voucher'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _printVoucher(Sale sale) {
    String voucherText =
        '''
      *** SALE VOUCHER ***
      Sale ID: ${sale.id}
      Date: ${sale.saleDate.toLocal().toString().substring(0, 16)}
      --------------------------
      Items:
''';
    for (var item in sale.items) {
      voucherText += '      - ${item.itemName} x${item.quantitySold}\n';
    }
    voucherText +=
        '''
      --------------------------
      Total: \$${sale.totalAmount.toStringAsFixed(2)}

      Thank you for your purchase!
      ''';

    _printerService.printVoucher(voucherText);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
