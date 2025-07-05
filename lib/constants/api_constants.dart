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
  static const String forgotPassword =
      '/password/forgot'; // Gửi OTP quên mật khẩu
  static const String resetPassword =
      '/password/reset'; // Reset mật khẩu với OTP

  // User profile endpoints
  static const String userProfile = '/profile';
  static const String updateProfile = '/profile';
  static const String userAvatar = '/profile/avatar';

  // Notification endpoints
  static const String notifications =
      '/notifications'; // Lấy danh sách thông báo

  // FCM endpoints
  static const String fcmToken = '/fcm/token'; // Đăng ký/xóa FCM token

  // Order endpoints

  static const String createOrder = '/orders'; // Tạo đơn hàng mới
  static const String ordersInprocess =
      '/orders/inproccess'; // Đơn hàng đang xử lý
  static const String ordersCompleted =
      '/orders/completed'; // Đơn hàng đã hoàn thành
  static const String orderDetail =
      '/orders'; // Chi tiết đơn hàng (GET /orders/{id})
  static const String cancelOrder =
      '/orders'; // Hủy đơn hàng (DELETE /orders/{id})
  static const String shippingFee = '/shipping-fee'; // Tính phí giao hàng
  static const String route = '/route'; // Lấy route đường đi
}
