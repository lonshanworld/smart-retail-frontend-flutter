import 'package:flutter_test/flutter_test.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaleItem and Sale model', () {
    test('SaleItem profit calculation with decimals', () {
      final item = SaleItem(
        id: 'si-1',
        saleId: 's-1',
        inventoryItemId: 'i-1',
        quantitySold: 3,
        sellingPriceAtSale: 9.99,
        originalPriceAtSale: 5.50,
        subtotal: 29.97,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        itemName: 'Decimal',
        itemSku: 'D-01',
      );

      final expected = (9.99 - 5.50) * 3;
      expect(item.profit, closeTo(expected, 1e-6));
    });

    test('Sale.fromJson reconstructs items and totals', () {
      final now = DateTime.now().toIso8601String();
      final json = {
        'id': 's123',
        'shopId': 'shop-1',
        'merchantId': 'm1',
        'saleDate': now,
        'totalAmount': 100.0,
        'discountAmount': 10.0,
        'paymentType': 'cash',
        'paymentStatus': 'succeeded',
        'createdAt': now,
        'updatedAt': now,
        'items': [
          {
            'id': 'si1',
            'saleId': 's123',
            'inventoryItemId': 'i1',
            'quantitySold': 2,
            'sellingPriceAtSale': 30.0,
            'originalPriceAtSale': 20.0,
            'subtotal': 60.0,
            'createdAt': now,
            'updatedAt': now,
            'itemName': 'Thing',
            'itemSku': 'T-01',
          },
        ],
      };

      final sale = Sale.fromJson(json);
      // Sale.fromJson in model reconstructs totalAmount as originalTotal (total + discount)
      expect(sale.totalAmount, closeTo(110.0, 1e-6));
      expect(sale.items.length, 1);
      expect(sale.items.first.itemName, 'Thing');
    });
  });
}
