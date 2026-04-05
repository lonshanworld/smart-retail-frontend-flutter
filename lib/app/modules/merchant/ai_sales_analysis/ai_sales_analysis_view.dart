import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/services/sales_analysis_api_service.dart';
import 'package:smart_retail/app/modules/merchant/ai_sales_analysis/ai_sales_analysis_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/widgets/ai/ai_chart_series_card.dart';
import 'package:smart_retail/app/widgets/ai/ai_html_response_card.dart';

class AiSalesAnalysisView extends GetView<AiSalesAnalysisController> {
  const AiSalesAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'AI Sales & Analysis',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProviderSelector(context),
            const SizedBox(height: 12),
            _buildQuickQuestions(),
            const SizedBox(height: 16),
            _buildPromptInput(),
            const SizedBox(height: 24),
            Expanded(child: _buildResponseArea(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelector(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          const Text(
            'AI Provider:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          DropdownButton<AiAnalysisProvider>(
            value: controller.selectedProvider.value,
            onChanged: (value) {
              if (value != null) {
                controller.setProvider(value);
              }
            },
            items: const [
              DropdownMenuItem(
                value: AiAnalysisProvider.auto,
                child: Text('Auto'),
              ),
              DropdownMenuItem(
                value: AiAnalysisProvider.gemini,
                child: Text('Gemini'),
              ),
              DropdownMenuItem(
                value: AiAnalysisProvider.openrouter,
                child: Text('OpenRouter'),
              ),
              DropdownMenuItem(
                value: AiAnalysisProvider.openai,
                child: Text('ChatGPT / OpenAI'),
              ),
            ],
          ),
          const Spacer(),
          Obx(
            () => controller.isLoading.value
                ? const SizedBox.shrink()
                : Text(
                    Get.find<AppConfig>().localStorageOnly
                        ? 'Local storage only: offline fallback is active'
                        : 'Remote AI is available',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.grey[700]),
                  ),
          ),
        ],
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

  Widget _buildResponseArea(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildViewModeDropdown(),
            const SizedBox(height: 12),
            if (controller.viewMode.value == AiResponseViewMode.chartAndHtml)
              AiChartSeriesCard(points: controller.chartSeries),
            if (controller.viewMode.value != AiResponseViewMode.rawData)
              AiHtmlResponseCard(
                html: controller.analysisHtml.value,
                fallbackText: controller.analysisResult.value,
              ),
            if (controller.viewMode.value == AiResponseViewMode.rawData)
              _buildRawDataCard(context),
          ],
        ),
      );
    });
  }

  Widget _buildViewModeDropdown() {
    return Row(
      children: [
        const Text('View:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        DropdownButton<AiResponseViewMode>(
          value: controller.viewMode.value,
          onChanged: (value) {
            if (value != null) {
              controller.setViewMode(value);
            }
          },
          items: const [
            DropdownMenuItem(
              value: AiResponseViewMode.chartAndHtml,
              child: Text('Chart + HTML'),
            ),
            DropdownMenuItem(
              value: AiResponseViewMode.htmlOnly,
              child: Text('HTML only'),
            ),
            DropdownMenuItem(
              value: AiResponseViewMode.rawData,
              child: Text('Raw data (debug)'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRawDataCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SQL',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            controller.sqlQuery.value.isEmpty
                ? 'No SQL available.'
                : controller.sqlQuery.value,
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 14),
          Text(
            'Raw Data',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            controller.rawDataJson.value.isEmpty
                ? '[]'
                : controller.rawDataJson.value,
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
