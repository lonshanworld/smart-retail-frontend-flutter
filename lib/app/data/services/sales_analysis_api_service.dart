import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';

class SalesAnalysisResponse {
  const SalesAnalysisResponse({
    required this.analysisText,
    required this.analysisHtml,
    required this.isHtml,
    required this.chartSeries,
    required this.sql,
    required this.rawDataJson,
  });

  final String analysisText;
  final String analysisHtml;
  final bool isHtml;
  final List<AiChartPoint> chartSeries;
  final String sql;
  final String rawDataJson;
}

class AiChartPoint {
  const AiChartPoint({
    required this.label,
    required this.value,
    required this.metric,
  });

  final String label;
  final double value;
  final String metric;
}

class SalesAnalysisApiService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AuthService _authService = Get.find<AuthService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/merchant';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Makes a request to the AI backend for sales analysis.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/merchant/ai-analysis`
  /// - __Headers:__
  ///   - `Authorization: Bearer <token>`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "prompt": "What are my best sellers?"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "success": true,
  ///     "analysis": "Based on sales data...",
  ///     "sql": "SELECT ...",
  ///     "data": [...]
  ///   }
  ///   ```
  Future<SalesAnalysisResponse> getSalesAnalysis(String prompt) async {
    debugPrint('🔍 [AI SALES API] Sending request to backend...');
    debugPrint('   Prompt: $prompt');

    final response = await _connect.post(
      '$_baseUrl/ai-analysis',
      headers: await _getHeaders(),
      {'prompt': prompt},
    );

    debugPrint('📥 [AI SALES API] Response status: ${response.statusCode}');
    debugPrint('📥 [AI SALES API] Response body: ${response.body}');

    if (response.isOk && response.body['success'] == true) {
      final analysis = (response.body['analysis'] as String?) ?? '';
      final analysisHtml = (response.body['analysis_html'] as String?) ?? '';
      final analysisFormat =
          (response.body['analysis_format'] as String?)?.toLowerCase() ?? '';
      final isHtml = analysisFormat == 'html' || analysisHtml.isNotEmpty;
      final chartSeries = _parseChartSeries(response.body['chart_series']);
      final sql = (response.body['sql'] as String?) ?? '';
      final rawDataJson = _prettyJson(response.body['data']);

      debugPrint(
        '✅ [AI SALES API] Analysis received (${analysis.length} chars)',
      );

      // Optionally log the SQL and data for debugging
      if (response.body['sql'] != null) {
        debugPrint('   SQL: ${response.body['sql']}');
      }

      return SalesAnalysisResponse(
        analysisText: analysis,
        analysisHtml: analysisHtml,
        isHtml: isHtml,
        chartSeries: chartSeries,
        sql: sql,
        rawDataJson: rawDataJson,
      );
    } else {
      final errorMsg = response.body?['message'] ?? 'Failed to get AI analysis';
      debugPrint('❌ [AI SALES API] Error: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  List<AiChartPoint> _parseChartSeries(dynamic rawSeries) {
    if (rawSeries is! List) {
      return const [];
    }

    final points = <AiChartPoint>[];
    for (final item in rawSeries) {
      if (item is! Map) {
        continue;
      }

      final label = (item['label'] as String?)?.trim();
      final metric = (item['metric'] as String?)?.trim() ?? 'value';
      final valueRaw = item['value'];

      double? value;
      if (valueRaw is num) {
        value = valueRaw.toDouble();
      } else if (valueRaw is String) {
        value = double.tryParse(valueRaw.trim());
      }

      if (label == null || label.isEmpty || value == null) {
        continue;
      }

      points.add(AiChartPoint(label: label, value: value, metric: metric));
    }

    return points;
  }

  String _prettyJson(dynamic data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (_) {
      return data?.toString() ?? '[]';
    }
  }
}
