class ApiConstants {
  // Base URL
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Authentication endpoints
  static const String registerOtp = '/register/otp'; // Gửi OTP đăng ký
  static const String register = '/register'; // Xác nhận đăng ký với OTP
  static const String loginOtp = '/login/otp'; // Gửi OTP đăng nhập
  static const String login = '/login'; // Xác nhận đăng nhập với OTP
  static const String loginWithPassword =
      '/login/password'; // Đăng nhập bằng mật khẩu
  static const String setPassword = '/set-password'; // Thiết lập mật khẩu

  // User profile endpoints
  static const String userProfile = '/profile';
  static const String updateProfile = '/profile';
  static const String userAvatar = '/profile/avatar';

  // Order endpoints
  static const String orders = '/orders'; // Lấy danh sách đơn hàng
  static const String createOrder = '/orders'; // Tạo đơn hàng mới
  static const String orderDetail =
      '/orders'; // Chi tiết đơn hàng (GET /orders/{id})
  static const String cancelOrder =
      '/orders'; // Hủy đơn hàng (DELETE /orders/{id})
  static const String estimateFee =
      '/orders/estimate'; // Ước tính phí giao hàng
}
