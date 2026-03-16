import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/notification_model.dart';
import './notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller
            .fetchNotifications(); // Load more when scrolled to the bottom
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value != null &&
            controller.notifications.isEmpty) {
          return Center(child: Text(controller.errorMessage.value!));
        }
        if (controller.notifications.isEmpty) {
          return const Center(child: Text('You have no notifications.'));
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(isRefresh: true),
          child: ListView.builder(
            controller: scrollController,
            itemCount:
                controller.notifications.length + (controller.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.notifications.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final notification = controller.notifications[index];
              return _buildNotificationTile(notification);
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final bool isRead = notification.isRead;
    final icon = _getIconForType(notification.type);

    return Material(
      color: isRead ? Colors.transparent : Colors.teal.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => controller.markAsRead(notification),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isRead ? Colors.grey : Colors.teal, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(notification.message, style: Get.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat.yMMMd().add_jm().format(
                        notification.createdAt.toLocal(),
                      ),
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: Get.theme.primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'low_stock':
        return Icons.warning_amber_rounded;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }
}

