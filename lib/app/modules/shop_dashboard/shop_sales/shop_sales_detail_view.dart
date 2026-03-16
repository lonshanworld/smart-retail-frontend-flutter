import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class ShopSalesDetailView extends StatelessWidget {
  final Sale sale;

  const ShopSalesDetailView({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat.yMd().add_jm();

    // Calculate totals
    double totalSellingPrice = sale.items.fold(
      0,
      (sum, item) => sum + item.subtotal,
    );
    double totalOriginalPrice = sale.items.fold(
      0,
      (sum, item) =>
          sum + ((item.originalPriceAtSale ?? 0.0) * item.quantitySold),
    );
    double totalProfit = sale.items.fold(0, (sum, item) => sum + item.profit);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        backgroundColor: AppColors.shop,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sale Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.shop.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.shop.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sale ID',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            sale.id,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(sale.paymentStatus),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sale.paymentStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date & Time',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            dateFormat.format(sale.saleDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Payment Type',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            sale.paymentType,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Items Section
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sale.items.length,
              itemBuilder: (context, index) {
                final item = sale.items[index];
                final profit = item.profit;
                final profitColor = profit >= 0 ? Colors.green : Colors.red;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Item #${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'ID: ${item.inventoryItemId}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Qty: ${item.quantitySold}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.info.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Prices row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selling Price',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                currencyFormat.format(item.sellingPriceAtSale),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Show Original Price only for merchants
                          if (Get.find<AuthService>().user.value?.role ==
                              'merchant')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Original Price',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(
                                    item.originalPriceAtSale ?? 0,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                currencyFormat.format(item.subtotal),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Profit row (only for merchants)
                      if (Get.find<AuthService>().user.value?.role ==
                          'merchant')
                        Container(
                          padding: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Profit per item',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                currencyFormat.format(
                                  item.profit / item.quantitySold,
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: profitColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Summary Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.shop.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.shop.shade200),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Items', '${sale.items.length}'),
                  const Divider(),
                  _buildSummaryRow(
                    'Total Selling Price',
                    currencyFormat.format(totalSellingPrice),
                  ),
                  if (Get.find<AuthService>().user.value?.role ==
                      'merchant') ...[
                    const Divider(),
                    _buildSummaryRow(
                      'Total Original Price',
                      currencyFormat.format(totalOriginalPrice),
                    ),
                    const Divider(),
                    _buildSummaryRow(
                      'Total Profit',
                      currencyFormat.format(totalProfit),
                      valueColor: totalProfit >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                  const Divider(),
                  _buildSummaryRow(
                    'Discount Applied',
                    currencyFormat.format(sale.discountAmount),
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'Sale Total',
                    currencyFormat.format(sale.totalAmount),
                    isFinal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.shop,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Get.back(),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isFinal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isFinal ? 14 : 13,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isFinal ? 14 : 13,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
