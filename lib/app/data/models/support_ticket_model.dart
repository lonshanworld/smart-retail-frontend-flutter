class SupportMessage {
  final String id;
  final String ticketId;
  final String senderRole;
  final String content;
  final bool isAdminReply;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderRole,
    required this.content,
    required this.isAdminReply,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: (json['id'] ?? '').toString(),
      ticketId: (json['ticketId'] ?? json['ticket_id'] ?? '').toString(),
      senderRole: (json['senderRole'] ?? json['sender_role'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      isAdminReply: (json['isAdminReply'] ?? json['is_admin_reply']) == true,
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']).toString(),
      ),
    );
  }
}

class SupportTicket {
  final String id;
  final String merchantId;
  final String shopId;
  final String subject;
  final String status;
  final String priority;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SupportMessage> messages;

  SupportTicket({
    required this.id,
    required this.merchantId,
    required this.shopId,
    required this.subject,
    required this.status,
    required this.priority,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    return SupportTicket(
      id: (json['id'] ?? '').toString(),
      merchantId: (json['merchantId'] ?? json['merchant_id'] ?? '').toString(),
      shopId: (json['shopId'] ?? json['shop_id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      priority: (json['priority'] ?? 'MEDIUM').toString(),
      customerName:
          json['customerName']?.toString() ?? json['customer_name']?.toString(),
      customerEmail:
          json['customerEmail']?.toString() ??
          json['customer_email']?.toString(),
      customerPhone:
          json['customerPhone']?.toString() ??
          json['customer_phone']?.toString(),
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']).toString(),
      ),
      updatedAt: DateTime.parse(
        (json['updatedAt'] ?? json['updated_at']).toString(),
      ),
      messages: rawMessages is List
          ? rawMessages
                .map(
                  (m) => SupportMessage.fromJson(Map<String, dynamic>.from(m)),
                )
                .toList()
          : <SupportMessage>[],
    );
  }

  SupportTicket copyWith({
    String? id,
    String? merchantId,
    String? shopId,
    String? subject,
    String? status,
    String? priority,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SupportMessage>? messages,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      shopId: shopId ?? this.shopId,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}
