import 'package:flutter/material.dart';
import 'package:customer_app/models/address_model.dart';
import 'package:customer_app/screens/map/location_picker_screen.dart';

class AddressPicker extends StatelessWidget {
  final AddressModel? address;
  final Function(AddressModel) onAddressSelected;
  final String? label;
  final String? hint;

  const AddressPicker({
    Key? key,
    this.address,
    required this.onAddressSelected,
    this.label,
    this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        InkWell(
          onTap: () async {
            final result = await Navigator.push<AddressModel>(
              context,
              MaterialPageRoute(
                builder: (context) => LocationPickerScreen(
                  initialAddress: address,
                ),
              ),
            );

            if (result != null) {
              onAddressSelected(result);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    address?.desc ?? hint ?? 'Chọn địa chỉ',
                    style: TextStyle(
                      color: address != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.location_on, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
