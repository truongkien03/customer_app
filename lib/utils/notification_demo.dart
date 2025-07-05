import 'package:customer_app/models/notification_model.dart';

/// Demo utility class để tạo thông báo mẫu cho testing
class NotificationDemo {
  /// Tạo danh sách thông báo mẫu theo format API documentation
  static List<NotificationModel> createSampleNotifications() {
    final now = DateTime.now();

    return [
      // Driver accepted order notification
      NotificationModel(
        id: 'demo-1',
        type: 'App\\Notifications\\DriverAcceptedOrder',
        notifiableType: 'App\\Models\\User',
        notifiableId: 1,
        data: NotificationData(
          key: 'AcceptOder',
          link: 'customer://Notification',
          orderId: '123',
        ),
        readAt: null, // Chưa đọc
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),

      // Order completed notification (đã đọc)
      NotificationModel(
        id: 'demo-2',
        type: 'App\\Notifications\\OrderHasBeenComplete',
        notifiableType: 'App\\Models\\User',
        notifiableId: 1,
        data: NotificationData(
          key: 'OrderComplete',
          link: 'customer://Notification',
          orderId: '122',
        ),
        readAt: now.subtract(const Duration(minutes: 30)),
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),

      // Driver declined notification
      NotificationModel(
        id: 'demo-3',
        type: 'App\\Notifications\\DriverDeclinedOrder',
        notifiableType: 'App\\Models\\User',
        notifiableId: 1,
        data: NotificationData(
          key: 'DriverDeclined',
          link: 'customer://Notification',
          orderId: '124',
        ),
        readAt: null, // Chưa đọc
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),

      // No driver available notification
      NotificationModel(
        id: 'demo-4',
        type: 'App\\Notifications\\NoAvailableDriver',
        notifiableType: 'App\\Models\\User',
        notifiableId: 1,
        data: NotificationData(
          key: 'NoDriver',
          link: 'customer://Notification',
          orderId: '125',
        ),
        readAt: now.subtract(const Duration(hours: 3)),
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
    ];
  }

  /// Tạo FCM message mẫu theo format documentation
  static Map<String, dynamic> createSampleFcmMessage(
      String actionType, String orderId) {
    return {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'app_type': 'user',
      'order_id': orderId,
      'action_type': actionType,
    };
  }

  /// Tạo notification từ FCM data mẫu
  static NotificationModel createNotificationFromFcmData(
      Map<String, dynamic> fcmData) {
    final actionType = fcmData['action_type'];
    final orderId = fcmData['order_id'];

    String notificationType;
    switch (actionType) {
      case 'driver_accepted':
        notificationType = 'App\\Notifications\\DriverAcceptedOrder';
        break;
      case 'driver_declined':
        notificationType = 'App\\Notifications\\DriverDeclinedOrder';
        break;
      case 'order_completed':
        notificationType = 'App\\Notifications\\OrderHasBeenComplete';
        break;
      case 'no_driver_available':
        notificationType = 'App\\Notifications\\NoAvailableDriver';
        break;
      default:
        notificationType = 'App\\Notifications\\GeneralNotification';
    }

    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: notificationType,
      notifiableType: 'App\\Models\\User',
      notifiableId: 1,
      data: NotificationData(
        key: actionType,
        link: 'customer://Notification',
        orderId: orderId,
      ),
      readAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
