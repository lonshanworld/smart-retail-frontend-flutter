import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:smart_retail/app/data/models/report_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/services/report_api_service.dart';

enum AiAnalysisProvider { auto, gemini, openrouter, openai }

class SalesAnalysisResponse {
  const SalesAnalysisResponse({
    required this.analysisText,
    required this.analysisHtml,
    required this.isHtml,
    required this.chartSeries,
    required this.sql,
    required this.rawDataJson,
    required this.provider,
  });

  final String analysisText;
  final String analysisHtml;
  final bool isHtml;
  final List<AiChartPoint> chartSeries;
  final String sql;
  final String rawDataJson;
  final String provider;
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
  final AppConfig _appConfig = Get.find<AppConfig>();
  final ReportApiService _reportApiService = Get.find<ReportApiService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/merchant';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String _providerName(AiAnalysisProvider provider) {
    switch (provider) {
      case AiAnalysisProvider.gemini:
        return 'gemini';
      case AiAnalysisProvider.openrouter:
        return 'openrouter';
      case AiAnalysisProvider.openai:
        return 'openai';
      case AiAnalysisProvider.auto:
        return 'auto';
    }
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
  Future<SalesAnalysisResponse> getSalesAnalysis(
    String prompt, {
    AiAnalysisProvider provider = AiAnalysisProvider.auto,
  }) async {
    final providerName = _providerName(provider);

    // If running in local-only mode, synthesize a useful response from the
    // locally stored sales report data.
    if (_appConfig.localStorageOnly) {
      debugPrint(
        '🔒 [AI SALES API] Local-only mode: using local sales data fallback.',
      );
      return await _buildLocalFallback(prompt, providerName);
    }

    debugPrint('🔍 [AI SALES API] Sending request to backend...');
    debugPrint('   Prompt: $prompt');
    debugPrint('   Provider: $providerName');

    final response = await _connect.post(
      '$_baseUrl/ai-analysis',
      headers: await _getHeaders(),
      {'prompt': prompt, 'provider': providerName},
    );

    // If local-only mode became enabled concurrently, return the offline
    // placeholder instead of processing a remote response.
    if (_appConfig.localStorageOnly) {
      return await _buildLocalFallback(prompt, providerName);
    }

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
      final providerUsed =
          (response.body['provider'] as String?) ?? providerName;

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
        provider: providerUsed,
      );
    } else {
      final errorMsg = response.body?['message'] ?? 'Failed to get AI analysis';
      debugPrint('❌ [AI SALES API] Error: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  Future<SalesAnalysisResponse> _buildLocalFallback(
    String prompt,
    String providerName,
  ) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    final report = await _reportApiService.getSalesReport(
      startDate: startDate,
      endDate: endDate,
    );

    final productStats = <String, _LocalProductStat>{};
    double totalRevenue = 0;
    double totalProfit = 0;
    int totalOrders = 0;
    int totalUnits = 0;

    for (final sale in report.sales) {
      totalOrders += 1;
      totalRevenue += sale.totalAmount;
      totalProfit += sale.totalProfit;
      for (final item in sale.items) {
        final key = item.itemName?.trim().isNotEmpty == true
            ? item.itemName!.trim()
            : item.inventoryItemId;
        final stat = productStats.putIfAbsent(
          key,
          () => _LocalProductStat(name: key, sku: item.itemSku),
        );
        stat.unitsSold += item.quantitySold;
        stat.revenue += item.subtotal;
        stat.profit += item.profit;
        totalUnits += item.quantitySold;
      }
    }

    final topProducts = productStats.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    final chartSeries = topProducts
        .take(6)
        .map(
          (product) => AiChartPoint(
            label: product.name,
            value: product.revenue,
            metric: 'revenue',
          ),
        )
        .toList();

    final margin = totalRevenue <= 0 ? 0.0 : totalProfit / totalRevenue;
    final recommendedAction = totalOrders == 0
        ? 'No local sales were found in the last 30 days.'
        : margin < 0.2
        ? 'Margin is thin. Review pricing, bundles, and promotions.'
        : 'Promote top sellers and keep the inventory moving.';

    final topHtmlRows = topProducts.take(5).map((product) {
      return '<tr>'
          '<td style="padding:10px;border:1px solid #d0d7de;">${_escapeHtml(product.name)}</td>'
          '<td style="padding:10px;border:1px solid #d0d7de;text-align:right;">${product.unitsSold}</td>'
          '<td style="padding:10px;border:1px solid #d0d7de;text-align:right;">${product.revenue.toStringAsFixed(2)}</td>'
          '<td style="padding:10px;border:1px solid #d0d7de;text-align:right;">${product.profit.toStringAsFixed(2)}</td>'
          '</tr>';
    }).join();

    final analysisHtml =
        '''
<div style="font-family:Arial,sans-serif;color:#111827;line-height:1.5;">
  <div style="padding:18px;border:1px solid #d1d5db;border-radius:16px;background:#ffffff;">
    <h2 style="margin:0 0 8px 0;font-size:22px;">Local Business Snapshot</h2>
    <p style="margin:0 0 16px 0;color:#4b5563;">Offline analysis based on the last 30 days of locally stored sales data.</p>
    <div style="display:flex;gap:12px;flex-wrap:wrap;margin-bottom:16px;">
      <div style="flex:1;min-width:160px;padding:12px;border-radius:12px;background:#f8fafc;border:1px solid #e5e7eb;"><strong>Total Revenue</strong><br>${totalRevenue.toStringAsFixed(2)}</div>
      <div style="flex:1;min-width:160px;padding:12px;border-radius:12px;background:#f8fafc;border:1px solid #e5e7eb;"><strong>Total Profit</strong><br>${totalProfit.toStringAsFixed(2)}</div>
      <div style="flex:1;min-width:160px;padding:12px;border-radius:12px;background:#f8fafc;border:1px solid #e5e7eb;"><strong>Orders</strong><br>$totalOrders</div>
      <div style="flex:1;min-width:160px;padding:12px;border-radius:12px;background:#f8fafc;border:1px solid #e5e7eb;"><strong>Units Sold</strong><br>$totalUnits</div>
    </div>
    <h3 style="margin:0 0 8px 0;font-size:18px;">What this means</h3>
    <p style="margin:0 0 10px 0;">${_escapeHtml(_summarizePrompt(prompt))}</p>
    <p style="margin:0 0 12px 0;">${_escapeHtml(recommendedAction)}</p>
    <h3 style="margin:0 0 8px 0;font-size:18px;">Top Products</h3>
    <table style="width:100%;border-collapse:collapse;">
      <thead>
        <tr>
          <th style="padding:10px;border:1px solid #d0d7de;background:#f3f4f6;text-align:left;">Product</th>
          <th style="padding:10px;border:1px solid #d0d7de;background:#f3f4f6;text-align:right;">Units</th>
          <th style="padding:10px;border:1px solid #d0d7de;background:#f3f4f6;text-align:right;">Revenue</th>
          <th style="padding:10px;border:1px solid #d0d7de;background:#f3f4f6;text-align:right;">Profit</th>
        </tr>
      </thead>
      <tbody>
        $topHtmlRows
      </tbody>
    </table>
  </div>
</div>
''';

    final plainText =
        'Offline analysis for "$prompt": revenue ${totalRevenue.toStringAsFixed(2)}, profit ${totalProfit.toStringAsFixed(2)}, orders $totalOrders, units $totalUnits. $recommendedAction';

    return SalesAnalysisResponse(
      analysisText: plainText,
      analysisHtml: analysisHtml,
      isHtml: true,
      chartSeries: chartSeries,
      sql: '',
      rawDataJson: _prettyJson({
        'mode': 'local',
        'provider': providerName,
        'prompt': prompt,
        'totalRevenue': totalRevenue,
        'totalProfit': totalProfit,
        'totalOrders': totalOrders,
        'totalUnits': totalUnits,
      }),
      provider: providerName,
    );
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

  String _summarizePrompt(String prompt) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return 'The question was empty, so this snapshot summarizes the latest available business data.';
    }
    return 'Question asked: $trimmed';
  }

  String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}

class _LocalProductStat {
  _LocalProductStat({required this.name, this.sku});

  final String name;
  final String? sku;
  int unitsSold = 0;
  double revenue = 0;
  double profit = 0;
}
