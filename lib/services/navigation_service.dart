import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  // Navigate to order detail screen
  static Future<void> navigateToOrderDetail(String orderId) async {
    try {
      if (navigator != null) {
        await navigator!.pushNamed('/order-detail', arguments: orderId);
      }
    } catch (e) {
      print('❌ Error navigating to order detail: $e');
    }
  }

  // Navigate to orders list screen
  static Future<void> navigateToOrdersList() async {
    try {
      if (navigator != null) {
        await navigator!.pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
        // After navigating to home, switch to orders tab (index 1)
        // This would require additional implementation in MainScreen
      }
    } catch (e) {
      print('❌ Error navigating to orders list: $e');
    }
  }

  // Navigate to home screen
  static Future<void> navigateToHome() async {
    try {
      if (navigator != null) {
        await navigator!.pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error navigating to home: $e');
    }
  }

  // Show notification dialog when app is in foreground
  static void showNotificationDialog({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final context = navigator?.context;
    if (context != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Đóng'),
              ),
              if (data != null && data['order_id'] != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    navigateToOrderDetail(data['order_id']);
                  },
                  child: const Text('Xem đơn hàng'),
                ),
            ],
          );
        },
      );
    }
  }

  // Show snackbar notification
  static void showSnackBarNotification(String message) {
    final context = navigator?.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Đóng',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
}
