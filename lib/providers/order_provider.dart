import 'package:flutter/material.dart';
import 'package:customer_app/models/order_model.dart';
import 'package:customer_app/models/address_model.dart';
import 'package:customer_app/services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  // Loading states
  bool _isLoading = false;
  bool _isEstimating = false;
  bool _isCreating = false;

  // Error state
  String? _errorMessage;

  // Orders data
  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;

  // Delivery fee estimation
  double? _estimatedFee;
  double? _estimatedDistance;
  int? _estimatedTime;

  // Getters
  bool get isLoading => _isLoading;
  bool get isEstimating => _isEstimating;
  bool get isCreating => _isCreating;
  String? get errorMessage => _errorMessage;
  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  double? get estimatedFee => _estimatedFee;
  double? get estimatedDistance => _estimatedDistance;
  int? get estimatedTime => _estimatedTime;

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setEstimating(bool estimating) {
    _isEstimating = estimating;
    notifyListeners();
  }

  void _setCreating(bool creating) {
    _isCreating = creating;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Ước tính phí giao hàng từ API
  Future<Map<String, dynamic>> estimateDeliveryFee({
    required AddressModel fromAddress,
    required AddressModel toAddress,
  }) async {
    _setEstimating(true);
    _clearError();

    try {
      final result = await _orderService.estimateDeliveryFee(
        fromAddress: fromAddress,
        toAddress: toAddress,
      );

      if (result['success']) {
        final data = result['data'];
        // Cập nhật theo API response format mới
        _estimatedFee = data['shipping_fee']?.toDouble();
        _estimatedDistance = data['distance']?.toDouble();

        // Xử lý estimated_time format "15-30 phút"
        if (data['estimated_time'] != null) {
          final timeStr = data['estimated_time'].toString();
          // Extract số đầu tiên từ string "15-30 phút" -> 15
          final match = RegExp(r'(\d+)').firstMatch(timeStr);
          _estimatedTime = match != null ? int.parse(match.group(1)!) : null;
        } else {
          _estimatedTime = null;
        }

        notifyListeners();
        return result;
      } else {
        _setError(result['message']);
        return result;
      }
    } catch (e) {
      final errorResult = {
        'success': false,
        'message': 'Lỗi ước tính phí giao hàng: ${e.toString()}',
      };
      _setError(errorResult['message'] as String?);
      return errorResult;
    } finally {
      _setEstimating(false);
    }
  }

  // Lấy route đường đi từ API
  Future<Map<String, dynamic>> getRoute({
    required AddressModel fromAddress,
    required AddressModel toAddress,
  }) async {
    try {
      final result = await _orderService.getRoute(
        fromAddress: fromAddress,
        toAddress: toAddress,
      );
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi lấy thông tin đường đi: ${e.toString()}',
      };
    }
  }

  // Tạo đơn hàng mới theo API specification mới
  Future<bool> createOrder({
    required AddressModel fromAddress,
    required AddressModel toAddress,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> receiver,
    String? userNote,
    double? discount,
  }) async {
    _setCreating(true);
    _clearError();

    try {
      final result = await _orderService.createOrder(
        fromAddress: fromAddress,
        toAddress: toAddress,
        items: items,
        receiver: receiver,
        userNote: userNote,
        discount: discount,
      );

      if (result['success']) {
        // Parse order data từ response và lưu làm currentOrder
        final orderData = result['data'];

        try {
          _currentOrder = OrderModel.fromJson(orderData);
          print('✅ Order created successfully: ${_currentOrder!.id}');

          // Thêm đơn hàng mới vào danh sách
          _addOrUpdateOrderInList(_currentOrder!);

          notifyListeners();
          return true;
        } catch (e) {
          print('❌ Error parsing created order: $e');
          print('📦 Order data: $orderData');

          // Fallback: reload orders list
          await loadOrders(refresh: true);
          notifyListeners();
          return true;
        }
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Lỗi tạo đơn hàng: ${e.toString()}');
      return false;
    } finally {
      _setCreating(false);
    }
  }

  // Lấy danh sách đơn hàng
  Future<bool> loadOrders({
    bool refresh = false,
    String? status, // 'inproccess', 'completed', hoặc null để lấy tất cả
  }) async {
    if (refresh) {
      _orders.clear();
    }

    _setLoading(true);
    _clearError();

    try {
      Map<String, dynamic> result;

      if (status != null) {
        // Lấy đơn hàng theo status cụ thể
        result = await _orderService.getUserOrders(status: status);
      } else {
        // Lấy tất cả đơn hàng
        result = await _orderService.getAllUserOrders();
      }

      if (result['success']) {
        final ordersData = result['data'];
        if (ordersData is List) {
          _orders = ordersData
              .map((orderJson) {
                try {
                  return OrderModel.fromJson(orderJson);
                } catch (e) {
                  print('❌ Error parsing order: $e');
                  print('📦 Order data: $orderJson');
                  return null;
                }
              })
              .where((order) => order != null)
              .cast<OrderModel>()
              .toList();
        } else {
          _orders = [];
        }

        print('📋 Loaded ${_orders.length} orders');
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Lỗi tải đơn hàng: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Lấy chi tiết đơn hàng
  Future<bool> loadOrderDetail(int orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _orderService.getOrderDetail(orderId.toString());

      if (result['success']) {
        // Parse order data from response
        final orderData = result['data'];
        if (orderData != null) {
          // Create OrderModel from data
          try {
            _currentOrder = OrderModel.fromJson(orderData);

            // Thêm hoặc cập nhật đơn hàng trong danh sách
            _addOrUpdateOrderInList(_currentOrder!);

            print('📄 Loaded order detail: ${_currentOrder!.id}');
            notifyListeners();
            return true;
          } catch (e) {
            print('❌ Error parsing order data: $e');
            _setError('Lỗi xử lý dữ liệu đơn hàng');
            return false;
          }
        } else {
          _setError('Không tìm thấy thông tin đơn hàng');
          return false;
        }
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Lỗi tải chi tiết đơn hàng: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper method để thêm hoặc cập nhật đơn hàng trong danh sách
  void _addOrUpdateOrderInList(OrderModel order) {
    final index = _orders.indexWhere((o) => o.id == order.id);

    if (index != -1) {
      // Cập nhật đơn hàng hiện có
      _orders[index] = order;
      print('✅ Updated existing order in list: ${order.id}');
    } else {
      // Thêm đơn hàng mới vào đầu danh sách
      _orders.insert(0, order);
      print('✅ Added new order to list: ${order.id}');
    }

    // Sắp xếp lại danh sách theo thời gian tạo (mới nhất trước)
    _orders.sort((a, b) {
      final dateA = a.createdAt ?? DateTime.now();
      final dateB = b.createdAt ?? DateTime.now();
      return dateB.compareTo(dateA); // Mới nhất trước
    });
  }

  // Hủy đơn hàng
  Future<bool> cancelOrder(int orderId, String reason) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _orderService.cancelOrder(orderId, reason);

      if (result['success']) {
        // Reload orders to get updated list
        await loadOrders(refresh: true);

        print('❌ Order cancelled: $orderId');
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Lỗi hủy đơn hàng: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear estimation data
  void clearEstimation() {
    _estimatedFee = null;
    _estimatedDistance = null;
    _estimatedTime = null;
    notifyListeners();
  }

  // Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Refresh orders
  Future<void> refreshOrders() async {
    await loadOrders(refresh: true);
  }

  // Filter orders by status code
  List<OrderModel> getOrdersByStatusCode(int statusCode) {
    return _orders.where((order) => order.statusCode == statusCode).toList();
  }

  // Get orders count by status code
  int getOrdersCountByStatusCode(int statusCode) {
    return _orders.where((order) => order.statusCode == statusCode).length;
  }

  // Public method to add or update order in list (useful for notification handling)
  void addOrUpdateOrder(OrderModel order) {
    _addOrUpdateOrderInList(order);
    notifyListeners();
  }
}
