import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/models/order_model.dart';
import 'package:customer_app/providers/order_provider.dart';
import 'package:customer_app/screens/order/create_order_screen.dart';
import 'package:customer_app/screens/order/order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true; // Keep state alive

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Listen to tab changes
    _tabController.addListener(_onTabChanged);

    // Load orders when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrdersForCurrentTab();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh orders when returning to this screen
    _loadOrdersForCurrentTab();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadOrdersForCurrentTab();
    }
  }

  void _loadOrdersForCurrentTab() {
    final orderProvider = context.read<OrderProvider>();
    switch (_tabController.index) {
      case 0: // Tất cả
        orderProvider.loadOrders(refresh: true);
        break;
      case 1: // Đang chờ
        orderProvider.loadOrders(refresh: true, status: 'inproccess');
        break;
      case 2: // Đang giao
        orderProvider.loadOrders(refresh: true, status: 'inproccess');
        break;
      case 3: // Hoàn thành
        orderProvider.loadOrders(refresh: true, status: 'completed');
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đang chờ'),
            Tab(text: 'Đang giao'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadOrdersForCurrentTab();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(), // Tất cả
          _buildOrderList(statusCode: 1), // Đang chờ
          _buildOrderList(statusCode: 2), // Đang giao
          _buildOrderList(statusCode: 3), // Hoàn thành
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<OrderModel>(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateOrderScreen(),
            ),
          );

          if (result != null) {
            // Refresh orders list
            _loadOrdersForCurrentTab();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOrderList({int? statusCode}) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Show loading indicator when loading
        if (orderProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải danh sách đơn hàng...'),
              ],
            ),
          );
        }

        if (orderProvider.errorMessage != null &&
            orderProvider.orders.isEmpty) {
          return _buildErrorState(orderProvider.errorMessage!);
        }

        final orders = statusCode != null
            ? orderProvider.getOrdersByStatusCode(statusCode)
            : orderProvider.orders;

        if (orders.isEmpty) {
          return _buildEmptyState(statusCode);
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadOrdersForCurrentTab();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: order.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn hàng #${order.id?.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(order.statusCode),
                ],
              ),

              const SizedBox(height: 12),

              // Addresses
              _buildAddressRow(
                icon: Icons.location_on,
                color: Colors.green,
                label: 'Lấy hàng',
                address: order.fromAddress?.desc ?? 'Không xác định',
              ),

              const SizedBox(height: 8),

              _buildAddressRow(
                icon: Icons.flag,
                color: Colors.red,
                label: 'Giao đến',
                address: order.toAddress?.desc ?? 'Không xác định',
              ),

              const SizedBox(height: 12),

              // Items summary
              if (order.items != null && order.items!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildItemsSummary(order.items!),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Bottom row with fee and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (order.shippingCost != null)
                    Text(
                      '${order.shippingCost!.toStringAsFixed(0)} VND',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // Driver info if available
              if (order.driver != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          order.driver!.name?.substring(0, 1).toUpperCase() ??
                              'T',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tài xế: ${order.driver!.name ?? 'Không xác định'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            if (order.driver!.phoneNumber != null)
                              Text(
                                'SĐT: ${order.driver!.phoneNumber}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (order.driver!.reviewRate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              order.driver!.reviewRate!.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(int? statusCode) {
    if (statusCode == null) return const SizedBox.shrink();

    Color color;
    Color backgroundColor;
    String statusText;

    switch (statusCode) {
      case 1:
        color = Colors.orange[700]!;
        backgroundColor = Colors.orange[100]!;
        statusText = 'Chờ tài xế';
        break;
      case 2:
        color = Colors.blue[700]!;
        backgroundColor = Colors.blue[100]!;
        statusText = 'Đang giao';
        break;
      case 3:
        color = Colors.green[700]!;
        backgroundColor = Colors.green[100]!;
        statusText = 'Hoàn thành';
        break;
      case 4:
      case 5:
      case 6:
        color = Colors.red[700]!;
        backgroundColor = Colors.red[100]!;
        statusText = 'Đã hủy';
        break;
      default:
        color = Colors.grey[700]!;
        backgroundColor = Colors.grey[100]!;
        statusText = 'Không xác định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
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
              Text(
                address,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(int? statusCode) {
    String message;
    IconData icon;

    switch (statusCode) {
      case 1:
        message = 'Không có đơn hàng đang chờ';
        icon = Icons.hourglass_empty;
        break;
      case 2:
        message = 'Không có đơn hàng đang giao';
        icon = Icons.local_shipping;
        break;
      case 3:
        message = 'Chưa có đơn hàng hoàn thành';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'Chưa có đơn hàng nào\nHãy tạo đơn hàng đầu tiên của bạn!';
        icon = Icons.inbox;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          if (statusCode == null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<OrderModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateOrderScreen(),
                  ),
                );

                if (result != null) {
                  _loadOrdersForCurrentTab();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn hàng'),
            ),
          ],
        ],
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
              _loadOrdersForCurrentTab();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  String _buildItemsSummary(List<OrderItem> items) {
    if (items.isEmpty) return 'Không có hàng hóa';

    final summary = items.map((item) {
      return '${item.name} (${item.quantity})';
    }).join(', ');

    return summary;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return '${difference.inHours} giờ trước';
      }
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
