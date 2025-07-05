import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/models/address_model.dart';
import 'package:customer_app/providers/order_provider.dart';
import 'package:customer_app/widgets/custom_button.dart';
import 'package:customer_app/widgets/custom_text_field.dart';
import 'package:customer_app/screens/map/location_picker_screen.dart';
import 'package:customer_app/screens/order/order_tracking_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Address fields
  AddressModel? _fromAddress;
  AddressModel? _toAddress;

  // Items and receiver
  final List<Map<String, dynamic>> _items = [];

  // Controllers
  final _noteController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _receiverNoteController = TextEditingController();
  final _discountController = TextEditingController();

  // Item form controllers
  final _itemNameController = TextEditingController();
  final _itemQuantityController = TextEditingController(text: '1');
  final _itemPriceController = TextEditingController();
  final _itemNoteController = TextEditingController();

  // Delivery fee and distance (from API)
  double? _estimatedFee;
  double? _estimatedDistance;
  int? _estimatedTime;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverNoteController.dispose();
    _discountController.dispose();
    _itemNameController.dispose();
    _itemQuantityController.dispose();
    _itemPriceController.dispose();
    _itemNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đơn hàng'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAddressSection(),
                    const SizedBox(height: 24),
                    _buildItemsSection(),
                    const SizedBox(height: 24),
                    _buildReceiverSection(),
                    const SizedBox(height: 24),
                    _buildEstimateSection(),
                    const SizedBox(height: 24),
                    _buildNoteSection(),
                  ],
                ),
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Địa chỉ giao hàng',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // From address
        _buildAddressCard(
          title: 'Điểm lấy hàng',
          address: _fromAddress,
          icon: Icons.location_on,
          color: Colors.green,
          onTap: () => _selectAddress(isFromAddress: true),
        ),

        const SizedBox(height: 16),

        // To address
        _buildAddressCard(
          title: 'Điểm giao hàng',
          address: _toAddress,
          icon: Icons.place,
          color: Colors.red,
          onTap: () => _selectAddress(isFromAddress: false),
        ),
      ],
    );
  }

  Widget _buildAddressCard({
    required String title,
    required AddressModel? address,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address?.desc ?? 'Chọn địa chỉ',
                      style: TextStyle(
                        color: address != null ? Colors.black87 : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateSection() {
    if (_fromAddress == null || _toAddress == null) {
      return const SizedBox.shrink();
    }

    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin giao hàng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (orderProvider.isEstimating)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Đang tính toán...'),
                        ],
                      )
                    else if (_fromAddress == null || _toAddress == null)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _fromAddress == null && _toAddress == null
                                  ? 'Vui lòng chọn điểm đi và điểm đến'
                                  : _fromAddress == null
                                      ? 'Vui lòng chọn điểm đi'
                                      : 'Vui lòng chọn điểm đến',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    else if (_estimatedFee != null &&
                        _estimatedDistance != null)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Khoảng cách:'),
                              Text(
                                  '${_estimatedDistance!.toStringAsFixed(1)} km'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Phí giao hàng:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_estimatedFee!.toStringAsFixed(0)} VNĐ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (_estimatedTime != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Thời gian dự kiến:'),
                                Text('${_estimatedTime!} phút'),
                              ],
                            ),
                          ],
                        ],
                      )
                    else
                      CustomButton(
                        text: 'Ước tính phí giao hàng',
                        onPressed: _estimateDeliveryFee,
                      ),
                    if (orderProvider.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        orderProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi chú & Khuyến mãi',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _noteController,
          labelText: 'Ghi chú đặc biệt',
          hintText: 'Ví dụ: Gọi điện trước khi đến, cẩn thận...',
          maxLines: 3,
          maxLength: 500,
          prefixIcon: const Icon(Icons.note_outlined),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _discountController,
          labelText: 'Giảm giá (VNĐ)',
          hintText: 'Nhập số tiền giảm giá (nếu có)',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.discount_outlined),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          text: _isSubmitting ? 'Đang tạo đơn...' : 'Tạo đơn hàng',
          onPressed: _canCreateOrder()
              ? () {
                  _createOrder();
                }
              : null,
          isLoading: _isSubmitting,
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sản phẩm cần giao',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Thêm sản phẩm',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Chưa có sản phẩm nào',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm sản phẩm'),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildItemCard(_items[index], index),
          ),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    return Card(
      child: ListTile(
        title: Text(item['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số lượng: ${item['quantity']}'),
            if (item['price'] != null) Text('Giá: ${item['price']} VNĐ'),
            if (item['note'] != null && item['note'].toString().isNotEmpty)
              Text('Ghi chú: ${item['note']}'),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _removeItem(index),
          icon: const Icon(Icons.delete_outline, color: Colors.red),
        ),
        onTap: () => _editItem(index),
      ),
    );
  }

  Widget _buildReceiverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin người nhận',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _receiverNameController,
          labelText: 'Tên người nhận *',
          hintText: 'Nhập tên người nhận',
          prefixIcon: const Icon(Icons.person_outline),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên người nhận';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _receiverPhoneController,
          labelText: 'Số điện thoại người nhận *',
          hintText: 'Nhập số điện thoại',
          prefixIcon: const Icon(Icons.phone_outlined),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập số điện thoại người nhận';
            }
            if (!RegExp(r'^\+?[0-9]{10,12}$').hasMatch(value.trim())) {
              return 'Số điện thoại không hợp lệ';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _receiverNoteController,
          labelText: 'Ghi chú cho người nhận',
          hintText: 'Ghi chú giao hàng (tùy chọn)',
          prefixIcon: const Icon(Icons.note_outlined),
          maxLines: 2,
        ),
      ],
    );
  }

  Future<void> _selectAddress({required bool isFromAddress}) async {
    final selectedAddress = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialAddress: isFromAddress ? _fromAddress : _toAddress,
        ),
      ),
    );

    if (selectedAddress != null) {
      setState(() {
        if (isFromAddress) {
          _fromAddress = selectedAddress;
        } else {
          _toAddress = selectedAddress;
        }

        // Reset estimate when addresses change
        _estimatedFee = null;
        _estimatedDistance = null;
        _estimatedTime = null;
      });

      // Auto-estimate delivery fee when both addresses are selected
      if (_fromAddress != null && _toAddress != null) {
        _estimateDeliveryFee();
      }
    }
  }

  Future<void> _estimateDeliveryFee() async {
    if (_fromAddress == null || _toAddress == null) return;

    final orderProvider = context.read<OrderProvider>();

    final result = await orderProvider.estimateDeliveryFee(
      fromAddress: _fromAddress!,
      toAddress: _toAddress!,
    );

    if (result['success']) {
      setState(() {
        _estimatedFee = orderProvider.estimatedFee;
        _estimatedDistance = orderProvider.estimatedDistance;
        _estimatedTime = orderProvider.estimatedTime;
      });

      // Kiểm tra business rule: khoảng cách <= 50km
      if (_estimatedDistance != null && _estimatedDistance! > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khoảng cách giao hàng không được vượt quá 50km'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _estimatedDistance = null;
          _estimatedFee = null;
          _estimatedTime = null;
        });
        return;
      }
    }
  }

  bool _canCreateOrder() {
    final hasAddresses = _fromAddress != null && _toAddress != null;
    final hasItems = _items.isNotEmpty;
    final hasReceiver = _receiverNameController.text.trim().isNotEmpty &&
        _receiverPhoneController.text.trim().isNotEmpty;
    final notSubmitting = !_isSubmitting;

    print('🔍 Can create order check:');
    print('🔍 Has addresses: $hasAddresses');
    print('🔍 Has items: $hasItems');
    print('🔍 Has receiver: $hasReceiver');
    print('🔍 Not submitting: $notSubmitting');

    return hasAddresses && hasItems && hasReceiver && notSubmitting;
  }

  Future<void> _createOrder() async {
    if (!_canCreateOrder()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Chuẩn bị dữ liệu receiver
      final receiver = {
        'name': _receiverNameController.text.trim(),
        'phone': _receiverPhoneController.text.trim(),
      };

      if (_receiverNoteController.text.trim().isNotEmpty) {
        receiver['note'] = _receiverNoteController.text.trim();
      }

      // Chuẩn bị dữ liệu gửi API theo format chuẩn
      final orderData = {
        'from_address': _fromAddress!.toJson(),
        'to_address': _toAddress!.toJson(),
        'items': _items,
        'receiver': receiver,
      };

      // Thêm user_note nếu có
      if (_noteController.text.trim().isNotEmpty) {
        orderData['user_note'] = _noteController.text.trim();
      }

      // Thêm discount nếu có
      final discountText = _discountController.text.trim();
      if (discountText.isNotEmpty) {
        final discount = double.tryParse(discountText);
        if (discount != null && discount >= 0) {
          orderData['discount'] = discount;
        }
      }

      print('🔥 Creating order with data: $orderData');

      final orderProvider = context.read<OrderProvider>();
      final success = await orderProvider.createOrder(
        fromAddress: _fromAddress!,
        toAddress: _toAddress!,
        items: _items,
        receiver: receiver,
        userNote: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        discount:
            discountText.isNotEmpty ? double.tryParse(discountText) : null,
      );

      if (!mounted) return;

      if (success) {
        // Lấy order vừa tạo từ provider
        final createdOrder = orderProvider.currentOrder;

        if (createdOrder != null && mounted) {
          // Chuyển đến màn hình tracking
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(order: createdOrder),
            ),
          );
        } else {
          // Fallback: refresh orders và quay về main screen
          orderProvider.refreshOrders();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tạo đơn hàng thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        }
      } else {
        // Hiển thị lỗi từ provider
        final errorMessage =
            orderProvider.errorMessage ?? 'Tạo đơn hàng thất bại';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo đơn hàng: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showAddItemDialog() {
    // Reset controllers
    _itemNameController.clear();
    _itemQuantityController.text = '1';
    _itemPriceController.clear();
    _itemNoteController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm sản phẩm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên sản phẩm *',
                  hintText: 'Nhập tên sản phẩm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _itemPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Giá (VNĐ)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _itemNoteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'Ghi chú cho sản phẩm (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              _addItem();
              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    if (_itemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên sản phẩm'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_itemQuantityController.text.trim()) ?? 1;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số lượng phải lớn hơn 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final item = {
      'name': _itemNameController.text.trim(),
      'quantity': quantity,
    };

    final price = double.tryParse(_itemPriceController.text.trim());
    if (price != null && price >= 0) {
      item['price'] = price;
    }

    final note = _itemNoteController.text.trim();
    if (note.isNotEmpty) {
      item['note'] = note;
    }

    setState(() {
      _items.add(item);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _editItem(int index) {
    final item = _items[index];

    _itemNameController.text = item['name'] ?? '';
    _itemQuantityController.text = item['quantity']?.toString() ?? '1';
    _itemPriceController.text = item['price']?.toString() ?? '';
    _itemNoteController.text = item['note'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa sản phẩm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên sản phẩm *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _itemPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Giá (VNĐ)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _itemNoteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateItem(index);
              Navigator.pop(context);
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _updateItem(int index) {
    if (_itemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên sản phẩm'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_itemQuantityController.text.trim()) ?? 1;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số lượng phải lớn hơn 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final item = {
      'name': _itemNameController.text.trim(),
      'quantity': quantity,
    };

    final price = double.tryParse(_itemPriceController.text.trim());
    if (price != null && price >= 0) {
      item['price'] = price;
    }

    final note = _itemNoteController.text.trim();
    if (note.isNotEmpty) {
      item['note'] = note;
    }

    setState(() {
      _items[index] = item;
    });
  }
}
