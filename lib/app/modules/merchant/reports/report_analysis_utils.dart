import 'package:flutter/material.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';

class TrendPoint {
  const TrendPoint({
    required this.date,
    required this.revenue,
    required this.profit,
    required this.orders,
    required this.unitsSold,
    this.label,
  });

  final DateTime date;
  final double revenue;
  final double profit;
  final int orders;
  final int unitsSold;
  final String? label;
}

class ProductPerformance {
  const ProductPerformance({
    required this.itemId,
    required this.name,
    required this.sku,
    required this.unitsSold,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
    required this.currentStock,
    required this.ageDays,
    required this.lastSoldAt,
  });

  final String itemId;
  final String name;
  final String? sku;
  final int unitsSold;
  final double revenue;
  final double cost;
  final double profit;
  final double margin;
  final int currentStock;
  final int ageDays;
  final DateTime? lastSoldAt;
}

class BusinessRecommendation {
  const BusinessRecommendation({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;
}

class BusinessAnalysisSnapshot {
  const BusinessAnalysisSnapshot({
    required this.startDate,
    required this.endDate,
    required this.trendGroupingLabel,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
    required this.averageOrderValue,
    required this.totalSales,
    required this.totalUnitsSold,
    required this.activeProducts,
    required this.unsoldProductsCount,
    required this.slowMovingProductsCount,
    required this.lowStockProductsCount,
    required this.trendPoints,
    required this.topProducts,
    required this.slowMovingProducts,
    required this.unsoldProducts,
    required this.lowStockProducts,
    required this.recommendations,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String trendGroupingLabel;
  final double revenue;
  final double cost;
  final double profit;
  final double margin;
  final double averageOrderValue;
  final int totalSales;
  final int totalUnitsSold;
  final int activeProducts;
  final int unsoldProductsCount;
  final int slowMovingProductsCount;
  final int lowStockProductsCount;
  final List<TrendPoint> trendPoints;
  final List<ProductPerformance> topProducts;
  final List<ProductPerformance> slowMovingProducts;
  final List<ProductPerformance> unsoldProducts;
  final List<ProductPerformance> lowStockProducts;
  final List<BusinessRecommendation> recommendations;
}

class _ProductAccumulator {
  _ProductAccumulator({
    required this.itemId,
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.ageDays,
    required this.lastSoldAt,
  });

  final String itemId;
  final String name;
  final String? sku;
  final int currentStock;
  final int ageDays;
  DateTime? lastSoldAt;
  int unitsSold = 0;
  double revenue = 0;
  double cost = 0;
  double profit = 0;

  ProductPerformance build() {
    final margin = revenue <= 0 ? 0.0 : profit / revenue;
    return ProductPerformance(
      itemId: itemId,
      name: name,
      sku: sku,
      unitsSold: unitsSold,
      revenue: revenue,
      cost: cost,
      profit: profit,
      margin: margin,
      currentStock: currentStock,
      ageDays: ageDays,
      lastSoldAt: lastSoldAt,
    );
  }
}

class _TrendAccumulator {
  _TrendAccumulator(this.date, {this.label});

  DateTime date;
  String? label;
  final Set<String> saleIds = <String>{};
  double revenue = 0;
  double profit = 0;
  int orders = 0;
  int unitsSold = 0;

  TrendPoint build() {
    return TrendPoint(
      date: date,
      revenue: revenue,
      profit: profit,
      orders: orders,
      unitsSold: unitsSold,
      label: label,
    );
  }
}

String _normalizeGroupBy(String? groupBy) {
  final normalized = (groupBy ?? 'daily').toLowerCase();
  switch (normalized) {
    case 'daily':
    case 'weekly':
    case 'monthly':
    case 'item':
      return normalized;
    default:
      return 'daily';
  }
}

String _trendGroupingLabel(String groupBy) {
  switch (groupBy) {
    case 'weekly':
      return 'Week';
    case 'monthly':
      return 'Month';
    case 'item':
      return 'Item';
    case 'daily':
    default:
      return 'Day';
  }
}

DateTime _weekStart(DateTime date) {
  final normalized = _dayOnly(date);
  return normalized.subtract(
    Duration(days: normalized.weekday - DateTime.monday),
  );
}

DateTime _bucketStart(DateTime date, String groupBy) {
  switch (groupBy) {
    case 'weekly':
      return _weekStart(date);
    case 'monthly':
      return DateTime(date.year, date.month, 1);
    case 'item':
    case 'daily':
    default:
      return _dayOnly(date);
  }
}

int _stockForShop(InventoryItem item, String? shopId) {
  final stockInfo = item.stockInfo ?? const [];
  if (shopId == null || shopId.isEmpty) {
    return stockInfo.fold<int>(0, (sum, info) => sum + info.quantity);
  }

  final filtered = stockInfo.where((info) => info.shopId == shopId);
  if (filtered.isEmpty) {
    return stockInfo.fold<int>(0, (sum, info) => sum + info.quantity);
  }

  return filtered.fold<int>(0, (sum, info) => sum + info.quantity);
}

DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

BusinessAnalysisSnapshot buildBusinessAnalysisSnapshot({
  required List<Sale> sales,
  required List<InventoryItem> inventoryItems,
  required DateTime startDate,
  required DateTime endDate,
  String? shopId,
  String? groupBy,
}) {
  final normalizedGroupBy = _normalizeGroupBy(groupBy);
  final filteredSales = shopId == null || shopId.isEmpty
      ? sales
      : sales.where((sale) => sale.shopId == shopId).toList();

  final trendMap = <String, _TrendAccumulator>{};
  final itemAccumulators = <String, _ProductAccumulator>{};
  final inventoryById = {
    for (final item in inventoryItems)
      if (item.id != null && item.id!.isNotEmpty) item.id!: item,
  };

  double revenue = 0;
  double cost = 0;
  double profit = 0;
  int totalUnitsSold = 0;

  for (final sale in filteredSales) {
    final saleDate = sale.saleDate;

    if (normalizedGroupBy != 'item') {
      final bucketStart = _bucketStart(saleDate, normalizedGroupBy);
      final trend = trendMap.putIfAbsent(
        bucketStart.toIso8601String(),
        () => _TrendAccumulator(bucketStart),
      );
      trend.orders += 1;
      trend.revenue += sale.totalAmount;
    }

    for (final saleItem in sale.items) {
      final inventoryItem = inventoryById[saleItem.inventoryItemId];
      final stock = inventoryItem == null
          ? 0
          : _stockForShop(inventoryItem, shopId);
      final ageDays = inventoryItem == null
          ? 0
          : DateTime.now().difference(inventoryItem.createdAt).inDays;
      final trendKey = normalizedGroupBy == 'item'
          ? saleItem.inventoryItemId
          : _bucketStart(saleDate, normalizedGroupBy).toIso8601String();
      final trend = trendMap.putIfAbsent(trendKey, () {
        return _TrendAccumulator(
          normalizedGroupBy == 'item'
              ? saleDate
              : _bucketStart(saleDate, normalizedGroupBy),
          label: normalizedGroupBy == 'item'
              ? (saleItem.itemName?.trim().isNotEmpty == true
                    ? saleItem.itemName!.trim()
                    : (inventoryItem?.name ?? saleItem.inventoryItemId))
              : null,
        );
      });
      if (normalizedGroupBy == 'item') {
        final fallbackLabel = saleItem.itemName?.trim().isNotEmpty == true
            ? saleItem.itemName!.trim()
            : (inventoryItem?.name ?? saleItem.inventoryItemId);
        trend.label ??= fallbackLabel;
        trend.saleIds.add(sale.id);
        trend.orders = trend.saleIds.length;
        trend.revenue += saleItem.subtotal;
        trend.profit += saleItem.profit;
        trend.unitsSold += saleItem.quantitySold;
        if (saleDate.isAfter(trend.date)) {
          trend.date = saleDate;
        }
      } else {
        trend.unitsSold += saleItem.quantitySold;
        trend.profit += saleItem.profit;
      }

      final accumulator = itemAccumulators.putIfAbsent(
        saleItem.inventoryItemId,
        () => _ProductAccumulator(
          itemId: saleItem.inventoryItemId,
          name: saleItem.itemName?.trim().isNotEmpty == true
              ? saleItem.itemName!.trim()
              : (inventoryItem?.name ?? saleItem.inventoryItemId),
          sku: saleItem.itemSku ?? inventoryItem?.sku,
          currentStock: stock,
          ageDays: ageDays,
          lastSoldAt: sale.saleDate,
        ),
      );

      accumulator.unitsSold += saleItem.quantitySold;
      accumulator.revenue += saleItem.subtotal;
      accumulator.cost +=
          (saleItem.originalPriceAtSale ?? saleItem.sellingPriceAtSale) *
          saleItem.quantitySold;
      accumulator.profit += saleItem.profit;
      accumulator.lastSoldAt =
          accumulator.lastSoldAt == null ||
              sale.saleDate.isAfter(accumulator.lastSoldAt!)
          ? sale.saleDate
          : accumulator.lastSoldAt;

      revenue += saleItem.subtotal;
      cost +=
          (saleItem.originalPriceAtSale ?? saleItem.sellingPriceAtSale) *
          saleItem.quantitySold;
      profit += saleItem.profit;
      totalUnitsSold += saleItem.quantitySold;
    }
  }

  for (final item in inventoryItems) {
    final id = item.id;
    if (id == null || id.isEmpty) {
      continue;
    }
    itemAccumulators.putIfAbsent(
      id,
      () => _ProductAccumulator(
        itemId: id,
        name: item.name,
        sku: item.sku,
        currentStock: _stockForShop(item, shopId),
        ageDays: DateTime.now().difference(item.createdAt).inDays,
        lastSoldAt: null,
      ),
    );
  }

  final products = itemAccumulators.values
      .map((accumulator) => accumulator.build())
      .toList();
  products.sort((a, b) => b.revenue.compareTo(a.revenue));

  final topProducts = products.take(8).toList();
  final slowMovingProducts =
      products
          .where((product) => product.unitsSold > 0 && product.unitsSold <= 5)
          .toList()
        ..sort((a, b) {
          final units = a.unitsSold.compareTo(b.unitsSold);
          if (units != 0) return units;
          return b.currentStock.compareTo(a.currentStock);
        });
  final unsoldProducts =
      products
          .where(
            (product) => product.unitsSold == 0 && product.currentStock > 0,
          )
          .toList()
        ..sort((a, b) => b.ageDays.compareTo(a.ageDays));
  final lowStockProducts = products.where((product) {
    final inventoryItem = inventoryById[product.itemId];
    final threshold = inventoryItem?.lowStockThreshold ?? 5;
    return product.currentStock > 0 && product.currentStock <= threshold;
  }).toList()..sort((a, b) => a.currentStock.compareTo(b.currentStock));

  final trendPoints = trendMap.values.map((trend) => trend.build()).toList();
  if (normalizedGroupBy == 'item') {
    trendPoints.sort((a, b) {
      final revenueCompare = b.revenue.compareTo(a.revenue);
      if (revenueCompare != 0) return revenueCompare;
      return (a.label ?? a.date.toIso8601String()).compareTo(
        b.label ?? b.date.toIso8601String(),
      );
    });
    if (trendPoints.length > 12) {
      trendPoints.removeRange(12, trendPoints.length);
    }
  } else {
    trendPoints.sort((a, b) => a.date.compareTo(b.date));
  }

  final totalSales = filteredSales.length;
  final averageOrderValue = totalSales == 0 ? 0.0 : revenue / totalSales;
  final margin = revenue <= 0 ? 0.0 : profit / revenue;

  final recommendations = <BusinessRecommendation>[];
  if (unsoldProducts.isNotEmpty) {
    recommendations.add(
      BusinessRecommendation(
        title: 'Move stagnant stock',
        detail:
            '${unsoldProducts.length} products have stock but no sales in this range. Bundle them, discount them, or move them to a campaign.',
        icon: Icons.local_fire_department_outlined,
      ),
    );
  }
  if (lowStockProducts.isNotEmpty) {
    recommendations.add(
      BusinessRecommendation(
        title: 'Restock the floor',
        detail:
            '${lowStockProducts.length} products are running low. Reorder before fast movers go out of stock.',
        icon: Icons.inventory_outlined,
      ),
    );
  }
  if (margin < 0.25 && revenue > 0) {
    recommendations.add(
      const BusinessRecommendation(
        title: 'Improve margin',
        detail:
            'Gross margin is thin. Review supplier pricing, bundle strategy, and discount policy.',
        icon: Icons.trending_down_outlined,
      ),
    );
  }
  if (topProducts.isNotEmpty) {
    recommendations.add(
      const BusinessRecommendation(
        title: 'Push best sellers',
        detail:
            'Feature the top selling products in bundles, homepage placements, and upsell flows.',
        icon: Icons.rocket_launch_outlined,
      ),
    );
  }

  return BusinessAnalysisSnapshot(
    startDate: startDate,
    endDate: endDate,
    trendGroupingLabel: _trendGroupingLabel(normalizedGroupBy),
    revenue: revenue,
    cost: cost,
    profit: profit,
    margin: margin,
    averageOrderValue: averageOrderValue,
    totalSales: totalSales,
    totalUnitsSold: totalUnitsSold,
    activeProducts: products.where((product) => product.unitsSold > 0).length,
    unsoldProductsCount: unsoldProducts.length,
    slowMovingProductsCount: slowMovingProducts.length,
    lowStockProductsCount: lowStockProducts.length,
    trendPoints: trendPoints,
    topProducts: topProducts,
    slowMovingProducts: slowMovingProducts,
    unsoldProducts: unsoldProducts,
    lowStockProducts: lowStockProducts,
    recommendations: recommendations,
  );
}
