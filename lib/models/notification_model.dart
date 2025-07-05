import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String type;
  final String notifiableType;
  final int notifiableId;
  final NotificationData data;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.notifiableType,
    required this.notifiableId,
    required this.data,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      notifiableType: json['notifiable_type'] as String,
      notifiableId: json['notifiable_id'] as int,
      data: NotificationData.fromJson(json['data'] as Map<String, dynamic>),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'notifiable_type': notifiableType,
      'notifiable_id': notifiableId,
      'data': data.toJson(),
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getter cho trạng thái đã đọc
  bool get isRead => readAt != null;

  // Getter cho loại thông báo theo doc
  NotificationType get notificationType {
    switch (type) {
      case 'App\\Notifications\\DriverAcceptedOrder':
        return NotificationType.driverAccepted;
      case 'App\\Notifications\\DriverDeclinedOrder':
        return NotificationType.driverDeclined;
      case 'App\\Notifications\\OrderHasBeenComplete':
        return NotificationType.orderCompleted;
      case 'App\\Notifications\\NoAvailableDriver':
        return NotificationType.noAvailableDriver;
      default:
        return NotificationType.unknown;
    }
  }

  // Getter cho tiêu đề thông báo theo doc
  String get title {
    switch (notificationType) {
      case NotificationType.driverAccepted:
        return 'Tài xế đã chấp nhận đơn hàng';
      case NotificationType.driverDeclined:
        return 'Tài xế từ chối đơn hàng';
      case NotificationType.orderCompleted:
        return 'Đơn hàng đã hoàn thành';
      case NotificationType.noAvailableDriver:
        return 'Không có tài xế trong khu vực';
      case NotificationType.unknown:
        return 'Thông báo mới';
    }
  }

  // Getter cho nội dung thông báo theo doc
  String get message {
    switch (notificationType) {
      case NotificationType.driverAccepted:
        return 'Đơn hàng #${data.orderId ?? ''} đã được tài xế chấp nhận';
      case NotificationType.driverDeclined:
        return 'Đơn hàng #${data.orderId ?? ''} bị tài xế từ chối';
      case NotificationType.orderCompleted:
        return 'Đơn hàng #${data.orderId ?? ''} đã được giao thành công';
      case NotificationType.noAvailableDriver:
        return 'Không tìm thấy tài xế sẵn sàng cho đơn hàng #${data.orderId ?? ''}';
      case NotificationType.unknown:
        return 'Bạn có thông báo mới';
    }
  }

  // Getter cho icon thông báo
  String get icon {
    switch (notificationType) {
      case NotificationType.driverAccepted:
        return '✅';
      case NotificationType.driverDeclined:
        return '❌';
      case NotificationType.orderCompleted:
        return '🎉';
      case NotificationType.noAvailableDriver:
        return '⚠️';
      case NotificationType.unknown:
        return '📢';
    }
  }

  // Getter cho màu sắc thông báo
  get color {
    switch (notificationType) {
      case NotificationType.driverAccepted:
        return const Color(0xFF4CAF50); // Green
      case NotificationType.driverDeclined:
        return const Color(0xFFF44336); // Red
      case NotificationType.orderCompleted:
        return const Color(0xFF2196F3); // Blue
      case NotificationType.noAvailableDriver:
        return const Color(0xFFFF9800); // Orange
      case NotificationType.unknown:
        return const Color(0xFF757575); // Grey
    }
  }
}

class NotificationData {
  final String? key;
  final String? link;
  final String? orderId; // API sử dụng 'oderId' theo doc

  NotificationData({
    this.key,
    this.link,
    this.orderId,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      key: json['key'] as String?,
      link: json['link'] as String?,
      orderId: json['oderId'] as String?, // API sử dụng 'oderId' theo doc
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'link': link,
      'oderId': orderId, // API sử dụng 'oderId' theo doc
    };
  }
}

enum NotificationType {
  driverAccepted, // Tài xế đã chấp nhận đơn hàng
  driverDeclined, // Tài xế từ chối đơn hàng
  orderCompleted, // Đơn hàng đã hoàn thành
  noAvailableDriver, // Không có tài xế trong khu vực
  unknown,
}

class NotificationResponse {
  final List<NotificationModel> data;

  NotificationResponse({required this.data});

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>;
    final notifications = dataList
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return NotificationResponse(data: notifications);
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((notification) => notification.toJson()).toList(),
    };
  }
}
