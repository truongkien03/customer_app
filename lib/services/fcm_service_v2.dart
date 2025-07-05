import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:customer_app/constants/api_constants.dart';
import 'package:customer_app/services/auth_service.dart';
import 'package:customer_app/services/navigation_service.dart';
import 'package:customer_app/providers/notification_provider.dart';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final AuthService _authService = AuthService();
  static NotificationProvider? _notificationProvider;

  static String? _currentToken;

  /// Set notification provider để có thể update UI khi nhận notification
  static void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  /// Initialize FCM according to FCM v1 API specification
  static Future<void> initialize() async {
    print('🔔 Initializing FCM Service (FCM v1 API)...');

    // Request notification permissions
    await _requestPermission();

    // Get initial FCM token
    await _getToken();

    // Listen for token refresh (FCM v1 auto-refresh feature)
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      print('🔄 FCM Token refreshed (FCM v1): ${token.substring(0, 10)}...');
      _currentToken = token;
      _registerTokenWithServer(token);
    });

    // Setup notification handlers according to FCM v1 format
    _setupNotificationHandlers();
  }

  /// Request notification permissions
  static Future<void> _requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('🔔 FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional permission');
      } else {
        print('❌ User denied notification permission');
      }
    } catch (e) {
      print('❌ Error requesting FCM permission: $e');
    }
  }

  /// Get FCM token
  static Future<String?> _getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('📱 FCM Token obtained: ${token.substring(0, 10)}...');
        _currentToken = token;
        return token;
      }
      return null;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Setup notification handlers according to FCM v1 specification
  static void _setupNotificationHandlers() {
    // Handle foreground messages (FCM v1 format)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle foreground messages according to FCM v1 format from documentation
  static void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 Received foreground message (FCM v1): ${message.messageId}');
    print('📱 Title: ${message.notification?.title}');
    print('📱 Body: ${message.notification?.body}');
    print('📱 Data: ${message.data}');

    // Process notification data according to FCM v1 spec from doc
    final data = message.data;
    final actionType = data['action_type'];
    final orderId = data['order_id'];
    final appType = data['app_type'];

    // Validate this is for user app according to doc
    if (appType != 'user') {
      print('⚠️ Notification not for user app, ignoring...');
      return;
    }

    // Add notification to provider if available
    if (_notificationProvider != null) {
      _notificationProvider!.handleFcmNotification(data);
    }

    // Handle different notification types according to documentation
    _processNotificationAction(actionType, orderId);
  }

  /// Handle notification tap according to FCM v1 format
  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped (FCM v1): ${message.messageId}');

    final data = message.data;
    final orderId = data['order_id'];
    final appType = data['app_type'];

    // Validate this is for user app
    if (appType != 'user') {
      print('⚠️ Notification not for user app, ignoring tap...');
      return;
    }

    // Navigate to order detail if order_id is present
    if (orderId != null && orderId.isNotEmpty) {
      NavigationService.navigateToOrderDetail(orderId);
    }
  }

  /// Process notification actions according to documentation
  /// Types: driver_accepted, driver_declined, order_completed, no_driver_available
  static void _processNotificationAction(String? actionType, String? orderId) {
    switch (actionType) {
      case 'driver_accepted':
        print('✅ Driver accepted order: $orderId');
        // Refresh order status, show success message
        break;
      case 'driver_declined':
        print('❌ Driver declined order: $orderId');
        // Show message that driver declined, finding new driver
        break;
      case 'order_completed':
        print('🎉 Order completed: $orderId');
        // Show order completed dialog, option to review
        break;
      case 'no_driver_available':
        print('⚠️ No driver available for order: $orderId');
        // Show no driver available message
        break;
      default:
        print('❓ Unknown notification action type: $actionType');
    }
  }

  /// Register FCM token with server using FCM v1 API endpoint
  /// Called after login according to documentation
  static Future<bool> registerToken() async {
    try {
      if (_currentToken == null) {
        await _getToken();
      }

      if (_currentToken == null) {
        print('❌ No FCM token available to register');
        return false;
      }

      return await _registerTokenWithServer(_currentToken!);
    } catch (e) {
      print('❌ Error registering FCM token: $e');
      return false;
    }
  }

  /// Register token with server using correct API endpoint /fcm/token
  static Future<bool> _registerTokenWithServer(String token) async {
    try {
      // Check if user is authenticated
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        print('⚠️ User not logged in, skipping token registration');
        return false;
      }

      print('📤 Registering FCM token with server (FCM v1)...');

      final headers = await _authService.getHeaders();
      final requestBody = {
        'fcm_token': token,
      };

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.fcmToken}'),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout registering FCM token'),
          );

      print('📤 FCM Register response: ${response.statusCode}');
      print('📤 FCM Register body: ${response.body}');

      // API returns 204 No Content on success according to doc
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ FCM token registered successfully');
        return true;
      }

      print('❌ Failed to register FCM token: ${response.body}');
      return false;
    } catch (e) {
      print('❌ Error registering FCM token with server: $e');
      return false;
    }
  }

  /// Remove FCM token from server using DELETE /fcm/token
  /// Called on logout according to documentation
  static Future<bool> removeToken() async {
    try {
      if (_currentToken == null) {
        print('⚠️ No FCM token to remove');
        return true;
      }

      // Check if user is authenticated
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        print('⚠️ User not logged in, skipping token removal');
        return true; // Consider it success since user is already logged out
      }

      print('📤 Removing FCM token from server...');

      final headers = await _authService.getHeaders();
      final requestBody = {
        'fcm_token': _currentToken!,
      };

      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.fcmToken}'),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout removing FCM token'),
          );

      print('📤 FCM Remove response: ${response.statusCode}');
      print('📤 FCM Remove body: ${response.body}');

      // API returns 204 No Content on success according to doc
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ FCM token removed successfully');
        _currentToken = null;
        return true;
      }

      print('❌ Failed to remove FCM token: ${response.body}');
      return false;
    } catch (e) {
      print('❌ Error removing FCM token: $e');
      return false;
    }
  }

  /// Get current FCM token
  static String? getCurrentToken() {
    return _currentToken;
  }

  /// Check if FCM is initialized and has token
  static bool get isInitialized {
    return _currentToken != null;
  }
}
