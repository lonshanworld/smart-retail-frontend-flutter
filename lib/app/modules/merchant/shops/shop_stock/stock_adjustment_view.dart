import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import './stock_adjustment_controller.dart';

class StockAdjustmentView extends GetView<StockAdjustmentController> {
  const StockAdjustmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adjust Stock: ${controller.itemName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.itemName,
                        style: Get.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (controller.itemSku != null &&
                          controller.itemSku!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'SKU: ${controller.itemSku}',
                            style: Get.textTheme.titleSmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Current Quantity: ${controller.initialQuantity}',
                        style: Get.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Adjustment Type Dropdown
              Obx(
                () => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  initialValue: controller.selectedAdjustmentType.value,
                  hint: const Text('Select reason for adjustment'),
                  isExpanded: true,
                  items: controller.adjustmentTypes.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    controller.selectedAdjustmentType.value = value;
                  },
                  validator: (value) =>
                      value == null ? 'Please select an adjustment type' : null,
                ),
              ),
              const SizedBox(height: 20),
              // Quantity Change TextField
              TextFormField(
                controller: controller.quantityChangeController,
                decoration: const InputDecoration(
                  labelText: 'Quantity Change (+/-)',
                  hintText: 'e.g., -5 or 10',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.compare_arrows_outlined),
                ),
                keyboardType: TextInputType.numberWithOptions(signed: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9-]'),
                  ), // Allow digits and hyphen
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the quantity change';
                  }
                  final int? quantity = int.tryParse(value);
                  if (quantity == null) {
                    return 'Please enter a valid number';
                  }
                  if (quantity == 0) {
                    return 'Quantity change cannot be zero';
                  }
                  // Further validation: Ensure negative adjustments don't exceed current quantity if not allowed
                  // This might be better handled by the backend, but a client-side check can be helpful.
                  // if (controller.initialQuantity + quantity < 0) {
                  //   return 'Adjustment results in negative stock.';
                  // }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Reason TextField (Optional)
              TextFormField(
                controller: controller.reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 30),
              Obx(() {
                if (controller.errorMessage.value != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      controller.errorMessage.value!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              Obx(
                () => ElevatedButton.icon(
                  icon: controller.isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Icon(Icons.save_alt_outlined),
                  label: Text(
                    controller.isSaving.value
                        ? 'Saving Adjustment...'
                        : 'Save Adjustment',
                  ),
                  onPressed: controller.isSaving.value
                      ? null
                      : () => controller.performAdjustment(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
