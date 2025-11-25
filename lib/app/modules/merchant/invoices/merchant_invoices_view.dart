import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/modules/merchant/invoices/merchant_invoices_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';

class MerchantInvoicesView extends GetView<MerchantInvoicesController> {
  const MerchantInvoicesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Invoices',
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
        
        if (controller.invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No invoices found.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchInvoices(resetPage: true),
          child: Column(
            children: [
              // Header with pagination info
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${controller.totalItems.value} invoices',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: controller.currentPage.value > 1
                              ? controller.goToPreviousPage
                              : null,
                        ),
                        Text(
                          'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: controller.currentPage.value < controller.totalPages.value
                              ? controller.goToNextPage
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Invoice list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: controller.invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = controller.invoices[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(invoice.paymentStatus).withOpacity(0.2),
                          child: Icon(
                            Icons.receipt_long,
                            color: _getStatusColor(invoice.paymentStatus),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              invoice.invoiceNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(invoice.paymentStatus),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(invoice.invoiceDate.toLocal())}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Amount: \$${invoice.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (invoice.discountAmount > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Discount: -\$${invoice.discountAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => controller.goToInvoiceDetail(invoice.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
