import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tax and discount calculation (5% tax on discounted amount)', () {
    double computeTax(double subtotal, double discount) {
      return (subtotal - discount) * 0.05;
    }

    double computeTotal(double subtotal, double discount) {
      return subtotal - discount + computeTax(subtotal, discount);
    }

    test('no discount => tax = 5% of subtotal', () {
      final subtotal = 200.0;
      final discount = 0.0;
      expect(computeTax(subtotal, discount), closeTo(10.0, 1e-6));
      expect(computeTotal(subtotal, discount), closeTo(210.0, 1e-6));
    });

    test('percentage-like discount applied', () {
      final subtotal = 100.0;
      final discount = 10.0; // e.g., 10% on 100
      expect(computeTax(subtotal, discount), closeTo(4.5, 1e-6));
      expect(computeTotal(subtotal, discount), closeTo(94.5, 1e-6));
    });

    test('discount equals subtotal => tax zero and total zero', () {
      final subtotal = 50.0;
      final discount = 50.0;
      expect(computeTax(subtotal, discount), closeTo(0.0, 1e-6));
      expect(computeTotal(subtotal, discount), closeTo(0.0, 1e-6));
    });
  });
}
