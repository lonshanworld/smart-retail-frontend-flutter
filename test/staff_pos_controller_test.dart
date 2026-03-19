import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/staff_pos/staff_pos_controller.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/cart_item_model.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StaffPosController logic', () {
    setUp(() {
      // Ensure no services are registered; tests only exercise pure controller logic.
      Get.reset();
    });

    test('discount calculation - percentage promo', () {
      final controller = StaffPosController();

      final item = InventoryItem(
        id: 'p1',
        merchantId: 'm1',
        name: 'Item 1',
        sellingPrice: 50.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      controller.cartItems.add(
        CartItem(product: item, initialQuantity: 2),
      ); // subtotal 100

      final promo = Promotion(
        id: 'promo1',
        merchantId: 'm1',
        shopId: null,
        name: '10% off',
        description: 'Ten percent off',
        type: 'percentage',
        value: 10.0,
        minSpend: 0.0,
        conditions: {},
        startDate: null,
        endDate: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      controller.selectedPromotion.value = promo;

      // discount: 10% of 100 = 10
      expect(controller.cartSubtotal, 100);
      expect(controller.discountAmount, closeTo(10.0, 0.001));
      // tax = (100 - 10) * 0.05 = 4.5
      expect(controller.taxAmount, closeTo(4.5, 0.001));
      // total = 100 - 10 + 4.5 = 94.5
      expect(controller.cartTotal, closeTo(94.5, 0.001));
    });

    test('buildSalePayload includes promotion fields when applicable', () {
      final controller = StaffPosController();

      final item = InventoryItem(
        id: 'p2',
        merchantId: 'm1',
        name: 'Item 2',
        sellingPrice: 20.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      controller.cartItems.add(
        CartItem(product: item, initialQuantity: 3),
      ); // subtotal 60

      controller.customerNameController.text = 'Alice';

      final promo = Promotion(
        id: 'promo_fixed',
        merchantId: 'm1',
        shopId: null,
        name: '5 off',
        description: 'Fixed 5 off',
        type: 'fixed_amount',
        value: 5.0,
        minSpend: 0.0,
        conditions: {},
        startDate: null,
        endDate: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      controller.selectedPromotion.value = promo;

      final payload = controller.buildSalePayload();
      expect(payload['items'], isNotNull);
      expect(payload['totalAmount'], isNotNull);
      expect(payload['paymentType'], 'cash');
      expect(payload['customerName'], 'Alice');
      expect(payload['discountAmount'], isNotNull);
      expect(payload['appliedPromotionId'], 'promo_fixed');
    });
  });
}

// No backend or Bluetooth mocks: unit tests exercise controller logic only.
