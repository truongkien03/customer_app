import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/models/order_model.dart';
import 'package:customer_app/providers/order_provider.dart';
import 'package:customer_app/widgets/custom_button.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load order details when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = context.read<OrderProvider>();
      orderProvider.loadOrderDetail(int.parse(widget.orderId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn hàng #${widget.orderId.substring(0, 8)}'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OrderProvider>().loadOrderDetail(
                    int.parse(widget.orderId),
                  );
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading && orderProvider.currentOrder == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProvider.errorMessage != null &&
              orderProvider.currentOrder == null) {
            return _buildErrorState(orderProvider.errorMessage!);
          }

          final order = orderProvider.currentOrder;
          if (order == null) {
            return _buildErrorState('Không tìm thấy thông tin đơn hàng');
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<OrderProvider>().loadOrderDetail(
                    int.parse(widget.orderId),
                  );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(order),
                  const SizedBox(height: 16),
                  _buildAddressSection(order),
                  const SizedBox(height: 16),
                  _buildDeliveryInfoSection(order),
                  if (order.userNote != null && order.userNote!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNoteSection(order),
                  ],
                  if (order.driver != null) ...[
                    const SizedBox(height: 16),
                    _buildDriverSection(order),
                  ],
                  const SizedBox(height: 16),
                  _buildTimelineSection(order),
                  const SizedBox(height: 24),
                  _buildActionButtons(order),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(OrderModel order) {
    Color statusColor;
    Color backgroundColor;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange[700]!;
        backgroundColor = Colors.orange[50]!;
        statusIcon = Icons.schedule;
        break;
      case OrderStatus.inprocess:
        statusColor = Colors.blue[700]!;
        backgroundColor = Colors.blue[50]!;
        statusIcon = Icons.local_shipping;
        break;
      case OrderStatus.completed:
        statusColor = Colors.green[700]!;
        backgroundColor = Colors.green[50]!;
        statusIcon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red[700]!;
        backgroundColor = Colors.red[50]!;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey[700]!;
        backgroundColor = Colors.grey[50]!;
        statusIcon = Icons.help_outline;
    }

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái đơn hàng',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.status?.displayName ?? 'Không xác định',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  Widget _buildAddressSection(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin giao hàng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildAddressRow(
              icon: Icons.location_on,
              color: Colors.green,
              title: 'Điểm lấy hàng',
              address: order.fromAddress ?? 'Không xác định',
              coordinates: order.fromLat != null && order.fromLon != null
                  ? '${order.fromLat}, ${order.fromLon}'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildAddressRow(
              icon: Icons.place,
              color: Colors.red,
              title: 'Điểm giao hàng',
              address: order.toAddress ?? 'Không xác định',
              coordinates: order.toLat != null && order.toLon != null
                  ? '${order.toLat}, ${order.toLon}'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required Color color,
    required String title,
    required String address,
    String? coordinates,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(fontSize: 16),
              ),
              if (coordinates != null) ...[
                const SizedBox(height: 2),
                Text(
                  coordinates,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfoSection(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin phí giao hàng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (order.distance != null)
              _buildInfoRow(
                'Khoảng cách',
                '${order.distance!.toStringAsFixed(1)} km',
              ),
            if (order.estimatedFee != null)
              _buildInfoRow(
                'Phí giao hàng',
                '${order.estimatedFee!.toStringAsFixed(0)} VNĐ',
                isHighlight: true,
              ),
            if (order.estimatedTime != null)
              _buildInfoRow(
                'Thời gian ước tính',
                '${order.estimatedTime} phút',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.green[700] : Colors.black87,
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ghi chú',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              order.userNote!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSection(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin tài xế',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    order.driver!.name?.substring(0, 1).toUpperCase() ?? 'T',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.driver!.name ?? 'Không xác định',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (order.driver!.vehiclePlate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Biển số: ${order.driver!.vehiclePlate}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (order.driver!.rating != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              order.driver!.rating!.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (order.driver!.phoneNumber != null)
                  IconButton(
                    onPressed: () {
                      // Implement call functionality
                      _callDriver(order.driver!.phoneNumber!);
                    },
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

  Widget _buildTimelineSection(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thời gian',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (order.createdAt != null)
              _buildTimelineItem(
                'Đơn hàng được tạo',
                order.createdAt!,
                Icons.add_circle_outline,
                Colors.blue,
              ),
            if (order.updatedAt != null && order.updatedAt != order.createdAt)
              _buildTimelineItem(
                'Cập nhật gần nhất',
                order.updatedAt!,
                Icons.update,
                Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    DateTime time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDateTime(time),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    return Column(
      children: [
        if (order.status == OrderStatus.pending) ...[
          CustomButton(
            text: 'Hủy đơn hàng',
            onPressed: () => _showCancelDialog(order),
          ),
        ],
        if (order.status == OrderStatus.completed) ...[
          CustomButton(
            text: 'Đánh giá đơn hàng',
            onPressed: () => _showRatingDialog(order),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<OrderProvider>().loadOrderDetail(
                    int.parse(widget.orderId),
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(OrderModel order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn có chắc muốn hủy đơn hàng này?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy',
                hintText: 'Nhập lý do hủy đơn hàng...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<OrderProvider>().cancelOrder(
                    int.parse(order.id!),
                    reasonController.text.trim().isEmpty
                        ? 'Người dùng hủy'
                        : reasonController.text.trim(),
                  );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đơn hàng đã được hủy'
                          : 'Không thể hủy đơn hàng',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(OrderModel order) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đánh giá đơn hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Đánh giá chất lượng dịch vụ:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() => rating = index + 1.0);
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Nhận xét',
                  hintText: 'Chia sẻ trải nghiệm của bạn...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Implement rating functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cảm ơn bạn đã đánh giá!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Gửi đánh giá'),
            ),
          ],
        ),
      ),
    );
  }

  void _callDriver(String phoneNumber) {
    // Implement call functionality
    // You can use url_launcher package
    print('Calling driver: $phoneNumber');
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
