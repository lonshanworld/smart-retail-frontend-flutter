class ShopStockItem {
  final String itemId;
  final String itemName;
  final String? itemDescription;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  int quantity; // Current stock in the specific shop
  final String shopId;
  // Add other relevant fields from your InventoryItem model if needed
  // e.g., category, brand, supplierPrice, sellingPrice

  ShopStockItem({
    required this.itemId,
    required this.itemName,
    this.itemDescription,
    this.sku,
    this.barcode,
    this.imageUrl,
    required this.quantity,
    required this.shopId,
  });

  factory ShopStockItem.fromJson(Map<String, dynamic> json) {
    return ShopStockItem(
      itemId: json['itemId'] as String? ?? json['item_id'] as String, // Support both
      itemName: json['itemName'] as String? ?? json['item_name'] as String,
      itemDescription: json['itemDescription'] as String? ?? json['item_description'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      quantity: json['quantity'] as int, // Stock quantity from shop_stocks
      shopId: json['shopId'] as String? ?? json['shop_id'] as String, // Support both
      // Map other fields as necessary
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemDescription': itemDescription,
      'sku': sku,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'shopId': shopId,
      // Map other fields
    };
  }
}
