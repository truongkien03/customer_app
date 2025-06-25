class User {
  final String? id;
  final String phoneNumber;
  final String? email;
  final String? name;
  final String? avatar;
  final bool hasPassword;

  User({
    this.id,
    required this.phoneNumber,
    this.email,
    this.name,
    this.avatar,
    this.hasPassword = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      name: json['name'],
      avatar: json['avatar'],
      hasPassword: json['has_password'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'email': email,
      'name': name,
      'avatar': avatar,
      'has_password': hasPassword,
    };
  }
}
