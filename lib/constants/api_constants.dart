class ApiConstants {
  // Base URL
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Authentication endpoints
  static const String registerOtp = '/register/otp';
  static const String register = '/register';
  static const String loginOtp = '/login/otp';
  static const String login = '/login';
  static const String loginWithPassword =
      '/login/password'; // Password login endpoint

  // User profile endpoints
  static const String userProfile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String userAvatar = '/profile/avatar';
  static const String changePassword = '/password';

  // Order endpoints
  static const String orders = '/orders';
  static const String createOrder = '/orders/create';
}
