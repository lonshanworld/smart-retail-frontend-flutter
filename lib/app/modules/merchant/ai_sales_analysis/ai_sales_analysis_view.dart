import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/merchant/ai_sales_analysis/ai_sales_analysis_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';

class AiSalesAnalysisView extends GetView<AiSalesAnalysisController> {
  const AiSalesAnalysisView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'AI Sales & Analysis',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildQuickQuestions(),
            const SizedBox(height: 16),
            _buildPromptInput(),
            const SizedBox(height: 24),
            Expanded(child: _buildResponseArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final quickQuestions = [
      'Show me sales report for this month',
      'What are my best selling products?',
      'Which shops have the highest revenue?',
      'Show me low stock items',
      'Total revenue this week',
      'List of customers who bought the most',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Questions:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickQuestions.map((question) {
            return ActionChip(
              label: Text(question, style: const TextStyle(fontSize: 12)),
              onPressed: () => controller.askQuestion(question),
              avatar: const Icon(Icons.smart_toy, size: 16),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPromptInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.promptController,
            decoration: const InputDecoration(
              hintText:
                  'Ask about your sales, e.g., "What are my best sellers?"',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => controller.getAnalysis(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () => controller.getAnalysis(),
          tooltip: 'Get Analysis',
        ),
      ],
    );
  }

  Widget _buildResponseArea() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.errorMessage.value != null) {
        return Center(
          child: Text(
            'Error: ${controller.errorMessage.value}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      }
      if (controller.analysisResult.value.isEmpty) {
        return const Center(
          child: Text('Ask a question to see your analysis.'),
        );
      }
      return SingleChildScrollView(
        child: Text(controller.analysisResult.value),
      );
    });
  }
}
