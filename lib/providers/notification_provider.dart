import 'package:flutter/material.dart';
import 'package:customer_app/models/notification_model.dart';
import 'package:customer_app/services/notification_service.dart';
import 'package:customer_app/services/fcm_service_v2.dart';
import 'package:customer_app/services/navigation_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  /// Initialize notification system
  /// Called after user login
  Future<void> initialize() async {
    // Set this provider vào FCM service để receive notification
    FcmService.setNotificationProvider(this);

    // Register FCM token with server according to doc
    await FcmService.registerToken();

    // Load initial notifications
    await loadNotifications(refresh: true);
  }

  /// Lấy danh sách thông báo
  /// Được gọi trong notification tab theo doc
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _notifications.clear();
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _notificationService.getNotifications();

      if (result['success'] == true) {
        final List<NotificationModel> newNotifications = result['data'] ?? [];

        if (refresh) {
          _notifications = newNotifications;
        } else {
          _notifications = newNotifications;
        }

        // Cập nhật số thông báo chưa đọc
        _updateUnreadCount();

        notifyListeners();
      } else {
        _setError(result['message'] ?? 'Lỗi tải thông báo');
      }
    } catch (e) {
      _setError('Lỗi kết nối: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Làm mới danh sách thông báo
  Future<void> refreshNotifications() async {
    await loadNotifications(refresh: true);
  }

  /// Đăng ký FCM token theo FCM v1 API specification
  /// Được gọi khi app khởi động, sau khi đăng nhập theo doc
  Future<bool> registerFcmToken(String fcmToken) async {
    try {
      final result = await _notificationService.registerFcmToken(fcmToken);

      if (result['success'] == true) {
        print('✅ FCM token registered successfully via NotificationService');
        return true;
      } else {
        print(
            '❌ Failed to register FCM token via NotificationService: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error registering FCM token via NotificationService: $e');
      return false;
    }
  }

  /// Xóa FCM token theo FCM v1 API specification
  /// Được gọi khi logout theo doc
  Future<bool> removeFcmToken(String fcmToken) async {
    try {
      final result = await _notificationService.removeFcmToken(fcmToken);

      if (result['success'] == true) {
        print('✅ FCM token removed successfully via NotificationService');
        return true;
      } else {
        print(
            '❌ Failed to remove FCM token via NotificationService: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error removing FCM token via NotificationService: $e');
      return false;
    }
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      final result = await _notificationService.markAsRead(notificationId);

      if (result['success'] == true) {
        // Cập nhật local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = _notifications[index];
          // Tạo notification mới với readAt = now
          final updatedNotification = NotificationModel(
            id: notification.id,
            type: notification.type,
            notifiableType: notification.notifiableType,
            notifiableId: notification.notifiableId,
            data: notification.data,
            readAt: DateTime.now(),
            createdAt: notification.createdAt,
            updatedAt: DateTime.now(),
          );

          _notifications[index] = updatedNotification;
          _updateUnreadCount();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Đánh dấu tất cả thông báo đã đọc
  Future<void> markAllAsRead() async {
    try {
      final result = await _notificationService.markAllAsRead();

      if (result['success'] == true) {
        // Cập nhật tất cả notifications thành đã đọc
        final now = DateTime.now();
        _notifications = _notifications.map((notification) {
          if (!notification.isRead) {
            return NotificationModel(
              id: notification.id,
              type: notification.type,
              notifiableType: notification.notifiableType,
              notifiableId: notification.notifiableId,
              data: notification.data,
              readAt: now,
              createdAt: notification.createdAt,
              updatedAt: now,
            );
          }
          return notification;
        }).toList();

        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      final result =
          await _notificationService.deleteNotification(notificationId);

      if (result['success'] == true) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Lấy số lượng thông báo chưa đọc từ server
  Future<void> loadUnreadCount() async {
    try {
      final result = await _notificationService.getUnreadCount();

      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map<String, dynamic> && data.containsKey('count')) {
          _unreadCount = data['count'] as int;
        } else if (data is int) {
          _unreadCount = data;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  /// Gửi test notification (development only)
  Future<void> sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  /// Thêm thông báo mới từ FCM push notification
  /// Được gọi khi nhận được push notification theo FCM v1 format
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _updateUnreadCount();
    notifyListeners();
  }

  /// Handle notification từ FCM message theo doc specification
  void handleFcmNotification(Map<String, dynamic> data) {
    final actionType = data['action_type'];
    final orderId = data['order_id'];

    // Tạo notification model từ FCM data
    try {
      final notificationData = NotificationData(
        key: actionType,
        link: 'customer://Notification',
        orderId: orderId,
      );

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _getNotificationTypeFromAction(actionType),
        notifiableType: 'App\\Models\\User',
        notifiableId: 1, // Current user ID
        data: notificationData,
        readAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      addNotification(notification);
    } catch (e) {
      print('Error handling FCM notification: $e');
    }
  }

  /// Convert action_type to notification type according to doc
  String _getNotificationTypeFromAction(String? actionType) {
    switch (actionType) {
      case 'driver_accepted':
        return 'App\\Notifications\\DriverAcceptedOrder';
      case 'driver_declined':
        return 'App\\Notifications\\DriverDeclinedOrder';
      case 'order_completed':
        return 'App\\Notifications\\OrderHasBeenComplete';
      case 'no_driver_available':
        return 'App\\Notifications\\NoAvailableDriver';
      default:
        return 'App\\Notifications\\GeneralNotification';
    }
  }

  /// Tìm thông báo theo order ID
  List<NotificationModel> getNotificationsByOrderId(String orderId) {
    return _notifications
        .where((notification) => notification.data.orderId == orderId)
        .toList();
  }

  /// Lấy thông báo chưa đọc
  List<NotificationModel> get unreadNotifications {
    return _notifications
        .where((notification) => !notification.isRead)
        .toList();
  }

  /// Lấy thông báo theo loại
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications
        .where((notification) => notification.notificationType == type)
        .toList();
  }

  /// Xử lý notification khi user tap
  /// Navigate đến màn hình liên quan theo doc
  void handleNotificationTap(NotificationModel notification) {
    // Đánh dấu đã đọc nếu chưa đọc
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // Navigate đến màn hình liên quan dựa trên data
    if (notification.data.orderId != null) {
      // Navigate to order detail screen theo doc
      print('Navigate to order detail: ${notification.data.orderId}');
      NavigationService.navigateToOrderDetail(notification.data.orderId!);
    }
  }

  /// Cleanup khi logout
  /// Remove FCM token từ server và clear local data
  Future<void> cleanup() async {
    // Remove FCM token from server
    await FcmService.removeToken();

    // Clear local notification data
    clear();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  /// Reset state khi logout
  void clear() {
    _notifications.clear();
    _unreadCount = 0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
