import 'package:flutter/material.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Đơn hàng',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
