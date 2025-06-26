import 'address_model.dart';

class UserModel {
  final String? name; // Tùy chọn, tối đa 255 ký tự
  final String phoneNumber; // Tùy chọn, tối đa 255 ký tự
  final AddressModel address; // Bắt buộc
  final String? avatar; // Tùy chọn, URL avatar

  UserModel({
    this.name,
    required this.phoneNumber,
    required this.address,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? avatarUrl = json['avatar'] as String?;
    // Xử lý URL avatar an toàn
    if (avatarUrl != null && avatarUrl.length > 500) {
      print('Avatar URL quá dài, có thể gây lỗi: ${avatarUrl.length} ký tự');
      avatarUrl = null; // Bỏ qua URL nếu quá dài
    }

    return UserModel(
      name: json['name'] as String?,
      phoneNumber: json['phone_number'] as String,
      address: AddressModel.fromJson(json['address'] as Map<String, dynamic>),
      avatar: avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'address': address.toJson(),
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
