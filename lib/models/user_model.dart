import 'address_model.dart';

class UserModel {
  final String? name; // Tùy chọn, tối đa 255 ký tự
  final String phoneNumber; // Bắt buộc
  final AddressModel? address; // Tùy chọn - có thể null
  final String? avatar; // Tùy chọn, URL avatar

  UserModel({
    this.name,
    required this.phoneNumber,
    this.address,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('UserModel.fromJson input: $json');

    String? avatarUrl = json['avatar'] as String?;
    // Xử lý URL avatar an toàn
    if (avatarUrl != null && avatarUrl.length > 500) {
      print('Avatar URL quá dài, có thể gây lỗi: ${avatarUrl.length} ký tự');
      avatarUrl = null; // Bỏ qua URL nếu quá dài
    }

    // Xử lý phone number với các tên field khác nhau
    String? phoneNumber;
    if (json.containsKey('phone_number')) {
      phoneNumber = json['phone_number'] as String?;
    } else if (json.containsKey('phoneNumber')) {
      phoneNumber = json['phoneNumber'] as String?;
    } else if (json.containsKey('phone')) {
      phoneNumber = json['phone'] as String?;
    }

    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw Exception('Phone number is required but not found in JSON: $json');
    }

    // Xử lý address an toàn
    AddressModel? address;
    if (json['address'] != null && json['address'] is Map<String, dynamic>) {
      try {
        address =
            AddressModel.fromJson(json['address'] as Map<String, dynamic>);
      } catch (e) {
        print('Error parsing address: $e');
        address = null;
      }
    }

    final userModel = UserModel(
      name: json['name'] as String?,
      phoneNumber: phoneNumber,
      address: address,
      avatar: avatarUrl,
    );

    print('UserModel created: ${userModel.phoneNumber}');
    return userModel;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'address': address?.toJson(),
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    String? name,
    String? phoneNumber,
    AddressModel? address,
    String? avatar,
  }) {
    return UserModel(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
    );
  }
}
