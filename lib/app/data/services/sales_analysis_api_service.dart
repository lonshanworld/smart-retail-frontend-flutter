import 'package:get/get.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';

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
  Future<String> getSalesAnalysis(String prompt) async {
    print('🔍 [AI SALES API] Sending request to backend...');
    print('   Prompt: $prompt');

    final response = await _connect.post(
      '$_baseUrl/ai-analysis',
      headers: await _getHeaders(),
      {'prompt': prompt},
    );

    print('📥 [AI SALES API] Response status: ${response.statusCode}');
    print('📥 [AI SALES API] Response body: ${response.body}');

    if (response.isOk && response.body['success'] == true) {
      final analysis = response.body['analysis'] as String;
      print('✅ [AI SALES API] Analysis received (${analysis.length} chars)');
      
      // Optionally log the SQL and data for debugging
      if (response.body['sql'] != null) {
        print('   SQL: ${response.body['sql']}');
      }
      
      return analysis;
    } else {
      final errorMsg = response.body?['message'] ?? 'Failed to get AI analysis';
      print('❌ [AI SALES API] Error: $errorMsg');
      throw Exception(errorMsg);
    }
  }
}
