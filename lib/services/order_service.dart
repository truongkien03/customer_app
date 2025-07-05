import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:customer_app/constants/api_constants.dart';
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

  // Xử lý response từ API
  Map<String, dynamic> _processResponse(http.Response response) {
    try {
      print('📦 Processing response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      // Xử lý response trống
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'data': {}};
        } else {
          return {
            'success': false,
            'message': 'Response trống với mã: ${response.statusCode}'
          };
        }
      }

      // Parse JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ JSON parse error: $e');
        return {
          'success': false,
          'message': 'Lỗi xử lý dữ liệu từ server: ${e.toString()}'
        };
      }

      // Xử lý response thành công
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData.containsKey('data')
              ? responseData['data']
              : responseData,
          'message': responseData['message'] ?? 'Thành công',
        };
      }

      // Xử lý response lỗi
      String errorMessage = 'Có lỗi xảy ra';

      // Kiểm tra format lỗi mới với errorCode (theo API documentation)
      if (responseData.containsKey('error') && responseData['error'] == true) {
        if (responseData.containsKey('errorCode') &&
            responseData['errorCode'] is Map) {
          // Xử lý validation errors
          final errorCodeMap =
              responseData['errorCode'] as Map<String, dynamic>;
          List<String> errors = [];
          errorCodeMap.forEach((field, messages) {
            if (messages is List) {
              errors.addAll(messages.map((m) => m.toString()));
            } else {
              errors.add(messages.toString());
            }
          });
          if (errors.isNotEmpty) {
            errorMessage = errors.join('\n');
          }
        } else if (responseData.containsKey('message')) {
          // Fallback: sử dụng message nếu có
          if (responseData['message'] is List) {
            errorMessage = (responseData['message'] as List).join('\n');
          } else {
            errorMessage = responseData['message'].toString();
          }
        }
      } else if (responseData.containsKey('message')) {
        // Xử lý format message cũ
        if (responseData['message'] is Map) {
          final messageMap = responseData['message'] as Map<String, dynamic>;
          List<String> errors = [];
          messageMap.forEach((field, messages) {
            if (messages is List) {
              errors.addAll(messages.map((m) => m.toString()));
            } else {
              errors.add(messages.toString());
            }
          });
          errorMessage = errors.join('\n');
        } else {
          errorMessage = responseData['message'].toString();
        }
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('❌ Error processing response: $e');
      return {
        'success': false,
        'message': 'Lỗi xử lý response: ${e.toString()}'
      };
    }
  }

  // Ước tính phí giao hàng theo API mới
  Future<Map<String, dynamic>> estimateDeliveryFee({
    required AddressModel fromAddress,
    required AddressModel toAddress,
  }) async {
    try {
      print('🚚 Estimating delivery fee...');

      // Xây dựng request body theo API spec
      final requestBody = {
        'from_address': fromAddress.toJson(),
        'to_address': toAddress.toJson(),
      };

      print('🚚 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.shippingFee}'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      );

      print('🚚 Shipping fee response: ${response.statusCode}');
      print('🚚 Shipping fee body: ${response.body}');

      final result = _processResponse(response);

      if (result['success']) {
        final data = result['data'];
        // Trả về data nguyên bản từ API (shipping_cost, distance, estimated_time)
        return {
          'success': true,
          'data': data,
          'message': 'Ước tính phí giao hàng thành công',
        };
      } else {
        return result;
      }
    } catch (e) {
      print('❌ Error estimating delivery fee: $e');
      return {
        'success': false,
        'message': 'Lỗi ước tính phí giao hàng: ${e.toString()}',
      };
    }
  }

  // Lấy route đường đi theo API spec
  Future<Map<String, dynamic>> getRoute({
    required AddressModel fromAddress,
    required AddressModel toAddress,
  }) async {
    try {
      print('🗺️ Getting route...');

      // Xây dựng query parameters theo API spec
      final queryParams = {
        'from_lat': fromAddress.lat.toString(),
        'from_lon': fromAddress.lon.toString(),
        'to_lat': toAddress.lat.toString(),
        'to_lon': toAddress.lon.toString(),
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.route}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      print('🗺️ Route response: ${response.statusCode}');
      print('🗺️ Route body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      print('❌ Error getting route: $e');
      return {
        'success': false,
        'message': 'Lỗi lấy thông tin đường đi: ${e.toString()}',
      };
    }
  }

  // Tạo đơn hàng mới theo API specification
  Future<Map<String, dynamic>> createOrder({
    required AddressModel fromAddress,
    required AddressModel toAddress,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> receiver,
    String? userNote,
    double? discount,
  }) async {
    try {
      print('📦 Creating new order...');
      print('📦 From address: ${fromAddress.toJson()}');
      print('📦 To address: ${toAddress.toJson()}');
      print('📦 Items: $items');
      print('📦 Receiver: $receiver');
      print('📦 User note: $userNote');
      print('📦 Discount: $discount');

      // Validation đầu vào
      if (fromAddress.desc.isEmpty) {
        return {
          'success': false,
          'message': 'Địa chỉ lấy hàng không được để trống',
        };
      }

      if (toAddress.desc.isEmpty) {
        return {
          'success': false,
          'message': 'Địa chỉ giao hàng không được để trống',
        };
      }

      if (items.isEmpty) {
        return {
          'success': false,
          'message': 'Vui lòng thêm ít nhất một sản phẩm',
        };
      }

      if (receiver.isEmpty ||
          receiver['name'] == null ||
          receiver['phone'] == null) {
        return {
          'success': false,
          'message': 'Thông tin người nhận không hợp lệ',
        };
      }

      // Chuẩn bị dữ liệu theo format API mới
      final orderData = {
        'from_address': {
          'lat': fromAddress.lat,
          'lon': fromAddress.lon,
          'desc': fromAddress.desc,
        },
        'to_address': {
          'lat': toAddress.lat,
          'lon': toAddress.lon,
          'desc': toAddress.desc,
        },
        'items': items,
        'receiver': receiver,
      };

      // Thêm các field tùy chọn
      if (userNote != null && userNote.trim().isNotEmpty) {
        orderData['user_note'] = userNote.trim();
      }

      if (discount != null && discount > 0) {
        orderData['discount'] = discount;
      }

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

      return _processResponse(response);
    } catch (e) {
      print('❌ Error creating order: $e');
      return {
        'success': false,
        'message': 'Lỗi tạo đơn hàng: ${e.toString()}',
      };
    }
  }

  // Lấy danh sách đơn hàng theo status
  Future<Map<String, dynamic>> getUserOrders({
    String? status, // 'inproccess' hoặc 'completed'
  }) async {
    try {
      print('📋 Getting user orders with status: ${status ?? "all"}');

      String endpoint;
      if (status == 'inproccess') {
        endpoint = ApiConstants.ordersInprocess;
      } else if (status == 'completed') {
        endpoint = ApiConstants.ordersCompleted;
      } else {
        // Mặc định lấy đơn hàng đang xử lý
        endpoint = ApiConstants.ordersInprocess;
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

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

      return _processResponse(response);
    } catch (e) {
      print('❌ Error getting orders: $e');
      return {
        'success': false,
        'message': 'Lỗi lấy danh sách đơn hàng: ${e.toString()}',
      };
    }
  }

  // Lấy tất cả đơn hàng (inproccess + completed)
  Future<Map<String, dynamic>> getAllUserOrders() async {
    try {
      print('📋 Getting all user orders...');

      // Gọi parallel để lấy cả 2 loại đơn hàng
      final results = await Future.wait([
        getUserOrders(status: 'inproccess'),
        getUserOrders(status: 'completed'),
      ]);

      final inprocessResult = results[0];
      final completedResult = results[1];

      List<dynamic> allOrders = [];

      if (inprocessResult['success'] && inprocessResult['data'] != null) {
        final inprocessOrders = inprocessResult['data'] as List<dynamic>;
        allOrders.addAll(inprocessOrders);
      }

      if (completedResult['success'] && completedResult['data'] != null) {
        final completedOrders = completedResult['data'] as List<dynamic>;
        allOrders.addAll(completedOrders);
      }

      return {
        'success': true,
        'data': allOrders,
        'message': 'Lấy danh sách đơn hàng thành công',
      };
    } catch (e) {
      print('❌ Error getting all orders: $e');
      return {
        'success': false,
        'message': 'Lỗi lấy danh sách đơn hàng: ${e.toString()}',
      };
    }
  }

  // Lấy chi tiết đơn hàng
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      print('📋 Getting order details for ID: $orderId');

      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}/$orderId'),
            headers: await _getHeaders(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Timeout khi lấy chi tiết đơn hàng'),
          );

      print('📋 Order details response: ${response.statusCode}');

      return _processResponse(response);
    } catch (e) {
      print('❌ Error getting order details: $e');
      return {
        'success': false,
        'message': 'Lỗi lấy chi tiết đơn hàng: ${e.toString()}',
      };
    }
  }

  // Hủy đơn hàng
  Future<Map<String, dynamic>> cancelOrder(int orderId, String reason) async {
    try {
      print('❌ Cancelling order ID: $orderId');

      final response = await http
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.orders}/$orderId/cancel'),
            headers: await _getHeaders(),
            body: jsonEncode({'reason': reason}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Timeout khi hủy đơn hàng'),
          );

      print('❌ Cancel response: ${response.statusCode}');

      return _processResponse(response);
    } catch (e) {
      print('❌ Error cancelling order: $e');
      return {
        'success': false,
        'message': 'Lỗi hủy đơn hàng: ${e.toString()}',
      };
    }
  }

  // Đánh giá đơn hàng
  Future<Map<String, dynamic>> rateOrder(
    int orderId,
    double rating,
    String comment,
  ) async {
    try {
      print('⭐ Rating order ID: $orderId');

      final response = await http
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.orders}/$orderId/rate'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'rating': rating,
              'comment': comment,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Timeout khi đánh giá đơn hàng'),
          );

      print('⭐ Rating response: ${response.statusCode}');

      return _processResponse(response);
    } catch (e) {
      print('❌ Error rating order: $e');
      return {
        'success': false,
        'message': 'Lỗi đánh giá đơn hàng: ${e.toString()}',
      };
    }
  }
}
