import 'package:shared_preferences/shared_preferences.dart';

class PrinterPreferences {
  final int paperWidthMm;
  final double fontScale;

  const PrinterPreferences({
    required this.paperWidthMm,
    required this.fontScale,
  });

  factory PrinterPreferences.defaults() {
    return const PrinterPreferences(paperWidthMm: 80, fontScale: 1.0);
  }

  PrinterPreferences copyWith({int? paperWidthMm, double? fontScale}) {
    return PrinterPreferences(
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

class PrinterPreferencesStorage {
  static const String _paperWidthKey = 'printer.paper_width_mm';
  static const String _fontScaleKey = 'printer.font_scale';

  static Future<PrinterPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final paperWidthMm = prefs.getInt(_paperWidthKey) ?? 80;
    final fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    return PrinterPreferences(
      paperWidthMm: _normalizePaperWidth(paperWidthMm),
      fontScale: _normalizeFontScale(fontScale),
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
  }

  static int _normalizePaperWidth(int paperWidthMm) {
    if (paperWidthMm <= 58) return 58;
    return 80;
  }

  static double _normalizeFontScale(double fontScale) {
    if (fontScale < 0.8) return 0.8;
    if (fontScale > 1.8) return 1.8;
    return fontScale;
  }
}
