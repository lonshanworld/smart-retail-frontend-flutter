import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart'; // For date formatting

class StockMovement {
  final String id;
  final String itemId;
  final String shopId;
  final String movementType; // e.g., "stock_in", "sale", "return", "adjustment"
  final int quantityChanged; // Can be positive (stock in) or negative (stock out)
  final int newQuantity; // Stock quantity after this movement
  final String? reason; // Optional reason for adjustment
  final String userId; // User who performed the action
  final String? userName; // Optional resolved user name
  final DateTime movementDate;
  final String? notes; // Additional notes if any

  // Potentially include item details if the API provides them and they are needed in the UI
  // final String? itemName;
  // final String? itemSku;

  StockMovement({
    required this.id,
    required this.itemId,
    required this.shopId,
    required this.movementType,
    required this.quantityChanged,
    required this.newQuantity,
    this.reason,
    required this.userId,
    this.userName,
    required this.movementDate,
    this.notes,
    // this.itemName,
    // this.itemSku,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? json['movement_id'] as String? ?? UniqueKey().toString();
    final itemId = json['itemId'] as String? ??
        json['item_id'] as String? ??
        json['inventoryItemId'] as String? ??
        json['inventory_item_id'] as String? ??
        json['item_id'] as String?;
    final shopId = json['shopId'] as String? ?? json['shop_id'] as String?;
    final movementType = json['movementType'] as String? ??
        json['movement_type'] as String? ??
        json['reason'] as String? ??
        'stock_in';
    final quantity = (json['quantityChanged'] as num?)?.toInt() ??
        (json['quantity_changed'] as num?)?.toInt() ??
        (json['quantity'] as num?)?.toInt() ??
        0;
    final inferredMovementType = (() {
      if (movementType == 'stock_in' && quantity < 0) {
        return 'sale';
      }
      return movementType;
    })();
    final newQuantity = (json['newQuantity'] as num?)?.toInt() ??
        (json['new_quantity'] as num?)?.toInt() ??
        (json['newQty'] as num?)?.toInt() ??
        0;
    final userId = json['userId'] as String? ??
        json['user_id'] as String? ??
        json['actorId'] as String? ??
        json['actor_id'] as String? ??
        'local-user';
    final userName = json['userName'] as String? ?? json['user_name'] as String?;
    final movementDateString = json['movementDate'] as String? ??
        json['movement_date'] as String? ??
        json['time'] as String?;

    DateTime movementDate;
    if (movementDateString != null) {
      movementDate = DateTime.parse(movementDateString);
    } else {
      movementDate = DateTime.now();
    }

    return StockMovement(
      id: id,
      itemId: itemId ?? '',
      shopId: shopId ?? '',
      movementType: inferredMovementType,
      quantityChanged: quantity,
      newQuantity: newQuantity,
      reason: json['reason'] as String?,
      userId: userId,
      userName: userName,
      movementDate: movementDate,
      notes: json['notes'] as String?,
      // itemName: json['item_name'] as String?, // If API includes this
      // itemSku: json['item_sku'] as String?,   // If API includes this
    );
  }

  String get displayMovementType {
    return movementType;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'inventoryItemId': itemId,
      'shopId': shopId,
      'movementType': movementType,
      'quantityChanged': quantityChanged,
      'newQuantity': newQuantity,
      'reason': reason,
      'userId': userId,
      'movementDate': movementDate.toIso8601String(),
      'notes': notes,
      // 'item_name': itemName,
      // 'item_sku': itemSku,
    };
  }

  String get formattedMovementDate {
    return DateFormat('yyyy-MM-dd HH:mm').format(movementDate);
  }
}
