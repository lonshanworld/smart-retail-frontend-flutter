import 'package:flutter_test/flutter_test.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Promotion model and simple logic', () {
    test('percentage promo properties', () {
      final now = DateTime.now();
      final promo = Promotion(
        id: 'p-1',
        merchantId: 'm1',
        shopId: null,
        name: 'TenPct',
        description: '10% off',
        type: 'percentage',
        value: 10.0,
        minSpend: 0.0,
        conditions: {},
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(promo.type, 'percentage');
      expect(promo.value, 10.0);
      expect(promo.isActive, isTrue);
    });

    test('fixed_amount promo properties', () {
      final now = DateTime.now();
      final promo = Promotion(
        id: 'p-2',
        merchantId: 'm1',
        shopId: 'shop-1',
        name: 'FiveOff',
        description: '5 off',
        type: 'fixed_amount',
        value: 5.0,
        minSpend: 10.0,
        conditions: {},
        startDate: now,
        endDate: now.add(const Duration(days: 10)),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(promo.type, 'fixed_amount');
      expect(promo.minSpend, 10.0);
      expect(promo.shopId, 'shop-1');
    });

    test('promo validity by date range', () {
      final now = DateTime.now();
      final expired = Promotion(
        id: 'p-exp',
        merchantId: 'm1',
        shopId: null,
        name: 'Expired',
        description: '',
        type: 'percentage',
        value: 50.0,
        minSpend: 0.0,
        conditions: {},
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.subtract(const Duration(days: 1)),
        isActive: true,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 10)),
      );

      // simple check: endDate before now => expired
      expect(expired.endDate!.isBefore(DateTime.now()), isTrue);
    });
  });
}
