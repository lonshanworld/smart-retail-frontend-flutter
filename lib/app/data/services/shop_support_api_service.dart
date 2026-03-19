import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/support_ticket_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';
import 'package:uuid/uuid.dart';

class ShopSupportApiService extends GetxService {
  final GetConnect _connect = GetConnect(timeout: const Duration(seconds: 30));
  final AuthService _authService = Get.find<AuthService>();
  final AppConfig _appConfig = Get.find<AppConfig>();
  final LocalDatabaseService _localDatabaseService =
      Get.find<LocalDatabaseService>();

  String get _baseUrl => '${ApiConstants.baseUrl}/shop/support';

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }
    return {'Authorization': 'Bearer $token'};
  }

  bool _shouldQueue(dynamic error) {
    final text = error.toString().toLowerCase();
    return _appConfig.localStorageOnly ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection') ||
        text.contains('timeout');
  }

  Future<void> _queueOperation({
    required String clientOperationId,
    required String entityType,
    required String action,
    required String endpoint,
    required Map<String, dynamic> payload,
    String method = 'POST',
  }) async {
    await _localDatabaseService.queueOperation({
      'id': clientOperationId,
      'client_operation_id': clientOperationId,
      'entity_type': entityType,
      'action': action,
      'method': method,
      'endpoint': endpoint,
      'payload': payload,
      'headers': {'X-Client-Operation-Id': clientOperationId},
    });
  }

  Future<List<SupportTicket>> listTickets({
    required String shopId,
    String? status,
  }) async {
    final headers = await _authHeaders();
    final query = <String, String>{'shopId': shopId};
    if (status != null && status.trim().isNotEmpty && status != 'ALL') {
      query['status'] = status.trim();
    }

    final response = await _connect.get(
      '$_baseUrl/tickets',
      headers: headers,
      query: query,
    );

    if (response.statusCode == 200 && response.body?['success'] == true) {
      final data = asList(response.body?['data']);
      return data
          .map(
            (item) => SupportTicket.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    throw Exception(response.body?['message'] ?? 'Failed to load tickets');
  }

  Future<SupportTicket> createTicket({
    required String shopId,
    required String subject,
    required String message,
    required String priority,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    final clientOperationId = const Uuid().v4();
    final headers = await _authHeaders();
    final payload = {
      'subject': subject,
      'message': message,
      'priority': priority,
      'clientOperationId': clientOperationId,
      if (customerName != null && customerName.isNotEmpty)
        'customerName': customerName,
      if (customerEmail != null && customerEmail.isNotEmpty)
        'customerEmail': customerEmail,
      if (customerPhone != null && customerPhone.isNotEmpty)
        'customerPhone': customerPhone,
    };

    try {
      final response = await _connect.post(
        '$_baseUrl/tickets?shopId=$shopId',
        payload,
        headers: {
          ...headers,
          'X-Client-Operation-Id': clientOperationId,
        },
      );

      if (response.statusCode == 201 && response.body?['success'] == true) {
        return SupportTicket.fromJson(asMap(response.body?['data']));
      }

      throw Exception(response.body?['message'] ?? 'Failed to create ticket');
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'support_ticket',
          action: 'create',
          endpoint: '$_baseUrl/tickets?shopId=$shopId',
          payload: payload,
        );
        return SupportTicket.fromJson({
          'id': clientOperationId,
          'merchantId': '',
          'shopId': shopId,
          'subject': subject,
          'status': 'OPEN',
          'priority': priority,
          'customerName': customerName,
          'customerEmail': customerEmail,
          'customerPhone': customerPhone,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'messages': <dynamic>[],
        });
      }
      rethrow;
    }
  }

  Future<SupportTicket> getTicketById({
    required String shopId,
    required String ticketId,
  }) async {
    final headers = await _authHeaders();
    final response = await _connect.get(
      '$_baseUrl/tickets/$ticketId',
      headers: headers,
      query: {'shopId': shopId},
    );

    if (response.statusCode == 200 && response.body?['success'] == true) {
      return SupportTicket.fromJson(asMap(response.body?['data']));
    }

    throw Exception(response.body?['message'] ?? 'Failed to load ticket');
  }

  Future<SupportMessage> replyToTicket({
    required String shopId,
    required String ticketId,
    required String content,
  }) async {
    final clientOperationId = const Uuid().v4();
    final headers = await _authHeaders();
    final payload = {'content': content, 'clientOperationId': clientOperationId};

    try {
      final response = await _connect.post(
        '$_baseUrl/tickets/$ticketId/replies?shopId=$shopId',
        payload,
        headers: {
          ...headers,
          'X-Client-Operation-Id': clientOperationId,
        },
      );

      if (response.statusCode == 201 && response.body?['success'] == true) {
        return SupportMessage.fromJson(asMap(response.body?['data']));
      }

      throw Exception(response.body?['message'] ?? 'Failed to send reply');
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'support_reply',
          action: 'create',
          endpoint: '$_baseUrl/tickets/$ticketId/replies?shopId=$shopId',
          payload: payload,
        );
        return SupportMessage.fromJson({
          'id': clientOperationId,
          'ticketId': ticketId,
          'senderRole': 'admin',
          'content': content,
          'isAdminReply': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      rethrow;
    }
  }

  Future<SupportTicket> updateTicketStatus({
    required String shopId,
    required String ticketId,
    required String status,
    required String priority,
  }) async {
    final clientOperationId = const Uuid().v4();
    final headers = await _authHeaders();
    final payload = {
      'status': status,
      'priority': priority,
      'clientOperationId': clientOperationId,
    };

    try {
      final response = await _connect.patch(
        '$_baseUrl/tickets/$ticketId/status?shopId=$shopId',
        payload,
        headers: {
          ...headers,
          'X-Client-Operation-Id': clientOperationId,
        },
      );

      if (response.statusCode == 200 && response.body?['success'] == true) {
        return SupportTicket.fromJson(asMap(response.body?['data']));
      }

      throw Exception(response.body?['message'] ?? 'Failed to update ticket');
    } catch (e) {
      if (_shouldQueue(e)) {
        await _queueOperation(
          clientOperationId: clientOperationId,
          entityType: 'support_ticket',
          action: 'update',
          endpoint: '$_baseUrl/tickets/$ticketId/status?shopId=$shopId',
          payload: payload,
          method: 'PATCH',
        );
        return SupportTicket.fromJson({
          'id': ticketId,
          'merchantId': '',
          'shopId': shopId,
          'subject': 'Pending ticket update',
          'status': status,
          'priority': priority,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'messages': <dynamic>[],
        });
      }
      rethrow;
    }
  }
}
