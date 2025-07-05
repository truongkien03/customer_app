import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:customer_app/models/order_model.dart';
import 'package:customer_app/models/notification_model.dart';
import 'package:customer_app/providers/order_provider.dart';
import 'package:customer_app/providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _pollingTimer;
  late OrderModel _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _setupNotificationListener();
    _startOrderStatusPolling();
    _showOrderCreatedDialog();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    // Listen to FCM notifications for this specific order
    final notificationProvider = context.read<NotificationProvider>();

    // Listen to notification updates
    notificationProvider.addListener(_onNotificationUpdate);
  }

  void _onNotificationUpdate() {
    final notificationProvider = context.read<NotificationProvider>();
    final latestNotification = notificationProvider.notifications.isNotEmpty
        ? notificationProvider.notifications.first
        : null;

    if (latestNotification != null &&
        latestNotification.data.orderId == _currentOrder.id) {
      _handleNotificationForOrder(latestNotification.notificationType);
    }
  }

  void _handleNotificationForOrder(NotificationType? notificationType) {
    switch (notificationType) {
      case NotificationType.driverAccepted:
        _handleDriverAccepted();
        break;
      case NotificationType.noAvailableDriver:
        _handleNoDriverFound();
        break;
      case NotificationType.orderCompleted:
        _handleOrderCompleted();
        break;
      case NotificationType.driverDeclined:
        // Handle driver declined - similar to no driver found
        _handleNoDriverFound();
        break;
      default:
        // Handle unknown notification types
        break;
    }
  }

  void _startOrderStatusPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshOrderStatus();
    });
  }

  Future<void> _refreshOrderStatus() async {
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.loadOrderDetail(
      int.parse(_currentOrder.id ?? '0'),
    );

    if (success && orderProvider.currentOrder != null) {
      setState(() {
        _currentOrder = orderProvider.currentOrder!;
      });
    }
  }

  void _showOrderCreatedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text("Đặt hàng thành công!"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mã đơn hàng: #${_currentOrder.id}"),
              const SizedBox(height: 8),
              Text(
                "Phí vận chuyển: ${NumberFormat('#,###').format(_currentOrder.shippingCost ?? 0)} đ",
              ),
              const SizedBox(height: 8),
              Text("Trạng thái: ${_getStatusName(_currentOrder.statusCode)}"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "💡 Chúng tôi sẽ thông báo khi tìm được tài xế phù hợp",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Theo dõi đơn hàng"),
            ),
          ],
        ),
      );
    });
  }

  void _handleDriverAccepted() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🎉 Đã tìm thấy tài xế!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: _currentOrder.driver?.avatar != null
                  ? NetworkImage(_currentOrder.driver!.avatar!)
                  : null,
              child: _currentOrder.driver?.avatar == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              _currentOrder.driver?.name ?? 'Tài xế',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_currentOrder.driver?.reviewRate != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  Text(" ${_currentOrder.driver!.reviewRate}/5"),
                ],
              ),
            const SizedBox(height: 8),
            const Text("Tài xế sẽ đến lấy hàng trong 10-15 phút"),
          ],
        ),
        actions: [
          if (_currentOrder.driver?.phoneNumber != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _callDriver(_currentOrder.driver!.phoneNumber!);
              },
              child: const Text("Gọi tài xế"),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Theo dõi"),
          ),
        ],
      ),
    );
  }

  void _handleNoDriverFound() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Không tìm thấy tài xế"),
        content: const Text(
          "Hiện tại không có tài xế khả dụng trong khu vực của bạn. "
          "Bạn có thể thử lại sau hoặc hủy đơn hàng.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCancelOrderDialog();
            },
            child: const Text("Hủy đơn"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _refreshOrderStatus();
            },
            child: const Text("Thử lại"),
          ),
        ],
      ),
    );
  }

  void _handleDriverOnTheWay() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚚 Tài xế đang trên đường đến điểm lấy hàng"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handlePackagePickedUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📦 Tài xế đã lấy hàng và đang giao đến bạn"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleOrderCompleted() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🎉 Giao hàng thành công!"),
        content: Text("Đơn hàng #${_currentOrder.id} đã được giao thành công"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Refresh orders before going back
              final orderProvider = context.read<OrderProvider>();
              orderProvider.refreshOrders();
              Navigator.of(context).pop(); // Back to main screen
            },
            child: const Text("Về trang chủ"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showRatingDialog();
            },
            child: const Text("Đánh giá tài xế"),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hủy đơn hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Vui lòng cho biết lý do hủy đơn:"),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Nhập lý do hủy đơn...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Quay lại"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.of(context).pop();
                await _cancelOrder(reason);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xác nhận hủy"),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Đánh giá tài xế"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "Bạn hài lòng với dịch vụ của ${_currentOrder.driver?.name ?? 'tài xế'}?"),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setDialogState(() {
                        rating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: "Nhận xét về tài xế (tùy chọn)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Bỏ qua"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitRating(rating, commentController.text);
              },
              child: const Text("Gửi đánh giá"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder(String reason) async {
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.cancelOrder(
      int.parse(_currentOrder.id ?? '0'),
      reason,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đơn hàng đã được hủy"),
          backgroundColor: Colors.orange,
        ),
      );
      // Refresh orders before going back
      orderProvider.refreshOrders();
      Navigator.of(context).pop(); // Back to main screen
    }
  }

  Future<void> _submitRating(int rating, String comment) async {
    // TODO: Implement rating submission API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cảm ơn bạn đã đánh giá!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _callDriver(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _getStatusName(int? statusCode) {
    switch (statusCode) {
      case 1:
        return 'Đang tìm tài xế';
      case 2:
        return 'Đã có tài xế nhận đơn';
      case 3:
        return 'Đang giao hàng';
      case 4:
        return 'Hoàn thành';
      case 5:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(int? statusCode) {
    switch (statusCode) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.green;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Refresh orders when going back to ensure the new order appears in list
        final orderProvider = context.read<OrderProvider>();
        orderProvider.refreshOrders();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Đơn hàng #${_currentOrder.id}'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshOrderStatus,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildDriverSection(),
              const SizedBox(height: 16),
              _buildAddressSection(),
              const SizedBox(height: 16),
              _buildItemsSection(),
              const SizedBox(height: 16),
              _buildCostSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(_currentOrder.statusCode),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusName(_currentOrder.statusCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo lúc: ${_formatDateTime(_currentOrder.createdAt)}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (_currentOrder.statusCode == 1)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đang tìm tài xế trong khu vực của bạn...',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSection() {
    if (_currentOrder.driver == null) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin tài xế',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: _currentOrder.driver?.avatar != null
                      ? NetworkImage(_currentOrder.driver!.avatar!)
                      : null,
                  child: _currentOrder.driver?.avatar == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentOrder.driver?.name ?? 'Tài xế',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentOrder.driver?.phoneNumber != null)
                        Text(_currentOrder.driver!.phoneNumber!),
                      if (_currentOrder.driver?.reviewRate != null)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.orange, size: 16),
                            Text(" ${_currentOrder.driver!.reviewRate}/5"),
                          ],
                        ),
                    ],
                  ),
                ),
                if (_currentOrder.driver?.phoneNumber != null)
                  IconButton(
                    onPressed: () =>
                        _callDriver(_currentOrder.driver!.phoneNumber!),
                    icon: const Icon(Icons.phone),
                    color: Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin giao hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAddressItem(
              'Từ',
              _currentOrder.fromAddress?.desc ?? 'N/A',
              Icons.my_location,
            ),
            const SizedBox(height: 8),
            _buildAddressItem(
              'Đến',
              _currentOrder.toAddress?.desc ?? 'N/A',
              Icons.location_on,
            ),
            if (_currentOrder.distance != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                      'Khoảng cách: ${_currentOrder.distance!.toStringAsFixed(1)} km'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressItem(String label, String address, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(address),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_currentOrder.items != null)
              ...(_currentOrder.items!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.name ?? 'N/A')),
                        Text('SL: ${item.quantity ?? 0}'),
                      ],
                    ),
                  )))
            else
              const Text('Không có thông tin sản phẩm'),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi phí',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Phí vận chuyển:'),
                Text(
                  '${NumberFormat('#,###').format(_currentOrder.shippingCost ?? 0)} đ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_currentOrder.discount != null &&
                _currentOrder.discount! > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giảm giá:'),
                  Text(
                    '-${NumberFormat('#,###').format(_currentOrder.discount)} đ',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format((_currentOrder.shippingCost ?? 0) - (_currentOrder.discount ?? 0))} đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
