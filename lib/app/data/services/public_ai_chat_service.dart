import 'package:get/get.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/core/config/app_config.dart';

/// Public AI chat service - when running in LOCAL_STORAGE_ONLY mode this
/// avoids any outbound requests and returns a clear offline message.

class PublicAiChatService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  String get _baseUrl => '${ApiConstants.baseUrl}/public';

  Future<String> ask(String prompt) async {
    if (_appConfig.localStorageOnly) {
      return 'AI chat is unavailable in LOCAL_STORAGE_ONLY mode.';
    }
    final response = await _connect.post(
      '$_baseUrl/ai-chat',
      {'prompt': prompt},
      headers: const {'Content-Type': 'application/json'},
    );

    if (response.isOk && response.body?['success'] == true) {
      final answer = (response.body?['answer'] as String?)?.trim() ?? '';
      if (answer.isNotEmpty) {
        return answer;
      }
    }

    final message = response.body?['message']?.toString();
    throw Exception(message ?? 'Unable to get AI response right now.');
  }
}
