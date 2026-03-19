import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/support_ticket_model.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/data/services/shop_support_api_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class ShopSupportController extends GetxController {
  final ShopSupportApiService _apiService = Get.find<ShopSupportApiService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();

  final RxList<SupportTicket> tickets = <SupportTicket>[].obs;
  final Rxn<SupportTicket> selectedTicket = Rxn<SupportTicket>();
  final RxString statusFilter = 'ALL'.obs;

  final TextEditingController newSubjectController = TextEditingController();
  final TextEditingController newMessageController = TextEditingController();
  final TextEditingController newCustomerNameController =
      TextEditingController();
  final TextEditingController newCustomerEmailController =
      TextEditingController();
  final TextEditingController newCustomerPhoneController =
      TextEditingController();
  final TextEditingController replyController = TextEditingController();

  String _shopId = '';

  @override
  void onInit() {
    super.onInit();
    _resolveShopId();
    if (_shopId.isNotEmpty) {
      loadTickets();
    } else {
      isLoading.value = false;
      errorMessage.value = 'Shop context not found for support module.';
    }
  }

  @override
  void onClose() {
    newSubjectController.dispose();
    newMessageController.dispose();
    newCustomerNameController.dispose();
    newCustomerEmailController.dispose();
    newCustomerPhoneController.dispose();
    replyController.dispose();
    super.onClose();
  }

  void _resolveShopId() {
    final routeShopId = Get.parameters['shopId'];
    final role = (_authService.user.value?.role ?? '').toLowerCase().trim();

    if (routeShopId != null && routeShopId.isNotEmpty) {
      _shopId = routeShopId;
      return;
    }

    if (role == 'staff') {
      final assigned = _authService.user.value?.assignedShopId;
      if (assigned != null && assigned.isNotEmpty) {
        _shopId = assigned;
        return;
      }
    }

    final shopFromAuth = _authService.currentShop.value?.id;
    if (shopFromAuth != null && shopFromAuth.isNotEmpty) {
      _shopId = shopFromAuth;
    }
  }

  Future<void> loadTickets() async {
    if (_shopId.isEmpty) return;

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final loaded = await _apiService.listTickets(
        shopId: _shopId,
        status: statusFilter.value,
      );
      tickets.assignAll(loaded);

      if (loaded.isEmpty) {
        selectedTicket.value = null;
      } else if (selectedTicket.value == null) {
        selectedTicket.value = loaded.first;
      } else {
        final selectedId = selectedTicket.value!.id;
        final refreshed = loaded.where((t) => t.id == selectedId).toList();
        selectedTicket.value = refreshed.isNotEmpty
            ? refreshed.first
            : loaded.first;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      DialogUtils.showError('Failed to load support tickets: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeFilter(String filter) async {
    statusFilter.value = filter;
    await loadTickets();
  }

  void selectTicket(SupportTicket ticket) {
    selectedTicket.value = ticket;
  }

  Future<void> createTicket({required String priority}) async {
    final subject = newSubjectController.text.trim();
    final message = newMessageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      DialogUtils.showError('Subject and message are required.');
      return;
    }

    try {
      isSubmitting.value = true;
      final created = await _apiService.createTicket(
        shopId: _shopId,
        subject: subject,
        message: message,
        priority: priority,
        customerName: newCustomerNameController.text.trim(),
        customerEmail: newCustomerEmailController.text.trim(),
        customerPhone: newCustomerPhoneController.text.trim(),
      );

      newSubjectController.clear();
      newMessageController.clear();
      newCustomerNameController.clear();
      newCustomerEmailController.clear();
      newCustomerPhoneController.clear();

      await loadTickets();
      selectedTicket.value = created;
      DialogUtils.showSuccess('Support ticket created successfully.');
    } catch (e) {
      DialogUtils.showError('Failed to create ticket: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> refreshSelectedTicket() async {
    final current = selectedTicket.value;
    if (current == null) return;

    try {
      final updated = await _apiService.getTicketById(
        shopId: _shopId,
        ticketId: current.id,
      );
      selectedTicket.value = updated;

      final index = tickets.indexWhere((t) => t.id == updated.id);
      if (index >= 0) {
        tickets[index] = updated;
        tickets.refresh();
      }
    } catch (_) {}
  }

  Future<void> sendReply() async {
    final current = selectedTicket.value;
    final content = replyController.text.trim();
    if (current == null || content.isEmpty) return;

    try {
      isSubmitting.value = true;
      await _apiService.replyToTicket(
        shopId: _shopId,
        ticketId: current.id,
        content: content,
      );
      replyController.clear();
      await refreshSelectedTicket();
      await loadTickets();
    } catch (e) {
      DialogUtils.showError('Failed to send reply: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updateStatus({required String status}) async {
    final current = selectedTicket.value;
    if (current == null) return;

    try {
      isSubmitting.value = true;
      final updated = await _apiService.updateTicketStatus(
        shopId: _shopId,
        ticketId: current.id,
        status: status,
        priority: current.priority,
      );
      selectedTicket.value = updated;
      await loadTickets();
      DialogUtils.showSuccess('Ticket status updated to $status.');
    } catch (e) {
      DialogUtils.showError('Failed to update ticket status: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  String formatRoleLabel(String senderRole) {
    final role = senderRole.toUpperCase();
    if (role == 'STAFF') return 'Staff';
    if (role == 'ADMIN') return 'Merchant';
    if (role == 'CUSTOMER') return 'Customer';
    return role;
  }
}
