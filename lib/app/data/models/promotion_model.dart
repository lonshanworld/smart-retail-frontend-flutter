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

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      merchantId: json['merchantId'] ?? json['merchant_id'],
      shopId: json['shopId'] ?? json['shop_id'],
      name: json['name'],
      description: json['description'] ?? '',
      type: json['type'] ?? json['promoType'] ?? json['promo_type'],
      value: (json['value'] ?? json['promoValue'] ?? json['promo_value'] as num)
          .toDouble(),
      minSpend:
          (json['minSpend'] ?? json['min_spend'] as num?)?.toDouble() ?? 0.0,
      conditions: json['conditions'] != null
          ? Map<String, dynamic>.from(jsonDecode(json['conditions'] ?? '{}'))
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
      isActive: json['isActive'] ?? json['is_active'] ?? true,
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
    var itemsList = json['items'] as List;
    List<Promotion> promotions = itemsList
        .map((i) => Promotion.fromJson(i))
        .toList();

    return PaginatedPromotionsResponse(
      items: promotions,
      totalItems: json['totalItems'],
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
    );
  }
}
