class ShopCustomer {
  final String id;
  final String shopId;
  final String merchantId;
  final String name;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopCustomer({
    required this.id,
    required this.shopId,
    required this.merchantId,
    required this.name,
    this.email,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopCustomer.fromJson(Map<String, dynamic> json) {
    return ShopCustomer(
      id: json['id'] as String,
      // Handle both camelCase and snake_case
      shopId: (json['shopId'] ?? json['shop_id']) as String,
      merchantId: (json['merchantId'] ?? json['merchant_id']) as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      // Handle both camelCase and snake_case for dates
      createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
      updatedAt: DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String),
    );
  }
}
