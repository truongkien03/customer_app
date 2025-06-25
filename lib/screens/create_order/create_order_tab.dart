import 'package:flutter/material.dart';

class CreateOrderTab extends StatelessWidget {
  const CreateOrderTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tạo đơn',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
