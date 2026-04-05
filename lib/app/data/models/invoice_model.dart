class Invoice {
  final String id;
  final String saleId;
  final String invoiceNumber;
  final String merchantId;
  final String shopId;
  final String? shopName;
  final String? customerId;
  final DateTime invoiceDate;
  final DateTime checkoutTime;
  final DateTime? dueDate;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double deliveryCharge;
  final double totalAmount;
  final String paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.saleId,
    required this.invoiceNumber,
    required this.merchantId,
    required this.shopId,
    this.shopName,
    this.customerId,
    required this.invoiceDate,
    required this.checkoutTime,
    this.dueDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.deliveryCharge,
    required this.totalAmount,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    List<InvoiceItem>? items,
  }) : items = items ?? const [];

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final dynamic idValue = json['id'] ?? json['invoiceId'] ?? json['invoice_id'];
    final dynamic saleIdValue = json['saleId'] ?? json['sale_id'];
    final dynamic invoiceNumberValue = json['invoiceNumber'] ?? json['invoice_number'];
    final dynamic merchantIdValue = json['merchantId'] ?? json['merchant_id'];
    final dynamic shopIdValue = json['shopId'] ?? json['shop_id'];
    final dynamic shopNameValue = json['shopName'] ?? json['shop_name'];
    final dynamic customerIdValue = json['customerId'] ?? json['customer_id'];
    final dynamic invoiceDateValue = json['invoiceDate'] ?? json['invoice_date'] ?? json['saleDate'] ?? json['sale_date'];
    final dynamic checkoutTimeValue = json['checkoutTime'] ?? json['checkout_time'] ?? invoiceDateValue;
    final dynamic dueDateValue = json['dueDate'] ?? json['due_date'];
    final dynamic subtotalValue = json['subtotal'] ?? json['sub_total'];
    final dynamic discountAmountValue = json['discountAmount'] ?? json['discount_amount'];
    final dynamic taxAmountValue = json['taxAmount'] ?? json['tax_amount'];
    final dynamic deliveryChargeValue = json['deliveryCharge'] ?? json['delivery_charge'];
    final dynamic totalAmountValue = json['totalAmount'] ?? json['total_amount'];
    final dynamic paymentStatusValue = json['paymentStatus'] ?? json['payment_status'] ?? 'pending';
    final dynamic notesValue = json['notes'];
    final dynamic createdAtValue = json['createdAt'] ?? json['created_at'] ?? invoiceDateValue;
    final dynamic updatedAtValue = json['updatedAt'] ?? json['updated_at'] ?? createdAtValue;

    return Invoice(
      id: idValue?.toString() ?? '',
      saleId: saleIdValue?.toString() ?? '',
      invoiceNumber: invoiceNumberValue?.toString() ?? '',
      merchantId: merchantIdValue?.toString() ?? '',
      shopId: shopIdValue?.toString() ?? '',
      shopName: shopNameValue?.toString(),
      customerId: customerIdValue?.toString(),
      invoiceDate: DateTime.tryParse(invoiceDateValue?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      checkoutTime: DateTime.tryParse(checkoutTimeValue?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      dueDate: dueDateValue != null ? DateTime.tryParse(dueDateValue.toString()) : null,
      subtotal: (subtotalValue as num?)?.toDouble() ?? double.tryParse(subtotalValue?.toString() ?? '') ?? 0.0,
      discountAmount: (discountAmountValue as num?)?.toDouble() ?? double.tryParse(discountAmountValue?.toString() ?? '') ?? 0.0,
      taxAmount: (taxAmountValue as num?)?.toDouble() ?? double.tryParse(taxAmountValue?.toString() ?? '') ?? 0.0,
      deliveryCharge:
          (deliveryChargeValue as num?)?.toDouble() ??
          double.tryParse(deliveryChargeValue?.toString() ?? '') ??
          0.0,
      totalAmount: (totalAmountValue as num?)?.toDouble() ?? double.tryParse(totalAmountValue?.toString() ?? '') ?? 0.0,
      paymentStatus: paymentStatusValue?.toString() ?? 'pending',
      notes: notesValue?.toString(),
      createdAt: DateTime.tryParse(createdAtValue?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(updatedAtValue?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      items:
          (json['items'] as List<dynamic>? ??
                  json['sale_items'] as List<dynamic>?)
              ?.map((i) => InvoiceItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'invoiceNumber': invoiceNumber,
      'merchantId': merchantId,
      'shopId': shopId,
      'shopName': shopName,
      'customerId': customerId,
      'invoiceDate': invoiceDate.toIso8601String(),
      'checkoutTime': checkoutTime.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'deliveryCharge': deliveryCharge,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class InvoiceItem {
  final String id;
  final String saleId;
  final String inventoryItemId;
  final String? itemName;
  final String? itemSku;
  final int quantitySold;
  final double sellingPriceAtSale;
  final double? originalPriceAtSale;
  final double subtotal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvoiceItem({
    required this.id,
    required this.saleId,
    required this.inventoryItemId,
    this.itemName,
    this.itemSku,
    required this.quantitySold,
    required this.sellingPriceAtSale,
    this.originalPriceAtSale,
    required this.subtotal,
    this.createdAt,
    this.updatedAt,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    final dynamic idValue = json['id'] ?? json['sale_item_id'] ?? json['item_id'];
    final dynamic saleIdValue = json['saleId'] ?? json['sale_id'];
    final dynamic inventoryItemIdValue = json['inventoryItemId'] ?? json['inventory_item_id'] ?? json['inventory_item'];
    final dynamic itemNameValue = json['itemName'] ?? json['item_name'] ?? json['name'] ?? json['title'] ?? json['product_name'] ?? json['productName'] ?? json['item'];
    final dynamic itemSkuValue = json['itemSku'] ?? json['item_sku'] ?? json['sku'];
    final dynamic quantityValue = json['quantitySold'] ?? json['quantity_sold'] ?? json['quantity'];

    return InvoiceItem(
      id: idValue?.toString() ?? '',
      saleId: saleIdValue?.toString() ?? '',
      inventoryItemId: inventoryItemIdValue?.toString() ?? '',
      itemName: itemNameValue?.toString(),
      itemSku: itemSkuValue?.toString(),
      quantitySold: quantityValue is num
          ? quantityValue.toInt()
          : int.tryParse(quantityValue?.toString() ?? '0') ?? 0,
      sellingPriceAtSale: () {
        final dynamic raw = json['sellingPriceAtSale'] ??
            json['selling_price_at_sale'] ??
            json['sellingPrice'] ??
            json['price'];
        if (raw == null) return 0.0;
        if (raw is num) return raw.toDouble();
        return double.tryParse(raw.toString()) ?? 0.0;
      }(),
      originalPriceAtSale: () {
        final dynamic raw = json['originalPriceAtSale'] ??
            json['original_price_at_sale'] ??
            json['originalPrice'];
        if (raw == null) return null;
        if (raw is num) return raw.toDouble();
        return double.tryParse(raw.toString());
      }(),
      subtotal: () {
        final dynamic raw = json['subtotal'] ?? json['sub_total'] ?? json['line_total'];
        if (raw == null) return 0.0;
        if (raw is num) return raw.toDouble();
        return double.tryParse(raw.toString()) ?? 0.0;
      }(),
      createdAt: () {
        final dynamic raw = json['createdAt'] ?? json['created_at'];
        if (raw == null) return null;
        try {
          return DateTime.parse(raw.toString());
        } catch (_) {
          return null;
        }
      }(),
      updatedAt: () {
        final dynamic raw = json['updatedAt'] ?? json['updated_at'];
        if (raw == null) return null;
        try {
          return DateTime.parse(raw.toString());
        } catch (_) {
          return null;
        }
      }(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'inventoryItemId': inventoryItemId,
      'itemName': itemName,
      'itemSku': itemSku,
      'quantitySold': quantitySold,
      'sellingPriceAtSale': sellingPriceAtSale,
      'originalPriceAtSale': originalPriceAtSale,
      'subtotal': subtotal,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
    final itemsList =
        (json['items'] as List<dynamic>?)
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
