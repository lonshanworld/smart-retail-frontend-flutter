import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/sales_analysis_api_service.dart';

class AiSalesAnalysisController extends GetxController {
  final SalesAnalysisApiService _apiService =
      Get.find<SalesAnalysisApiService>();

  final TextEditingController promptController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxString analysisResult = ''.obs;

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
    print('🤖 [AI SALES ANALYSIS] Sending prompt: $prompt');
    try {
      final result = await _apiService.getSalesAnalysis(prompt);
      print('🤖 [AI SALES ANALYSIS] Received result: $result');
      analysisResult.value = result;
    } catch (e) {
      errorMessage.value = e.toString();
      analysisResult.value = ''; // Clear previous results on error
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
