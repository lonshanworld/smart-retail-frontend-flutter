import 'package:shared_preferences/shared_preferences.dart';

class PrinterPreferences {
  final int paperWidthMm;
  final double fontScale;
  final int printContentWidthPercent;
  final String voucherHeaderShopName;
  final String voucherHeaderAddress;
  final String voucherHeaderContact;

  const PrinterPreferences({
    required this.paperWidthMm,
    required this.fontScale,
    required this.printContentWidthPercent,
    required this.voucherHeaderShopName,
    required this.voucherHeaderAddress,
    required this.voucherHeaderContact,
  });

  factory PrinterPreferences.defaults() {
    return const PrinterPreferences(
      paperWidthMm: 80,
      fontScale: 1.0,
      printContentWidthPercent: 92,
      voucherHeaderShopName: '',
      voucherHeaderAddress: '',
      voucherHeaderContact: '',
    );
  }

  PrinterPreferences copyWith({
    int? paperWidthMm,
    double? fontScale,
    int? printContentWidthPercent,
    String? voucherHeaderShopName,
    String? voucherHeaderAddress,
    String? voucherHeaderContact,
  }) {
    return PrinterPreferences(
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      fontScale: fontScale ?? this.fontScale,
      printContentWidthPercent:
          printContentWidthPercent ?? this.printContentWidthPercent,
      voucherHeaderShopName:
          voucherHeaderShopName ?? this.voucherHeaderShopName,
      voucherHeaderAddress: voucherHeaderAddress ?? this.voucherHeaderAddress,
      voucherHeaderContact: voucherHeaderContact ?? this.voucherHeaderContact,
    );
  }
}

class PrinterPreferencesStorage {
  static const String _paperWidthKey = 'printer.paper_width_mm';
  static const String _fontScaleKey = 'printer.font_scale';
  static const String _printContentWidthPercentKey =
      'printer.print_content_width_percent';
  static const String _voucherHeaderShopNameKey = 'printer.voucher.shop_name';
  static const String _voucherHeaderAddressKey = 'printer.voucher.address';
  static const String _voucherHeaderContactKey = 'printer.voucher.contact';

  static Future<PrinterPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final paperWidthMm = prefs.getInt(_paperWidthKey) ?? 80;
    final fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    final printContentWidthPercent =
        prefs.getInt(_printContentWidthPercentKey) ??
        PrinterPreferences.defaults().printContentWidthPercent;
    final voucherHeaderShopName =
        prefs.getString(_voucherHeaderShopNameKey) ??
        PrinterPreferences.defaults().voucherHeaderShopName;
    final voucherHeaderAddress =
        prefs.getString(_voucherHeaderAddressKey) ??
        PrinterPreferences.defaults().voucherHeaderAddress;
    final voucherHeaderContact =
        prefs.getString(_voucherHeaderContactKey) ??
        PrinterPreferences.defaults().voucherHeaderContact;
    return PrinterPreferences(
      paperWidthMm: _normalizePaperWidth(paperWidthMm),
      fontScale: _normalizeFontScale(fontScale),
      printContentWidthPercent: _normalizePrintContentWidthPercent(
        printContentWidthPercent,
      ),
      voucherHeaderShopName: voucherHeaderShopName,
      voucherHeaderAddress: voucherHeaderAddress,
      voucherHeaderContact: voucherHeaderContact,
    );
  }

  static Future<void> save(PrinterPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _paperWidthKey,
      _normalizePaperWidth(preferences.paperWidthMm),
    );
    await prefs.setDouble(
      _fontScaleKey,
      _normalizeFontScale(preferences.fontScale),
    );
    await prefs.setInt(
      _printContentWidthPercentKey,
      _normalizePrintContentWidthPercent(preferences.printContentWidthPercent),
    );
    await prefs.setString(
      _voucherHeaderShopNameKey,
      preferences.voucherHeaderShopName.trim(),
    );
    await prefs.setString(
      _voucherHeaderAddressKey,
      preferences.voucherHeaderAddress.trim(),
    );
    await prefs.setString(
      _voucherHeaderContactKey,
      preferences.voucherHeaderContact.trim(),
    );
  }

  static int _normalizePaperWidth(int paperWidthMm) {
    if (paperWidthMm <= 40) return 40;
    if (paperWidthMm <= 58) return 58;
    return 80;
  }

  static double _normalizeFontScale(double fontScale) {
    if (fontScale < 0.8) return 0.8;
    if (fontScale > 3.0) return 3.0;
    return fontScale;
  }

  static int _normalizePrintContentWidthPercent(int value) {
    if (value < 50) return 50;
    if (value > 150) return 150;
    return value;
  }
}
