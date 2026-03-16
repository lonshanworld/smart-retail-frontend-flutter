import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/modules/merchant/invoices/invoice_detail_controller.dart';
import 'package:smart_retail/app/modules/shop_dashboard/widgets/shop_main_scaffold.dart';

class ShopInvoiceDetailView extends GetView<InvoiceDetailController> {
  const ShopInvoiceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopMainScaffold(
      title: 'Invoice Details',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${controller.errorMessage.value}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: controller.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final invoice = controller.invoice.value;
        if (invoice == null) {
          return const Center(child: Text('Invoice not found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invoice.invoiceNumber,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Invoice Date: ${DateFormat('MMM dd, yyyy').format(invoice.invoiceDate.toLocal())}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amount Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildAmountRow('Subtotal', invoice.subtotal),
                      const SizedBox(height: 12),
                      if (invoice.discountAmount > 0) ...[
                        _buildAmountRow('Discount', -invoice.discountAmount, color: Colors.green),
                        const SizedBox(height: 12),
                      ],
                      if (invoice.taxAmount > 0) ...[
                        _buildAmountRow('Tax', invoice.taxAmount),
                        const SizedBox(height: 12),
                      ],
                      const Divider(height: 24),
                      _buildAmountRow('Total', invoice.totalAmount, isTotal: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('Sale ID', invoice.saleId),
                      const SizedBox(height: 12),
                      _buildInfoRow('Shop ID', invoice.shopId),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Items Card
              if (invoice.items.isNotEmpty) Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      ...invoice.items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it.itemName ?? it.inventoryItemId, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (it.itemSku != null) Text('SKU: ${it.itemSku}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('x${it.quantitySold}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            Text('\$${it.sellingPriceAtSale.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            Text('\$${it.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),

              // Download PDF Button
              Obx(() {
                final isGenerating = controller.isGeneratingPdf.value;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isGenerating ? null : controller.downloadPdf,
                    icon: isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(isGenerating ? 'Generating PDF...' : 'Download PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          '\$${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isTotal ? Colors.blue : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
