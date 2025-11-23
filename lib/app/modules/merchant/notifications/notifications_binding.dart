import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/notification_api_service.dart';
import './notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    // The NotificationApiService and NotificationCenterService should be put in a more global binding (e.g., ApplicationBinding)
    // But for this case, we put it here to ensure it's available.
    Get.lazyPut<NotificationApiService>(
      () => NotificationApiService(),
      fenix: true,
    );
    Get.lazyPut<NotificationsController>(() => NotificationsController());
  }
}
