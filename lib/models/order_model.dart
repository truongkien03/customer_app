import 'package:flutter/material.dart';

class OrderModel {
  final String? id;
  final int? userId;
  final int? driverId;
  final AddressData? fromAddress;
  final AddressData? toAddress;
  final List<OrderItem>? items;
  final double? shippingCost;
  final double? distance;
  final double? discount;
  final int? statusCode;
  final DateTime? completedAt;
  final DateTime? driverAcceptAt;
  final String? userNote;
  final String? driverNote;
  final int? driverRate;
  final ReceiverData? receiver;
  final int? isSharable;
  final List<int>? exceptDrivers;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? customerAvatar;
  final String? customerName;
  final DriverData? driver;

  OrderModel({
    this.id,
    this.userId,
    this.driverId,
    this.fromAddress,
    this.toAddress,
    this.items,
    this.shippingCost,
    this.distance,
    this.discount,
    this.statusCode,
    this.completedAt,
    this.driverAcceptAt,
    this.userNote,
    this.driverNote,
    this.driverRate,
    this.receiver,
    this.isSharable,
    this.exceptDrivers,
    this.createdAt,
    this.updatedAt,
    this.customerAvatar,
    this.customerName,
    this.driver,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    try {
      return OrderModel(
        id: json['id']?.toString(),
        userId: json['user_id'] is int
            ? json['user_id']
            : int.tryParse(json['user_id']?.toString() ?? ''),
        driverId: json['driver_id'] is int
            ? json['driver_id']
            : int.tryParse(json['driver_id']?.toString() ?? ''),
        fromAddress: json['from_address'] is Map<String, dynamic>
            ? AddressData.fromJson(json['from_address'])
            : null,
        toAddress: json['to_address'] is Map<String, dynamic>
            ? AddressData.fromJson(json['to_address'])
            : null,
        items: json['items'] is List
            ? (json['items'] as List)
                .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
                .toList()
            : null,
        shippingCost: _parseDouble(json['shipping_cost']),
        distance: _parseDouble(json['distance']),
        discount: _parseDouble(json['discount']),
        statusCode: json['status_code'] is int
            ? json['status_code']
            : int.tryParse(json['status_code']?.toString() ?? ''),
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'].toString())
            : null,
        driverAcceptAt: json['driver_accept_at'] != null
            ? DateTime.tryParse(json['driver_accept_at'].toString())
            : null,
        userNote: json['user_note']?.toString(),
        driverNote: json['driver_note']?.toString(),
        driverRate: json['driver_rate'] is int
            ? json['driver_rate']
            : int.tryParse(json['driver_rate']?.toString() ?? ''),
        receiver: json['receiver'] is Map<String, dynamic>
            ? ReceiverData.fromJson(json['receiver'])
            : null,
        isSharable: json['is_sharable'] is int
            ? json['is_sharable']
            : int.tryParse(json['is_sharable']?.toString() ?? '0'),
        exceptDrivers: json['except_drivers'] is List
            ? (json['except_drivers'] as List)
                .map((id) => int.tryParse(id.toString()) ?? 0)
                .toList()
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
        customerAvatar: json['customerAvatar']?.toString(),
        customerName: json['customerName']?.toString(),
        driver: json['driver'] is Map<String, dynamic>
            ? DriverData.fromJson(json['driver'])
            : null,
      );
    } catch (e) {
      print('Error parsing OrderModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Getter cho status name theo documentation
  String get statusName {
    switch (statusCode) {
      case 1:
        return 'Chờ tài xế chấp nhận';
      case 2:
        return 'Đang giao hàng';
      case 3:
        return 'Đã hoàn thành';
      case 4:
        return 'Người dùng hủy';
      case 5:
        return 'Tài xế hủy';
      case 6:
        return 'Hệ thống hủy';
      default:
        return 'Không xác định';
    }
  }

  // Getter cho status color
  get statusColor {
    switch (statusCode) {
      case 1:
        return const Color(0xFFFF9800); // Orange - Pending
      case 2:
        return const Color(0xFF2196F3); // Blue - In process
      case 3:
        return const Color(0xFF4CAF50); // Green - Completed
      case 4:
      case 5:
      case 6:
        return const Color(0xFFF44336); // Red - Cancelled
      default:
        return const Color(0xFF757575); // Grey - Unknown
    }
  }

  // Getter kiểm tra có thể đánh giá tài xế không
  bool get canReviewDriver {
    return statusCode == 3 && driverId != null && driverRate == null;
  }

  // Helper method để parse double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'driver_id': driverId,
      'from_address': fromAddress?.toJson(),
      'to_address': toAddress?.toJson(),
      'items': items?.map((item) => item.toJson()).toList(),
      'shipping_cost': shippingCost,
      'distance': distance,
      'discount': discount,
      'status_code': statusCode,
      'completed_at': completedAt?.toIso8601String(),
      'driver_accept_at': driverAcceptAt?.toIso8601String(),
      'user_note': userNote,
      'driver_note': driverNote,
      'driver_rate': driverRate,
      'receiver': receiver?.toJson(),
      'is_sharable': isSharable,
      'except_drivers': exceptDrivers,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'customerAvatar': customerAvatar,
      'customerName': customerName,
      'driver': driver?.toJson(),
    };
  }
}

class OrderItem {
  final String? name;
  final int? quantity;
  final double? price;
  final String? note;

  OrderItem({
    this.name,
    this.quantity,
    this.price,
    this.note,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name']?.toString(),
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '1'),
      price: OrderModel._parseDouble(json['price']),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'note': note,
    };
  }
}

class AddressData {
  final double? lat;
  final double? lon;
  final String? desc;

  AddressData({
    this.lat,
    this.lon,
    this.desc,
  });

  factory AddressData.fromJson(Map<String, dynamic> json) {
    return AddressData(
      lat: OrderModel._parseDouble(json['lat']),
      lon: OrderModel._parseDouble(json['lon']),
      desc: json['desc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      'desc': desc,
    };
  }
}

class ReceiverData {
  final String? name;
  final String? phone;
  final String? note;

  ReceiverData({
    this.name,
    this.phone,
    this.note,
  });

  factory ReceiverData.fromJson(Map<String, dynamic> json) {
    return ReceiverData(
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'note': note,
    };
  }
}

class DriverData {
  final int? id;
  final String? name;
  final String? phoneNumber;
  final String? email;
  final String? avatar;
  final double? reviewRate;
  final DriverLocation? currentLocation;
  final int? status;

  DriverData({
    this.id,
    this.name,
    this.phoneNumber,
    this.email,
    this.avatar,
    this.reviewRate,
    this.currentLocation,
    this.status,
  });

  factory DriverData.fromJson(Map<String, dynamic> json) {
    return DriverData(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
      reviewRate: OrderModel._parseDouble(json['review_rate']),
      currentLocation: json['current_location'] is Map<String, dynamic>
          ? DriverLocation.fromJson(json['current_location'])
          : null,
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status']?.toString() ?? ''),
    );
  }

  // Getter cho driver status name theo documentation
  String get statusName {
    switch (status) {
      case 1:
        return 'Sẵn sàng nhận đơn';
      case 2:
        return 'Offline';
      case 3:
        return 'Đang giao hàng';
      default:
        return 'Không xác định';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'avatar': avatar,
      'review_rate': reviewRate,
      'current_location': currentLocation?.toJson(),
      'status': status,
    };
  }
}

class DriverLocation {
  final double? lat;
  final double? lon;

  DriverLocation({
    this.lat,
    this.lon,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      lat: OrderModel._parseDouble(json['lat']),
      lon: OrderModel._parseDouble(json['lon']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
    };
  }
}

enum OrderStatus {
  pending,
  inprocess,
  completed,
  cancelled;

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'inprocess':
      case 'in_process':
        return OrderStatus.inprocess;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static OrderStatus fromCode(int statusCode) {
    switch (statusCode) {
      case 0: // pending
        return OrderStatus.pending;
      case 1: // driver_accepted
      case 2: // in_transit
      case 3: // delivered
        return OrderStatus.inprocess;
      case 4: // completed
        return OrderStatus.completed;
      case 5: // cancelled
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.inprocess:
        return 'inprocess';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Đang chờ tài xế';
      case OrderStatus.inprocess:
        return 'Đang giao hàng';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
