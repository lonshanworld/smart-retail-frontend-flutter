import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/support_ticket_model.dart';
import 'package:smart_retail/app/modules/shop_dashboard/widgets/shop_main_scaffold.dart';
import 'package:smart_retail/app/modules/shop_support/shop_support_controller.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class ShopSupportView extends GetView<ShopSupportController> {
  const ShopSupportView({super.key});

  static const List<String> _statusOptions = <String>[
    'ALL',
    'OPEN',
    'IN_PROGRESS',
    'CLOSED',
  ];

  static const List<String> _priorityOptions = <String>[
    'LOW',
    'MEDIUM',
    'HIGH',
  ];

  @override
  Widget build(BuildContext context) {
    return ShopMainScaffold(
      title: 'Support',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTicketDialog(context),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New Ticket'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null &&
            controller.tickets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                controller.errorMessage.value!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        return Column(
          children: [
            _buildToolbar(context),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return _buildMobileLayout();
                  }
                  return _buildDesktopLayout();
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusOptions.map((status) {
              return Obx(() {
                final isSelected = controller.statusFilter.value == status;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(status == 'IN_PROGRESS' ? 'IN PROGRESS' : status),
                  onSelected: (_) => controller.changeFilter(status),
                );
              });
            }).toList(),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Refresh',
          onPressed: controller.loadTickets,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(width: 380, child: _buildTicketList()),
        const SizedBox(width: 12),
        Expanded(child: _buildTicketDetail()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Obx(() {
      final selected = controller.selectedTicket.value;
      if (selected == null) {
        return _buildTicketList();
      }

      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => controller.selectedTicket.value = null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to tickets'),
            ),
          ),
          Expanded(child: _buildTicketDetail()),
        ],
      );
    });
  }

  Widget _buildTicketList() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Obx(() {
        if (controller.tickets.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No support tickets yet. Create your first ticket.'),
            ),
          );
        }

        return ListView.separated(
          itemCount: controller.tickets.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final ticket = controller.tickets[index];
            final isSelected = controller.selectedTicket.value?.id == ticket.id;
            return Material(
              color: isSelected ? AppColors.shop.shade50 : Colors.transparent,
              child: ListTile(
                title: Text(
                  ticket.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${ticket.status} • ${DateFormat.yMMMd().add_jm().format(ticket.updatedAt)}',
                  maxLines: 1,
                ),
                trailing: _statusBadge(ticket.status),
                onTap: () => controller.selectTicket(ticket),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildTicketDetail() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Obx(() {
        final ticket = controller.selectedTicket.value;
        if (ticket == null) {
          return const Center(child: Text('Select a ticket to view details.'));
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.shop.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusBadge(ticket.status),
                      _priorityBadge(ticket.priority),
                      InputChip(
                        label: Text(
                          'Created ${DateFormat.yMMMd().add_jm().format(ticket.createdAt)}',
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () => controller.updateStatus(status: 'OPEN'),
                        child: const Text('Mark OPEN'),
                      ),
                      OutlinedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () => controller.updateStatus(
                                status: 'IN_PROGRESS',
                              ),
                        child: const Text('Mark IN PROGRESS'),
                      ),
                      OutlinedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () => controller.updateStatus(status: 'CLOSED'),
                        child: const Text('Mark CLOSED'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ticket.messages.length,
                itemBuilder: (_, index) {
                  final msg = ticket.messages[index];
                  return _messageBubble(msg);
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.replyController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write a reply...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.sendReply,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _messageBubble(SupportMessage message) {
    final isStaffSide =
        message.senderRole.toUpperCase() == 'STAFF' ||
        message.senderRole.toUpperCase() == 'ADMIN';

    return Align(
      alignment: isStaffSide ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isStaffSide ? AppColors.shop.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    controller.formatRoleLabel(message.senderRole),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isStaffSide
                          ? AppColors.shop.shade800
                          : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat.MMMd().add_jm().format(message.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(message.content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'CLOSED':
        color = Colors.grey;
        break;
      case 'IN_PROGRESS':
        color = Colors.orange;
        break;
      case 'OPEN':
      default:
        color = Colors.green;
        break;
    }
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status.toUpperCase()),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      labelStyle: TextStyle(color: color.shade700OrSelf),
    );
  }

  Widget _priorityBadge(String priority) {
    Color color;
    switch (priority.toUpperCase()) {
      case 'HIGH':
        color = Colors.red;
        break;
      case 'LOW':
        color = Colors.blue;
        break;
      case 'MEDIUM':
      default:
        color = Colors.amber;
        break;
    }
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('Priority ${priority.toUpperCase()}'),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      labelStyle: TextStyle(color: color.shade700OrSelf),
    );
  }

  void _showCreateTicketDialog(BuildContext context) {
    var selectedPriority = 'MEDIUM';

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Support Ticket'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller.newSubjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.newMessageController,
                        minLines: 4,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: _priorityOptions
                            .map(
                              (p) => DropdownMenuItem<String>(
                                value: p,
                                child: Text(p),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => selectedPriority = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.newCustomerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.newCustomerEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Email (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.newCustomerPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Phone (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    await controller.createTicket(priority: selectedPriority);
                    if (context.mounted && !controller.isSubmitting.value) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

extension on Color {
  Color get shade700OrSelf {
    if (this is MaterialColor) {
      return (this as MaterialColor).shade700;
    }
    return this;
  }
}
