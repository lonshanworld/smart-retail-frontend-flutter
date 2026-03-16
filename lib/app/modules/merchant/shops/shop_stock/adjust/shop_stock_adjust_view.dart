import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './shop_stock_adjust_controller.dart';

class ShopStockAdjustView extends GetView<ShopStockAdjustController> {
  const ShopStockAdjustView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adjust Stock')),
      body: const Center(
        child: Text('Stock adjustment form will be implemented here.'),
      ),
    );
  }
}
