import 'package:get/get.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';

class PublicAiChatService extends GetxService {
  final GetConnect _connect = Get.find<GetConnect>();

  String get _baseUrl => '${ApiConstants.baseUrl}/public';

  Future<String> ask(String prompt) async {
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
