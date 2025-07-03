import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/models/address_model.dart';
import 'package:customer_app/models/order_model.dart';
import 'package:customer_app/providers/order_provider.dart';
import 'package:customer_app/widgets/custom_button.dart';
import 'package:customer_app/widgets/custom_text_field.dart';
import 'package:customer_app/screens/map/location_picker_screen.dart';
import 'package:customer_app/utils/validators.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Address controllers
  AddressModel? _fromAddress;
  AddressModel? _toAddress;

  // Item controllers
  final List<OrderItemForm> _items = [OrderItemForm()];

  // Receiver controllers
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();

  // Note controllers
  final _userNoteController = TextEditingController();
  final _discountController = TextEditingController();

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _userNoteController.dispose();
    _discountController.dispose();
    for (var item in _items) {
      item.dispose();
    }
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
                    _buildNotesSection(),
                    const SizedBox(height: 24),
                    _buildEstimationSection(),
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

        // From Address
        _buildAddressCard(
          title: 'Địa chỉ lấy hàng',
          address: _fromAddress,
          icon: Icons.location_on,
          color: Colors.green,
          onTap: () => _selectAddress(isFromAddress: true),
        ),

        const SizedBox(height: 16),

        // To Address
        _buildAddressCard(
          title: 'Địa chỉ giao hàng',
          address: _toAddress,
          icon: Icons.flag,
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
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
                    const SizedBox(height: 4),
                    Text(
                      address?.desc ?? 'Chọn địa chỉ',
                      style: TextStyle(
                        color:
                            address != null ? Colors.black87 : Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thông tin hàng hóa',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildItemCard(index);
          },
        ),
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: item.nameController,
                    labelText: 'Tên hàng hóa',
                    hintText: 'Ví dụ: Thức ăn, Quần áo...',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên hàng hóa';
                      }
                      return null;
                    },
                  ),
                ),
                if (_items.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _removeItem(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: item.quantityController,
                    labelText: 'Số lượng',
                    hintText: '1',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số lượng';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Số lượng phải lớn hơn 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: item.noteController,
                    labelText: 'Ghi chú',
                    hintText: 'Tùy chọn',
                  ),
                ),
              ],
            ),
          ],
        ),
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
        const SizedBox(height: 16),
        CustomTextField(
          controller: _receiverNameController,
          labelText: 'Tên người nhận',
          hintText: 'Nhập tên người nhận',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập tên người nhận';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.person),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _receiverPhoneController,
          labelText: 'Số điện thoại người nhận',
          hintText: 'Nhập số điện thoại',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập số điện thoại';
            }
            if (!Validators.isValidPhoneNumber(value)) {
              return 'Số điện thoại không hợp lệ';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.phone),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin bổ sung',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _userNoteController,
          labelText: 'Ghi chú cho tài xế',
          hintText: 'Ví dụ: Giao gấp, cẩn thận...',
          maxLines: 3,
          prefixIcon: const Icon(Icons.note),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _discountController,
          labelText: 'Mã giảm giá',
          hintText: 'Nhập mã giảm giá (nếu có)',
          prefixIcon: const Icon(Icons.discount),
        ),
      ],
    );
  }

  Widget _buildEstimationSection() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.estimatedFee == null) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Ước tính phí giao hàng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildEstimationRow(
                  'Khoảng cách',
                  '${orderProvider.estimatedDistance?.toStringAsFixed(1)} km',
                ),
                _buildEstimationRow(
                  'Thời gian dự kiến',
                  '${orderProvider.estimatedTime} phút',
                ),
                const Divider(),
                _buildEstimationRow(
                  'Phí giao hàng',
                  '${orderProvider.estimatedFee?.toStringAsFixed(0)} VND',
                  isTotal: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstimationRow(String label, String value,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_fromAddress != null && _toAddress != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _estimateFee,
                icon: const Icon(Icons.calculate),
                label: const Text('Ước tính phí giao hàng'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              return CustomButton(
                text: orderProvider.isCreating
                    ? 'Đang tạo đơn hàng...'
                    : 'Tạo đơn hàng',
                onPressed: () {
                  if (!orderProvider.isCreating) {
                    _createOrder();
                  }
                },
                isLoading: orderProvider.isCreating,
              );
            },
          ),
        ],
      ),
    );
  }

  void _selectAddress({required bool isFromAddress}) async {
    final result = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialAddress: isFromAddress ? _fromAddress : _toAddress,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isFromAddress) {
          _fromAddress = result;
        } else {
          _toAddress = result;
        }
      });

      // Clear previous estimation when addresses change
      context.read<OrderProvider>().clearEstimation();
    }
  }

  void _addItem() {
    setState(() {
      _items.add(OrderItemForm());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
  }

  void _estimateFee() async {
    if (_fromAddress == null || _toAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ địa chỉ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.estimateDeliveryFee(
      fromAddress: _fromAddress!,
      toAddress: _toAddress!,
    );

    if (!success && orderProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _createOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromAddress == null || _toAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ địa chỉ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prepare order items
    final orderItems = _items.map((item) {
      return OrderItem(
        name: item.nameController.text,
        quantity: int.parse(item.quantityController.text),
        note: item.noteController.text.isNotEmpty
            ? item.noteController.text
            : null,
      );
    }).toList();

    // Prepare receiver info
    final receiver = ReceiverInfo(
      name: _receiverNameController.text,
      phoneNumber: _receiverPhoneController.text,
    );

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.createOrder(
      fromAddress: _fromAddress!,
      toAddress: _toAddress!,
      items: orderItems,
      receiver: receiver,
      userNote:
          _userNoteController.text.isNotEmpty ? _userNoteController.text : null,
      discount:
          _discountController.text.isNotEmpty ? _discountController.text : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đơn hàng đã được tạo thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to order detail or tracking screen
      Navigator.of(context).pop(orderProvider.currentOrder);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Không thể tạo đơn hàng'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class OrderItemForm {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController =
      TextEditingController(text: '1');
  final TextEditingController noteController = TextEditingController();

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    noteController.dispose();
  }
}
