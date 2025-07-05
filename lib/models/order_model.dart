class OrderModel {
  final String? id;
  final String? fromAddress;
  final double? fromLat;
  final double? fromLon;
  final String? toAddress;
  final double? toLat;
  final double? toLon;
  final List<OrderItem>? items;
  final ReceiverInfo? receiver;
  final String? userNote;
  final String? discount;
  final double? estimatedFee;
  final double? distance;
  final int? estimatedTime;
  final OrderStatus? status;
  final String? driverId;
  final DriverInfo? driver;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderModel({
    this.id,
    this.fromAddress,
    this.fromLat,
    this.fromLon,
    this.toAddress,
    this.toLat,
    this.toLon,
    this.items,
    this.receiver,
    this.userNote,
    this.discount,
    this.estimatedFee,
    this.distance,
    this.estimatedTime,
    this.status,
    this.driverId,
    this.driver,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse địa chỉ từ object hoặc string
      String? fromAddressDesc;
      double? fromLat;
      double? fromLon;

      if (json['from_address'] is Map) {
        final fromAddr = json['from_address'] as Map<String, dynamic>;
        fromAddressDesc = fromAddr['desc']?.toString();
        fromLat = _parseDouble(fromAddr['lat']);
        fromLon = _parseDouble(fromAddr['lon']);
      } else {
        fromAddressDesc = json['from_address']?.toString();
        fromLat = _parseDouble(json['from_lat']);
        fromLon = _parseDouble(json['from_lon']);
      }

      String? toAddressDesc;
      double? toLat;
      double? toLon;

      if (json['to_address'] is Map) {
        final toAddr = json['to_address'] as Map<String, dynamic>;
        toAddressDesc = toAddr['desc']?.toString();
        toLat = _parseDouble(toAddr['lat']);
        toLon = _parseDouble(toAddr['lon']);
      } else {
        toAddressDesc = json['to_address']?.toString();
        toLat = _parseDouble(json['to_lat']);
        toLon = _parseDouble(json['to_lon']);
      }

      // Parse status từ status_code hoặc status
      OrderStatus? orderStatus;
      if (json['status_code'] != null) {
        orderStatus = OrderStatus.fromCode(
            int.tryParse(json['status_code'].toString()) ?? 0);
      } else if (json['status'] != null) {
        orderStatus = OrderStatus.fromString(json['status'].toString());
      }

      return OrderModel(
        id: json['id']?.toString(),
        fromAddress: fromAddressDesc,
        fromLat: fromLat,
        fromLon: fromLon,
        toAddress: toAddressDesc,
        toLat: toLat,
        toLon: toLon,
        items: json['items'] != null
            ? (json['items'] as List)
                .map((item) => OrderItem.fromJson(item))
                .toList()
            : null,
        receiver: json['receiver'] != null
            ? ReceiverInfo.fromJson(json['receiver'])
            : null,
        userNote: json['user_note']?.toString(),
        discount: json['discount']?.toString(),
        // Ưu tiên shipping_fee từ API mới, fallback về shipping_cost và estimated_fee cũ
        estimatedFee: _parseDouble(json['shipping_fee']) ??
            _parseDouble(json['shipping_cost']) ??
            _parseDouble(json['estimated_fee']),
        distance: _parseDouble(json['distance']),
        estimatedTime: json['estimated_time'] != null
            ? int.tryParse(json['estimated_time'].toString())
            : null,
        status: orderStatus,
        driverId: json['driver_id']?.toString(),
        driver:
            json['driver'] != null ? DriverInfo.fromJson(json['driver']) : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );
    } catch (e) {
      print('Error parsing OrderModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_address': fromAddress,
      'from_lat': fromLat,
      'from_lon': fromLon,
      'to_address': toAddress,
      'to_lat': toLat,
      'to_lon': toLon,
      'items': items?.map((item) => item.toJson()).toList(),
      'receiver': receiver?.toJson(),
      'user_note': userNote,
      'discount': discount,
      'estimated_fee': estimatedFee,
      'distance': distance,
      'estimated_time': estimatedTime,
      'status': status?.toString(),
      'driver_id': driverId,
      'driver': driver?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double? price;
  final String? note;

  OrderItem({
    required this.name,
    required this.quantity,
    this.price,
    this.note,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
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

class ReceiverInfo {
  final String name;
  final String phoneNumber;

  ReceiverInfo({
    required this.name,
    required this.phoneNumber,
  });

  factory ReceiverInfo.fromJson(Map<String, dynamic> json) {
    return ReceiverInfo(
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
    };
  }
}

class DriverInfo {
  final String? id;
  final String? name;
  final String? phoneNumber;
  final String? avatar;
  final String? vehiclePlate;
  final double? rating;

  DriverInfo({
    this.id,
    this.name,
    this.phoneNumber,
    this.avatar,
    this.vehiclePlate,
    this.rating,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      avatar: json['avatar']?.toString(),
      vehiclePlate: json['vehicle_plate']?.toString(),
      rating: OrderModel._parseDouble(json['rating']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'avatar': avatar,
      'vehicle_plate': vehiclePlate,
      'rating': rating,
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
