import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/cart_item_model.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/services/bluetooth_printer_service.dart';
import 'package:smart_retail/app/data/services/shop_pos_api_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class ShopPosController extends GetxController {
  final ShopPosApiService _apiService = Get.find<ShopPosApiService>();
  final BluetoothPrinterService _printerService =
      Get.find<BluetoothPrinterService>();

  var cartItems = <CartItem>[].obs;
  var isCheckingOut = false.obs;
  var errorMessage = RxnString();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();
  var searchResults = <InventoryItem>[].obs;
  var isSearching = false.obs;

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
    // Get shopId from route parameters
    shopId = Get.parameters['shopId'] ?? '';
    if (shopId.isEmpty) {
      DialogUtils.showError('Shop ID is required');
      return;
    }
    fetchActivePromotions();
    searchProducts(initialLoad: true);
    debounce(
      searchController.obs,
      (_) => searchProducts(),
      time: const Duration(milliseconds: 500),
    );
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

  void searchProducts({bool initialLoad = false}) async {
    final searchTerm = searchController.text;
    if (searchTerm.isEmpty && !initialLoad) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;
    try {
      final results = await _apiService.searchProducts(shopId, searchTerm);
      searchResults.assignAll(results);
    } catch (e) {
      DialogUtils.showError(e.toString(), title: 'Error Searching Products');
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
      DialogUtils.showError('Cannot checkout with an empty cart.');
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
      'paymentType': 'cash',
      if (customerNameController.text.isNotEmpty)
        'customerName': customerNameController.text,
      if (selectedPromotion.value != null && discountAmount > 0) ...{
        'discountAmount': discountAmount,
        'appliedPromotionId': selectedPromotion.value!.id,
      },
    };

    try {
      final Sale result = await _apiService.checkout(shopId, saleData);
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
            onPressed: () => _printerService.downloadVoucherPdf(
              _buildVoucherText(sale),
              filename: 'voucher-${sale.id}.pdf',
            ),
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
    voucherText += '\n--------------------------\nTotal: \$${sale.totalAmount.toStringAsFixed(2)}\n\nThank you for your purchase!';
    return voucherText;
  }

  void _printVoucher(Sale sale) {
    final voucherText = _buildVoucherText(sale);
    _printerService.printVoucher(voucherText);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
