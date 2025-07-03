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

    // Load order detail when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OrderProvider>().loadOrderDetail(widget.orderId);
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
            return _buildErrorState('Không tìm thấy đơn hàng');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOrderHeader(order),
                const SizedBox(height: 24),
                _buildAddressSection(order),
                const SizedBox(height: 24),
                _buildItemsSection(order),
                const SizedBox(height: 24),
                _buildReceiverSection(order),
                const SizedBox(height: 24),
                _buildFeeSection(order),
                if (order.driver != null) ...[
                  const SizedBox(height: 24),
                  _buildDriverSection(order.driver!),
                ],
                if (order.userNote != null && order.userNote!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildNotesSection(order),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(order),
                const SizedBox(
                    height: 100), // Extra space for floating elements
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn hàng #${order.id?.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(order.status),
              ],
            ),
            if (order.distance != null || order.estimatedTime != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (order.distance != null) ...[
                    Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${order.distance!.toStringAsFixed(1)} km',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (order.estimatedTime != null) ...[
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${order.estimatedTime} phút',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
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
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Địa chỉ giao hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // From Address
            _buildAddressRow(
              icon: Icons.location_on,
              color: Colors.green,
              label: 'Lấy hàng',
              address: order.fromAddress ?? 'Không xác định',
            ),

            const SizedBox(height: 16),

            // Route line
            Container(
              margin: const EdgeInsets.only(left: 8),
              height: 20,
              width: 2,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(1),
              ),
            ),

            const SizedBox(height: 16),

            // To Address
            _buildAddressRow(
              icon: Icons.flag,
              color: Colors.red,
              label: 'Giao đến',
              address: order.toAddress ?? 'Không xác định',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required Color color,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(OrderModel order) {
    if (order.items == null || order.items!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Hàng hóa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items!.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = order.items![index];
                return _buildItemRow(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.note!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            'x${item.quantity}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverSection(OrderModel order) {
    if (order.receiver == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'Người nhận',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  order.receiver!.name,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  order.receiver!.phoneNumber,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeSection(OrderModel order) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Chi phí',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (order.distance != null) ...[
              _buildFeeRow(
                'Khoảng cách',
                '${order.distance!.toStringAsFixed(1)} km',
              ),
            ],
            if (order.estimatedTime != null) ...[
              _buildFeeRow(
                'Thời gian dự kiến',
                '${order.estimatedTime} phút',
              ),
            ],
            if (order.discount != null && order.discount!.isNotEmpty) ...[
              _buildFeeRow(
                'Mã giảm giá',
                order.discount!,
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng phí giao hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${order.estimatedFee?.toStringAsFixed(0) ?? '0'} VND',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSection(DriverInfo driver) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_pin, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Tài xế',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    driver.name?.substring(0, 1).toUpperCase() ?? 'T',
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
                        driver.name ?? 'Không xác định',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (driver.phoneNumber != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              driver.phoneNumber!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (driver.vehiclePlate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.motorcycle,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              driver.vehiclePlate!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (driver.rating != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          driver.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.userNote!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    if (order.status != OrderStatus.pending) {
      return const SizedBox.shrink();
    }

    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return CustomButton(
          text: orderProvider.isLoading ? 'Đang hủy...' : 'Hủy đơn hàng',
          onPressed: () {
            if (!orderProvider.isLoading) {
              _showCancelConfirmation(order);
            }
          },
          backgroundColor: Colors.red,
          isLoading: orderProvider.isLoading,
        );
      },
    );
  }

  Widget _buildStatusChip(OrderStatus? status) {
    if (status == null) return const SizedBox.shrink();

    Color color;
    Color backgroundColor;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange[700]!;
        backgroundColor = Colors.orange[100]!;
        break;
      case OrderStatus.inprocess:
        color = Colors.blue[700]!;
        backgroundColor = Colors.blue[100]!;
        break;
      case OrderStatus.completed:
        color = Colors.green[700]!;
        backgroundColor = Colors.green[100]!;
        break;
      case OrderStatus.cancelled:
        color = Colors.red[700]!;
        backgroundColor = Colors.red[100]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
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
              context.read<OrderProvider>().loadOrderDetail(widget.orderId);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đơn hàng này? '
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success =
                  await context.read<OrderProvider>().cancelOrder(order.id!);

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đơn hàng đã được hủy'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                final error = context.read<OrderProvider>().errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Không thể hủy đơn hàng'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy đơn hàng'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
