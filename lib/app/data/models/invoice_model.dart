class Invoice {
  final String id;
  final String saleId;
  final String invoiceNumber;
  final String merchantId;
  final String shopId;
  final String? customerId;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.saleId,
    required this.invoiceNumber,
    required this.merchantId,
    required this.shopId,
    this.customerId,
    required this.invoiceDate,
    this.dueDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      saleId: json['saleId'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      merchantId: json['merchantId'] as String,
      shopId: json['shopId'] as String,
      customerId: json['customerId'] as String?,
      invoiceDate: DateTime.parse(json['invoiceDate'] as String),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      subtotal: (json['subtotal'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentStatus: json['paymentStatus'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'invoiceNumber': invoiceNumber,
      'merchantId': merchantId,
      'shopId': shopId,
      'customerId': customerId,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PaginatedInvoicesResponse {
  final List<Invoice> items;
  final int totalItems;
  final int currentPage;
  final int pageSize;
  final int totalPages;

  PaginatedInvoicesResponse({
    required this.items,
    required this.totalItems,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedInvoicesResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((item) => Invoice.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    final pagination = json['pagination'] as Map<String, dynamic>?;

    return PaginatedInvoicesResponse(
      items: itemsList,
      totalItems: pagination?['totalItems'] as int? ?? 0,
      currentPage: pagination?['currentPage'] as int? ?? 1,
      pageSize: pagination?['pageSize'] as int? ?? 10,
      totalPages: pagination?['totalPages'] as int? ?? 0,
    );
  }
}
