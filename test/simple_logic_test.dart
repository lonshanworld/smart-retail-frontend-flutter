import 'package:flutter_test/flutter_test.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/cart_item_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CartItem subtotal is price * quantity', () {
    final item = InventoryItem(
      id: 'i1',
      merchantId: 'm1',
      name: 'Test Item',
      sellingPrice: 9.99,
      originalPrice: 6.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final cartItem = CartItem(product: item, initialQuantity: 3);
    expect(cartItem.subtotal, closeTo(9.99 * 3, 0.0001));
  });

  test('SaleItem profit calculation', () {
    final saleItem = SaleItem(
      id: 's1',
      saleId: 'sale1',
      inventoryItemId: 'i1',
      quantitySold: 4,
      sellingPriceAtSale: 20.0,
      originalPriceAtSale: 12.5,
      subtotal: 80.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      itemName: 'Widget',
      itemSku: 'W-01',
    );

    // profit = (sellingPrice - originalPrice) * quantity
    final expectedProfit = (20.0 - 12.5) * 4; // 7.5 * 4 = 30
    expect(saleItem.profit, closeTo(expectedProfit, 0.0001));
  });

  test('Promotion model holds values correctly', () {
    final now = DateTime.now();
    final promo = Promotion(
      id: 'promo1',
      merchantId: 'm1',
      shopId: null,
      name: 'Ten Percent',
      description: '10% off',
      type: 'percentage',
      value: 10.0,
      minSpend: 5.0,
      conditions: {},
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    expect(promo.type, 'percentage');
    expect(promo.value, 10.0);
    expect(promo.minSpend, 5.0);
    expect(promo.isActive, true);
  });
}
