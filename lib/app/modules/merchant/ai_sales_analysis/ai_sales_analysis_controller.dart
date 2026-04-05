import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/sales_analysis_api_service.dart';

enum AiResponseViewMode { chartAndHtml, htmlOnly, rawData }

class AiSalesAnalysisController extends GetxController {
  final SalesAnalysisApiService _apiService =
      Get.find<SalesAnalysisApiService>();

  final TextEditingController promptController = TextEditingController();
  final Rx<AiAnalysisProvider> selectedProvider = AiAnalysisProvider.auto.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxString analysisResult = ''.obs;
  final RxString analysisHtml = ''.obs;
  final RxBool isHtmlResult = false.obs;
  final RxList<AiChartPoint> chartSeries = <AiChartPoint>[].obs;
  final RxString sqlQuery = ''.obs;
  final RxString rawDataJson = ''.obs;
  final Rx<AiResponseViewMode> viewMode = AiResponseViewMode.chartAndHtml.obs;

  void setViewMode(AiResponseViewMode mode) {
    viewMode.value = mode;
  }

  void setProvider(AiAnalysisProvider provider) {
    selectedProvider.value = provider;
  }

  void askQuestion(String question) {
    promptController.text = question;
    getAnalysis();
  }

  Future<void> getAnalysis() async {
    final prompt = promptController.text;
    if (prompt.isEmpty) {
      errorMessage.value = 'Please enter a question.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    debugPrint('🤖 [AI SALES ANALYSIS] Sending prompt: $prompt');
    try {
      final result = await _apiService.getSalesAnalysis(
        prompt,
        provider: selectedProvider.value,
      );
      debugPrint('🤖 [AI SALES ANALYSIS] Received result: $result');
      analysisResult.value = result.analysisText;
      analysisHtml.value = result.analysisHtml;
      isHtmlResult.value = result.isHtml;
      chartSeries.assignAll(result.chartSeries);
      sqlQuery.value = result.sql;
      rawDataJson.value = result.rawDataJson;
      debugPrint('🤖 [AI SALES ANALYSIS] Provider used: ${result.provider}');
    } catch (e) {
      errorMessage.value = e.toString();
      analysisResult.value = ''; // Clear previous results on error
      analysisHtml.value = '';
      isHtmlResult.value = false;
      chartSeries.clear();
      sqlQuery.value = '';
      rawDataJson.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    promptController.dispose();
    super.onClose();
  }
}
