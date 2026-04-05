class Supplier {
  final String? id;
  final String merchantId;
  final String name;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Supplier({
    this.id,
    required this.merchantId,
    required this.name,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json["id"]?.toString(),
    merchantId: (json["merchantId"] ?? json["merchant_id"] ?? '').toString(),
    name: (json["name"] ?? '').toString(),
    contactName: (json["contactName"] ?? json["contact_name"])?.toString(),
    contactEmail: (json["contactEmail"] ?? json["contact_email"])?.toString(),
    contactPhone: (json["contactPhone"] ?? json["contact_phone"])?.toString(),
    address: (json["address"] ?? json["supplier_address"])?.toString(),
    notes: (json["notes"] ?? json["supplier_notes"])?.toString(),
    createdAt: (json["createdAt"] ?? json["created_at"]) == null
        ? null
      : DateTime.parse((json["createdAt"] ?? json["created_at"]).toString()),
    updatedAt: (json["updatedAt"] ?? json["updated_at"]) == null
        ? null
      : DateTime.parse((json["updatedAt"] ?? json["updated_at"]).toString()),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "merchantId": merchantId,
    "name": name,
    "contactName": contactName,
    "contactEmail": contactEmail,
    "contactPhone": contactPhone,
    "address": address,
    "notes": notes,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}

class PaginatedSuppliersResponse {
  final List<Supplier> suppliers;
  final int totalItems;
  final int currentPage;
  final int pageSize;
  final int totalPages;

  PaginatedSuppliersResponse({
    required this.suppliers,
    required this.totalItems,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedSuppliersResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedSuppliersResponse(
      suppliers: (json['data'] as List)
          .map((i) => Supplier.fromJson(i))
          .toList(),
      totalItems: json['pagination']['totalItems'],
      currentPage: json['pagination']['currentPage'],
      pageSize: json['pagination']['pageSize'],
      totalPages: json['pagination']['totalPages'],
    );
  }
}
