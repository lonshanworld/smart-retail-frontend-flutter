import 'dart:convert';

class Promotion {
  final String id;
  final String merchantId;
  final String? shopId;
  final String name;
  final String description;
  final String type;
  final double value;
  final double minSpend; // ADDED
  final Map<String, dynamic> conditions;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.merchantId,
    this.shopId,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    required this.minSpend, // ADDED
    required this.conditions,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  static Map<String, dynamic> _normalizeConditions(dynamic conditions) {
    if (conditions is Map<String, dynamic>) {
      return conditions;
    }
    if (conditions is Map) {
      return conditions.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes' || normalized == 'y') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no' || normalized == 'n') {
        return false;
      }
    }
    return defaultValue;
  }

  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] ?? json['promoType'] ?? json['promo_type'] ?? '';
    return Promotion(
      id: json['id']?.toString() ?? '',
      merchantId: (json['merchantId'] ?? json['merchant_id'])?.toString() ?? '',
      shopId: (json['shopId'] ?? json['shop_id'])?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description'] ?? '',
      type: rawType.toString(),
      value: _parseDouble(json['value'] ?? json['promoValue'] ?? json['promo_value']),
      minSpend: _parseDouble(json['minSpend'] ?? json['min_spend']),
      conditions: json['conditions'] != null
          ? (json['conditions'] is String
              ? Map<String, dynamic>.from(jsonDecode(json['conditions'] as String))
              : Promotion._normalizeConditions(json['conditions']))
          : {},

      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : (json['start_date'] != null
                ? DateTime.parse(json['start_date'])
                : null),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : (json['end_date'] != null
                ? DateTime.parse(json['end_date'])
                : null),
      isActive: _parseBool(json['isActive'] ?? json['is_active'] ?? json['active'], defaultValue: true),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null
                ? DateTime.parse(json['updated_at'])
                : DateTime.now()),
    );
  }
}

class PaginatedPromotionsResponse {
  final List<Promotion> items;
  final int totalItems;
  final int currentPage;
  final int totalPages;

  PaginatedPromotionsResponse({
    required this.items,
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
  });

  factory PaginatedPromotionsResponse.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? const [];
    List<Promotion> promotions = itemsList
        .map((i) => Promotion.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();

    return PaginatedPromotionsResponse(
      items: promotions,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}
