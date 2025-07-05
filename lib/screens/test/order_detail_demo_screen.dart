import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/providers/order_provider.dart';
import 'package:customer_app/screens/order/order_detail_screen.dart';

class OrderDetailDemoScreen extends StatefulWidget {
  const OrderDetailDemoScreen({Key? key}) : super(key: key);

  @override
  State<OrderDetailDemoScreen> createState() => _OrderDetailDemoScreenState();
}

class _OrderDetailDemoScreenState extends State<OrderDetailDemoScreen> {
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
        title: const Text('Demo Chi tiết Đơn hàng'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test API GET /orders/{orderId}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập Order ID để test chức năng lấy chi tiết đơn hàng theo API documentation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _orderIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Order ID',
                hintText: 'Nhập ID đơn hàng (ví dụ: 123)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: orderProvider.isLoading
                            ? null
                            : () => _loadOrderDetail(),
                        icon: orderProvider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          orderProvider.isLoading
                              ? 'Đang tải...'
                              : 'Lấy chi tiết đơn hàng',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _orderIdController.text.isEmpty
                            ? null
                            : () => _navigateToOrderDetail(),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Mở OrderDetailScreen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.errorMessage != null) {
          return Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Lỗi',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    orderProvider.errorMessage!,
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ],
              ),
            ),
          );
        }

        if (orderProvider.currentOrder != null) {
          final order = orderProvider.currentOrder!;
          return Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Thành công',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildOrderInfo('ID', order.id?.toString() ?? 'N/A'),
                  _buildOrderInfo('Trạng thái', order.statusName),
                  _buildOrderInfo('Từ', order.fromAddress?.desc ?? 'N/A'),
                  _buildOrderInfo('Đến', order.toAddress?.desc ?? 'N/A'),
                  if (order.shippingCost != null)
                    _buildOrderInfo(
                        'Phí', '${order.shippingCost!.toStringAsFixed(0)} VNĐ'),
                  if (order.distance != null)
                    _buildOrderInfo('Khoảng cách',
                        '${order.distance!.toStringAsFixed(1)} km'),
                  if (order.driver?.name != null)
                    _buildOrderInfo('Tài xế', order.driver!.name!),
                ],
              ),
            ),
          );
        }

        return Container();
      },
    );
  }

  Widget _buildOrderInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _loadOrderDetail() {
    final orderIdText = _orderIdController.text.trim();
    if (orderIdText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Order ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final orderId = int.tryParse(orderIdText);
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID phải là số'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<OrderProvider>().loadOrderDetail(orderId);
  }

  void _navigateToOrderDetail() {
    final orderIdText = _orderIdController.text.trim();
    if (orderIdText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Order ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: orderIdText),
      ),
    );
  }
}
