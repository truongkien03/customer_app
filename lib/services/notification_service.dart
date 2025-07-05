import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:customer_app/constants/api_constants.dart';
import 'package:customer_app/models/notification_model.dart';
import 'package:customer_app/services/auth_service.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  /// GET /notifications - Lấy danh sách thông báo
  /// Khi nào sử dụng: Trong notification tab để xem thông báo
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.notifications}';
      print('📢 Getting notifications from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: await _authService.getHeaders(),
      );

      print('📢 Notifications response status: ${response.statusCode}');
      print('📢 Notifications response body: ${response.body}');

      final result = await _authService.processResponse(response);

      if (result['success'] == true) {
        final data = result['data'];

        // Xử lý data theo format API response
        List<dynamic> notificationsList;
        if (data is List) {
          notificationsList = data;
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          notificationsList = data['data'] as List<dynamic>;
        } else {
          notificationsList = [];
        }

        final notifications = notificationsList
            .map((item) =>
                NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        return {
          'success': true,
          'data': notifications,
          'message': 'Lấy thông báo thành công'
        };
      }

      return result;
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  /// POST /fcm/token - Đăng ký FCM token theo FCM v1 API
  /// Khi nào sử dụng: Khi app khởi động, sau khi đăng nhập, khi token refresh
  Future<Map<String, dynamic>> registerFcmToken(String fcmToken) async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.fcmToken}';
      print('📢 Registering FCM token: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: await _authService.getHeaders(),
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      print('📢 Register FCM token response status: ${response.statusCode}');
      print('📢 Register FCM token response body: ${response.body}');

      return await _authService.processResponse(response);
    } catch (e) {
      print('❌ Error registering FCM token: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  /// DELETE /fcm/token - Xóa FCM token theo FCM v1 API
  /// Khi nào sử dụng: Khi logout, khi token expire, khi app uninstall
  Future<Map<String, dynamic>> removeFcmToken(String fcmToken) async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.fcmToken}';
      print('📢 Removing FCM token: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: await _authService.getHeaders(),
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      print('📢 Remove FCM token response status: ${response.statusCode}');
      print('📢 Remove FCM token response body: ${response.body}');

      return await _authService.processResponse(response);
    } catch (e) {
      print('❌ Error removing FCM token: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Helper methods cho xử lý thông báo

  /// Đánh dấu thông báo đã đọc (nếu API hỗ trợ)
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.notifications}/$notificationId/read';
      print('📢 Marking notification as read: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: await _authService.getHeaders(),
      );

      print('📢 Mark as read response status: ${response.statusCode}');
      return await _authService.processResponse(response);
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  /// Đánh dấu tất cả thông báo đã đọc (nếu API hỗ trợ)
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.notifications}/mark-all-read';
      print('📢 Marking all notifications as read: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: await _authService.getHeaders(),
      );

      print('📢 Mark all as read response status: ${response.statusCode}');
      return await _authService.processResponse(response);
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  /// Xóa thông báo (nếu API hỗ trợ)
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.notifications}/$notificationId';
      print('📢 Deleting notification: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: await _authService.getHeaders(),
      );

      print('📢 Delete notification response status: ${response.statusCode}');
      return await _authService.processResponse(response);
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  /// Lấy số lượng thông báo chưa đọc (nếu API hỗ trợ)
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.notifications}/unread-count';
      print('📢 Getting unread count: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: await _authService.getHeaders(),
      );

      print('📢 Unread count response status: ${response.statusCode}');
      return await _authService.processResponse(response);
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  /// Test notification (development only)
  Future<Map<String, dynamic>> sendTestNotification() async {
    try {
      final url = '${ApiConstants.baseUrl}/fcm/test-notification';
      print('📢 Sending test notification: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: await _authService.getHeaders(),
        body: jsonEncode({
          'title': 'Test Notification',
          'body': 'This is a test notification from the app',
          'data': {
            'test': true,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString()
          }
        }),
      );

      print('📢 Test notification response status: ${response.statusCode}');
      return await _authService.processResponse(response);
    } catch (e) {
      print('❌ Error sending test notification: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }
}
