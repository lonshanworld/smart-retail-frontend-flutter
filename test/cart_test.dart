import 'package:flutter_test/flutter_test.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/cart_item_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartItem behavior', () {
    test('initial quantity and subtotal', () {
      final item = InventoryItem(
        id: 'i-100',
        merchantId: 'm1',
        name: 'Test Product',
        sellingPrice: 12.5,
        originalPrice: 8.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final c = CartItem(product: item, initialQuantity: 2);
      expect(c.quantity.value, 2);
      expect(c.subtotal, closeTo(25.0, 1e-6));
    });

    test('increment and decrement operations', () {
      final item = InventoryItem(
        id: 'i-200',
        merchantId: 'm1',
        name: 'Another',
        sellingPrice: 3.0,
        originalPrice: 2.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final c = CartItem(product: item, initialQuantity: 1);
      c.increment();
      expect(c.quantity.value, 2);
      c.decrement();
      expect(c.quantity.value, 1);
      // Decrement below 1 removes in controller, but CartItem itself allows 0
      c.decrement();
      expect(c.quantity.value, 0);
    });
  });
}
