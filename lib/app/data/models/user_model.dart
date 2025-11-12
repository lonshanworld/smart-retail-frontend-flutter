import 'package:smart_retail/app/data/enums/user_role.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? phone;
  final String? assignedShopId;
  final String? merchantId;
  final String? merchantName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Shop? shop;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.phone,
    this.assignedShopId,
    this.merchantId,
    this.merchantName,
    this.createdAt,
    this.updatedAt,
    this.shop,
  });

  // Convert role string to enum
  UserRole get roleAsEnum => role.toUserRole();

  // Get display name for role
  String get roleDisplay => roleAsEnum.toDisplayString();

  // Get shop name safely
  String? get shopName => shop?.name;

  factory User.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      if (value is int) return value == 1;
      return false;
    }

    final roleValue = json['role'] ?? UserRole.unknown.name;
    final bool isMerchant = roleValue == 'merchant';

    String? merchantId;
    String? merchantName;

    if (isMerchant) {
      merchantId = json['shop']?['merchant_id'] as String?;
      merchantName = json['shop']?['name'] as String?;
    } else {
      merchantId = json['merchant_id'];
      merchantName = json['merchant_name'];
    }

    return User(
      id: json['ID'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      role: roleValue,
      isActive: parseBool(json['isActive'] ?? json['is_active']),
      phone: json['phone'] as String?,
      assignedShopId: json['assignedShopId'] as String? ?? json['assigned_shop_id'] as String?,
      merchantId: merchantId,
      merchantName: merchantName,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : (json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null),
      shop: json['shop'] != null
          ? Shop.fromJson(json['shop'])
          : (json['Shop'] != null ? Shop.fromJson(json['Shop']) : null),
    );
  }

  factory User.fromJsonWithShop(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      if (value is int) return value == 1;
      return false;
    }

    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final roleValue = userJson['role'] ?? UserRole.unknown.name;
    final bool isMerchant = roleValue == 'merchant';

    String? merchantId;
    String? merchantName;

    if (isMerchant) {
      merchantId = json['shop']?['merchant_id'] as String?;
      merchantName = json['shop']?['name'] as String?;
    } else {
      merchantId = json['merchant']?['id'] as String?;
      merchantName = json['merchant']?['name'] as String?;
    }

    return User(
      id: userJson['ID'] ?? userJson['id'],
      name: userJson['name'],
      email: userJson['email'],
      role: roleValue,
      isActive: parseBool(userJson['isActive'] ?? userJson['is_active']),
      phone: userJson['phone'] as String?,
      assignedShopId: userJson['assignedShopId'] as String? ?? userJson['assigned_shop_id'] as String?,
      merchantId: merchantId,
      merchantName: merchantName,
      createdAt: userJson['createdAt'] != null
          ? DateTime.tryParse(userJson['createdAt'].toString())
          : (userJson['created_at'] != null
          ? DateTime.tryParse(userJson['created_at'].toString())
          : null),
      updatedAt: userJson['updatedAt'] != null
          ? DateTime.tryParse(userJson['updatedAt'].toString())
          : (userJson['updated_at'] != null
          ? DateTime.tryParse(userJson['updated_at'].toString())
          : null),
      shop: json['shop'] != null ? Shop.fromJson(json['shop']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'phone': phone,
      'assignedShopId': assignedShopId,
      'merchantId': merchantId,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? isActive,
    String? phone,
    String? assignedShopId,
    String? merchantId,
    String? merchantName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Shop? shop,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      assignedShopId: assignedShopId ?? this.assignedShopId,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shop: shop ?? this.shop,
    );
  }
}
