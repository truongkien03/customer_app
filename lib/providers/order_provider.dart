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

  // Ước tính phí giao hàng
  Future<bool> estimateDeliveryFee({
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
        _estimatedFee = data['estimated_fee']?.toDouble();
        _estimatedDistance = data['distance']?.toDouble();
        _estimatedTime = data['estimated_time']?.toInt();

        print('💰 Estimated fee: $_estimatedFee VND');
        print('📏 Distance: $_estimatedDistance km');
        print('⏱️ Time: $_estimatedTime minutes');

        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Lỗi ước tính phí: ${e.toString()}');
      return false;
    } finally {
      _setEstimating(false);
    }
  }

  // Tạo đơn hàng mới
  Future<bool> createOrder({
    required AddressModel fromAddress,
    required AddressModel toAddress,
    required List<OrderItem> items,
    required ReceiverInfo receiver,
    String? userNote,
    String? discount,
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
        _currentOrder = result['data'] as OrderModel;

        // Thêm đơn hàng mới vào đầu danh sách
        _orders.insert(0, _currentOrder!);

        print('✅ Order created successfully: ${_currentOrder!.id}');
        notifyListeners();
        return true;
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
    OrderStatus? status,
  }) async {
    if (refresh) {
      _orders.clear();
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _orderService.getUserOrders(
        page: 1,
        limit: 50,
        status: status,
      );

      if (result['success']) {
        _orders = result['data'] as List<OrderModel>;
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
  Future<bool> loadOrderDetail(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _orderService.getOrderDetail(orderId);

      if (result['success']) {
        _currentOrder = result['data'] as OrderModel;

        // Cập nhật trong danh sách nếu có
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1) {
          _orders[index] = _currentOrder!;
        }

        print('📄 Loaded order detail: ${_currentOrder!.id}');
        notifyListeners();
        return true;
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

  // Hủy đơn hàng
  Future<bool> cancelOrder(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _orderService.cancelOrder(orderId);

      if (result['success']) {
        // Cập nhật status trong danh sách
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1) {
          _orders[index] = OrderModel(
            id: _orders[index].id,
            fromAddress: _orders[index].fromAddress,
            fromLat: _orders[index].fromLat,
            fromLon: _orders[index].fromLon,
            toAddress: _orders[index].toAddress,
            toLat: _orders[index].toLat,
            toLon: _orders[index].toLon,
            items: _orders[index].items,
            receiver: _orders[index].receiver,
            userNote: _orders[index].userNote,
            discount: _orders[index].discount,
            estimatedFee: _orders[index].estimatedFee,
            distance: _orders[index].distance,
            estimatedTime: _orders[index].estimatedTime,
            status: OrderStatus.cancelled, // Cập nhật status
            driverId: _orders[index].driverId,
            driver: _orders[index].driver,
            createdAt: _orders[index].createdAt,
            updatedAt: DateTime.now(),
          );
        }

        // Cập nhật current order nếu đúng order
        if (_currentOrder?.id == orderId) {
          _currentOrder = _orders[index];
        }

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

  // Filter orders by status
  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Get orders count by status
  int getOrdersCountByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).length;
  }
}
