import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/providers/order_provider.dart';

class OrderListTestScreen extends StatefulWidget {
  const OrderListTestScreen({Key? key}) : super(key: key);

  @override
  State<OrderListTestScreen> createState() => _OrderListTestScreenState();
}

class _OrderListTestScreenState extends State<OrderListTestScreen> {
  final TextEditingController _orderIdController = TextEditingController();

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Order List Update'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Auto-Update Order List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhập Order ID để test việc load chi tiết và tự động thêm vào danh sách:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _orderIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Order ID',
                hintText: 'Ví dụ: 1, 2, 3...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: orderProvider.isLoading
                        ? null
                        : () => _testLoadOrderDetail(),
                    icon: orderProvider.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_circle),
                    label: Text(
                      orderProvider.isLoading
                          ? 'Đang load...'
                          : 'Load Order Detail & Add to List',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Trạng thái danh sách đơn hàng:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
    );
  }

  void _testLoadOrderDetail() async {
    final orderId = _orderIdController.text.trim();
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Order ID')),
      );
      return;
    }

    final orderProvider = context.read<OrderProvider>();

    // Load order detail - này sẽ tự động thêm vào danh sách
    final success = await orderProvider.loadOrderDetail(int.parse(orderId));

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã load order $orderId và thêm vào danh sách'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('❌ Lỗi load order $orderId: ${orderProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOrdersList() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.orders.isEmpty) {
          return const Center(
            child: Text(
              'Chưa có đơn hàng nào\nHãy load một order để test!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng: ${orderProvider.orders.length} đơn hàng',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusSummary(orderProvider),
            const SizedBox(height: 16),
            const Text(
              'Danh sách đơn hàng:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: orderProvider.orders.length,
                itemBuilder: (context, index) {
                  final order = orderProvider.orders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('Order #${order.id}'),
                      subtitle: Text(
                        '${_getStatusName(order.statusCode)} • '
                        '${order.fromAddress?.desc ?? 'N/A'} → ${order.toAddress?.desc ?? 'N/A'}',
                      ),
                      trailing: Text(
                        '${order.shippingCost?.toStringAsFixed(0) ?? 'N/A'} VNĐ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusSummary(OrderProvider orderProvider) {
    final statusCounts = <int, int>{};
    for (final order in orderProvider.orders) {
      statusCounts[order.statusCode ?? 0] =
          (statusCounts[order.statusCode ?? 0] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8,
      children: statusCounts.entries.map((entry) {
        return Chip(
          label: Text('${_getStatusName(entry.key)}: ${entry.value}'),
          backgroundColor: _getStatusColor(entry.key),
        );
      }).toList(),
    );
  }

  String _getStatusName(int? statusCode) {
    switch (statusCode) {
      case 1:
        return 'Đang chờ';
      case 2:
        return 'Đã nhận';
      case 3:
        return 'Đang giao';
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
        return Colors.orange[100]!;
      case 2:
        return Colors.blue[100]!;
      case 3:
        return Colors.purple[100]!;
      case 4:
        return Colors.green[100]!;
      case 5:
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}
