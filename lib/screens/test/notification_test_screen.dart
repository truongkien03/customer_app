import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/providers/notification_provider.dart';
import 'package:customer_app/services/fcm_service_v2.dart';
import 'package:customer_app/utils/notification_demo.dart';

/// Screen để test notification system theo documentation
class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notification System'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Test Notification System theo API Documentation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // FCM Status
            _buildFcmStatus(),
            const SizedBox(height: 20),

            // Test buttons
            _buildTestButtons(context),
            const SizedBox(height: 20),

            // Notification count
            _buildNotificationCount(),
          ],
        ),
      ),
    );
  }

  Widget _buildFcmStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FCM Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
                'Token: ${FcmService.getCurrentToken()?.substring(0, 20) ?? 'No token'}...'),
            Text('Initialized: ${FcmService.isInitialized ? 'Yes' : 'No'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons(BuildContext context) {
    return Column(
      children: [
        // Test load notifications
        ElevatedButton(
          onPressed: () {
            context.read<NotificationProvider>().refreshNotifications();
          },
          child: const Text('Load Notifications từ API'),
        ),
        const SizedBox(height: 8),

        // Test add demo notifications
        ElevatedButton(
          onPressed: () {
            final provider = context.read<NotificationProvider>();
            final demoNotifications =
                NotificationDemo.createSampleNotifications();

            for (final notification in demoNotifications) {
              provider.addNotification(notification);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Đã thêm ${demoNotifications.length} thông báo demo')),
            );
          },
          child: const Text('Thêm Demo Notifications'),
        ),
        const SizedBox(height: 8),

        // Test simulate FCM driver accepted
        ElevatedButton(
          onPressed: () {
            final provider = context.read<NotificationProvider>();
            final fcmData = NotificationDemo.createSampleFcmMessage(
                'driver_accepted', '126');
            provider.handleFcmNotification(fcmData);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mô phỏng FCM: Tài xế chấp nhận')),
            );
          },
          child: const Text('Mô phỏng: Tài xế chấp nhận'),
        ),
        const SizedBox(height: 8),

        // Test simulate FCM order completed
        ElevatedButton(
          onPressed: () {
            final provider = context.read<NotificationProvider>();
            final fcmData = NotificationDemo.createSampleFcmMessage(
                'order_completed', '127');
            provider.handleFcmNotification(fcmData);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Mô phỏng FCM: Đơn hàng hoàn thành')),
            );
          },
          child: const Text('Mô phỏng: Đơn hàng hoàn thành'),
        ),
        const SizedBox(height: 8),

        // Test register FCM token
        ElevatedButton(
          onPressed: () async {
            final success = await FcmService.registerToken();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success
                    ? 'Đăng ký FCM token thành công'
                    : 'Đăng ký FCM token thất bại'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          },
          child: const Text('Test Register FCM Token'),
        ),
        const SizedBox(height: 8),

        // Test clear all notifications
        ElevatedButton(
          onPressed: () {
            context.read<NotificationProvider>().clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa tất cả thông báo local')),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Xóa tất cả thông báo local'),
        ),
      ],
    );
  }

  Widget _buildNotificationCount() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Tổng số thông báo: ${provider.notifications.length}'),
                Text('Chưa đọc: ${provider.unreadCount}'),
                Text('Loading: ${provider.isLoading ? 'Yes' : 'No'}'),
                if (provider.error != null)
                  Text('Error: ${provider.error}',
                      style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        );
      },
    );
  }
}
