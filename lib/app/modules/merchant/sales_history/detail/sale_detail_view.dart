import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import './sale_detail_controller.dart';

class SaleDetailView extends GetView<SaleDetailController> {
  const SaleDetailView({super.key});

  String _getSafeTitle(String? saleId) {
    if (saleId == null) {
      return 'Sale Details';
    }
    final id = saleId.length > 8 ? '${saleId.substring(0, 8)}...' : saleId;
    return 'Sale: $id';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return MerchantMainScaffold(
        title: _getSafeTitle(controller.sale.value?.id),
        body: _buildBody(),
      );
    });
  }

  Widget _buildBody() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage.value.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            controller.errorMessage.value,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    if (controller.sale.value == null) {
      return const Center(child: Text('Sale not found.'));
    }
    return _buildSaleDetails(controller.sale.value!);
  }

  Widget _buildSaleDetails(Sale sale) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildHeader(sale),
        const SizedBox(height: 16),
        _buildInfoCard(sale, currencyFormat),
        const SizedBox(height: 16),
        _buildItemsCard(sale.items, currencyFormat),
      ],
    );
  }

  Widget _buildHeader(Sale sale) {
    return Center(
      child: Column(
        children: [
          Text(
            'Sale Details',
            style: Get.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat.yMMMMEEEEd().add_jm().format(sale.saleDate.toLocal()),
            style: Get.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Sale sale, NumberFormat currencyFormat) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.store, 'Shop ID:', sale.shopId),
            _buildInfoRow(
              Icons.person_outline,
              'Merchant ID:',
              sale.merchantId,
            ),
            if (sale.notes != null && sale.notes!.isNotEmpty)
              _buildInfoRow(Icons.notes, 'Notes:', sale.notes!),
            const Divider(height: 24),
            _buildTotalRow(
              'Subtotal',
              currencyFormat.format(
                sale.totalAmount +
                    (sale.discountAmount ?? 0) -
                    sale.deliveryCharge,
              ),
            ),
            if (sale.discountAmount != null && sale.discountAmount! > 0)
              _buildTotalRow(
                'Discount',
                '- ${currencyFormat.format(sale.discountAmount)}',
                color: Colors.green,
              ),
            if (sale.deliveryCharge > 0)
              _buildTotalRow(
                'Delivery Charge',
                currencyFormat.format(sale.deliveryCharge),
              ),
            _buildTotalRow(
              'Final Total',
              currencyFormat.format(sale.totalAmount),
              isBold: true,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.payment,
              'Payment Type:',
              sale.paymentType.capitalizeFirst ?? sale.paymentType,
            ),
            _buildInfoRow(
              Icons.credit_card,
              'Payment Status:',
              sale.paymentStatus.capitalizeFirst ?? sale.paymentStatus,
              valueColor: sale.paymentStatus == 'succeeded'
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(List<SaleItem> items, NumberFormat currencyFormat) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items Sold (${items.length})',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildItemTile(item, currencyFormat)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(SaleItem item, NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item.quantitySold} x ${currencyFormat.format(item.sellingPriceAtSale)}',
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
