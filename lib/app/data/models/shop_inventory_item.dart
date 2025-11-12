/// Represents the stock of a specific inventory item within a single shop.
class ShopInventoryItem {
  final String id; // Unique ID for the shop-stock link
  final String productId; // Foreign key to the master InventoryItem
  final String name; // Denormalized for display
  final String? sku; // Denormalized for display
  final int quantity;
  final double sellingPrice;

  ShopInventoryItem({
    required this.id,
    required this.productId,
    required this.name,
    this.sku,
    required this.quantity,
    required this.sellingPrice,
  });

  factory ShopInventoryItem.fromJson(Map<String, dynamic> json) {
    // Backend returns the full InventoryItem structure with 'id' as the product ID
    // For backward compatibility, also check for 'productId' and 'product_id'
    final productId = json['productId'] as String? ?? 
                     json['product_id'] as String? ?? 
                     json['id'] as String;
    
    // Handle quantity - it's nested in 'stock' object
    final stockData = json['stock'] as Map<String, dynamic>?;
    final quantityValue = stockData?['quantity'] as num?;
    final quantity = quantityValue?.toInt() ?? 0;
    
    // Handle selling price - try multiple field names with null safety
    final sellingPriceValue = json['sellingPrice'] as num? ?? 
                              json['selling_price'] as num? ?? 
                              0.0;
    
    return ShopInventoryItem(
      id: json['id'] as String,
      productId: productId,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      quantity: quantity,
      sellingPrice: sellingPriceValue.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'sku': sku,
      'quantity': quantity,
      'sellingPrice': sellingPrice,
    };
  }
}
