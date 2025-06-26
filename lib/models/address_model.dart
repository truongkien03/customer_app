class AddressModel {
  final double lat; // Bắt buộc, kiểu số (vĩ độ)
  final double lon; // Bắt buộc, kiểu số (kinh độ)
  final String desc; // Bắt buộc, mô tả địa chỉ

  AddressModel({
    required this.lat,
    required this.lon,
    required this.desc,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      desc: json['desc'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      'desc': desc,
    };
  }
}
