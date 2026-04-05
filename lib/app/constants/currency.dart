import 'package:intl/intl.dart';

const String currencySymbol = '\$';

String formatCurrency(num value) {
  final sign = value < 0 ? '-' : '';
  return '$sign$currencySymbol ${value.abs().toStringAsFixed(2)}';
}

NumberFormat buildCurrencyFormatter() {
  return NumberFormat.currency(symbol: currencySymbol);
}
