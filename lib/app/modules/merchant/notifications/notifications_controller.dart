import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/notification_model.dart';
import 'package:smart_retail/app/data/services/notification_api_service.dart';
import 'package:smart_retail/app/data/services/notification_center_service.dart';

class NotificationsController extends GetxController {
  final NotificationApiService _apiService = Get.find<NotificationApiService>();
  final NotificationCenterService _centerService = Get.find<NotificationCenterService>();

  var notifications = <NotificationModel>[].obs;
  var isLoading = false.obs; // Start with false
  var errorMessage = RxnString();

  // Pagination
  var currentPage = 1;
  var hasMore = true;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications(isRefresh: true); // Perform an initial refresh
  }

  Future<void> fetchNotifications({bool isRefresh = false}) async {
    if (isLoading.value) return;
    if (isRefresh) {
      currentPage = 1;
      hasMore = true;
      notifications.clear();
    }
    if (!hasMore) return;

    try {
      isLoading.value = true;
      final response = await _apiService.getNotifications(page: currentPage);
      if (response.data.isEmpty) {
        hasMore = false;
      } else {
        notifications.addAll(response.data);
        currentPage++;
      }
      errorMessage.value = null;
    } catch (e) {
      errorMessage.value = "Error fetching notifications: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(NotificationModel notification) async {
    // Only proceed if the notification is unread
    if (!notification.isRead) {
      try {
        // This API call does not return a value. It succeeds or throws an error.
        await _apiService.markAsRead(notification.id);

        // If no error was thrown, we assume success.
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = notification.copyWith(isRead: true);
          notifications.refresh(); // Refresh the list to update the UI
        }
        // Decrement the global unread count
        _centerService.decrementUnreadCount();
      } catch (e) {
        Get.snackbar("Error", "Failed to mark as read: $e");
      }
    }
  }
}
