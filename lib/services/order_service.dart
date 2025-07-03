import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:customer_app/constants/api_constants.dart';
import 'package:customer_app/models/order_model.dart';
import 'package:customer_app/models/address_model.dart';
import 'package:customer_app/services/auth_service.dart';

class OrderService {
  final AuthService _authService = AuthService();

  // Header cho API requests
  Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await _authService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Ước tính phí giao hàng
  Future<Map<String, dynamic>> estimateDeliveryFee({
    required AddressModel fromAddress,
    required AddressModel toAddress,
  }) async {
    try {
      print('🚚 Estimating delivery fee...');
      print(
          'From: ${fromAddress.desc} (${fromAddress.lat}, ${fromAddress.lon})');
      print('To: ${toAddress.desc} (${toAddress.lat}, ${toAddress.lon})');

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.estimateFee}'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'from_lat': fromAddress.lat,
              'from_lon': fromAddress.lon,
              'from_address': fromAddress.desc,
              'to_lat': toAddress.lat,
              'to_lon': toAddress.lon,
              'to_address': toAddress.desc,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Timeout khi ước tính phí'),
          );

      print('💰 Estimate response: ${response.statusCode}');
      print('💰 Estimate body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Không thể ước tính phí giao hàng',
        };
      }
    } catch (e) {
      print('❌ Error estimating fee: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // Tạo đơn hàng mới
  Future<Map<String, dynamic>> createOrder({
    required AddressModel fromAddress,
    required AddressModel toAddress,
    required List<OrderItem> items,
    required ReceiverInfo receiver,
    String? userNote,
    String? discount,
  }) async {
    try {
      print('📦 Creating new order...');

      final orderData = {
        'from_address': fromAddress.desc,
        'from_lat': fromAddress.lat,
        'from_lon': fromAddress.lon,
        'to_address': toAddress.desc,
        'to_lat': toAddress.lat,
        'to_lon': toAddress.lon,
        'items': items.map((item) => item.toJson()).toList(),
        'receiver': receiver.toJson(),
        if (userNote != null && userNote.isNotEmpty) 'user_note': userNote,
        if (discount != null && discount.isNotEmpty) 'discount': discount,
      };

      print('📦 Order data: ${jsonEncode(orderData)}');

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createOrder}'),
            headers: await _getHeaders(),
            body: jsonEncode(orderData),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Timeout khi tạo đơn hàng'),
          );

      print('📦 Create response: ${response.statusCode}');
      print('📦 Create body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final orderData = data['data'] ?? data;

        final order = OrderModel.fromJson(orderData);
        return {
          'success': true,
          'data': order,
          'message': 'Đơn hàng đã được tạo thành công',
        };
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Không thể tạo đơn hàng';

        if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'].toString();
        }

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // Lấy danh sách đơn hàng của user
  Future<Map<String, dynamic>> getUserOrders({
    int page = 1,
    int limit = 20,
    OrderStatus? status,
  }) async {
    try {
      print('📋 Getting user orders...');

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status.toString();
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: await _getHeaders(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Timeout khi lấy danh sách đơn hàng'),
          );

      print('📋 Orders response: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final ordersData = data['data'] ?? data;

        List<OrderModel> orders = [];
        if (ordersData is List) {
          orders = ordersData
              .map((orderJson) => OrderModel.fromJson(orderJson))
              .toList();
        } else if (ordersData['orders'] != null) {
          orders = (ordersData['orders'] as List)
              .map((orderJson) => OrderModel.fromJson(orderJson))
              .toList();
        }

        return {
          'success': true,
          'data': orders,
          'pagination': data['pagination'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Không thể lấy danh sách đơn hàng',
        };
      }
    } catch (e) {
      print('❌ Error getting orders: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // Lấy chi tiết đơn hàng
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      print('📄 Getting order detail: $orderId');

      final response = await http
          .get(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.orderDetail}/$orderId'),
            headers: await _getHeaders(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Timeout khi lấy chi tiết đơn hàng'),
          );

      print('📄 Order detail response: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final orderData = data['data'] ?? data;

        final order = OrderModel.fromJson(orderData);
        return {
          'success': true,
          'data': order,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Không thể lấy chi tiết đơn hàng',
        };
      }
    } catch (e) {
      print('❌ Error getting order detail: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // Hủy đơn hàng
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      print('❌ Cancelling order: $orderId');

      final response = await http
          .delete(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.cancelOrder}/$orderId'),
            headers: await _getHeaders(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Timeout khi hủy đơn hàng'),
          );

      print('❌ Cancel response: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': 'Đơn hàng đã được hủy thành công',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Không thể hủy đơn hàng',
        };
      }
    } catch (e) {
      print('❌ Error cancelling order: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }
}
