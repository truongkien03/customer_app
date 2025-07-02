import 'dart:io';
import 'package:flutter/material.dart';
import 'package:customer_app/models/user_model.dart';
import 'package:customer_app/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math' as math;

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  UserModel? _currentUser;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserModel? get userData => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoggedIn => _currentUser != null;

  // Initialize auth state
  Future<void> initAuthState() async {
    _setLoading(true);
    print('=== Initializing auth state... ===');

    try {
      // Kiểm tra token trực tiếp
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: AuthService.TOKEN_KEY);
      print(
          'Token from storage: ${token != null ? token.substring(0, math.min<int>(10, token.length)) : 'null'}...');

      final isLoggedIn = await _authService.isLoggedIn();
      print('isLoggedIn check result: $isLoggedIn');

      if (isLoggedIn) {
        _isAuthenticated = true;
        print('📱 User is authenticated, fetching profile data...');
        // Thử lấy thông tin người dùng
        await fetchCurrentUser();
      } else {
        _isAuthenticated = false;
        print('❌ User is not logged in');
      }
    } catch (e) {
      print('❌ Error during auth initialization: $e');
      _isAuthenticated = false;
    }

    _setLoading(false);
  }

  // Send registration OTP
  Future<bool> sendRegisterOtp(String phoneNumber) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.sendRegisterOtp(phoneNumber);

      if (!result['success']) {
        _setError(result['message']);
        return false;
      }

      return true;
    } catch (e) {
      _setError('Lỗi gửi OTP: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register with OTP
  Future<bool> register(String phoneNumber, String otp) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.register(phoneNumber, otp);

      if (!result['success']) {
        _setError(result['message']);
        return false;
      }

      _isAuthenticated = true;
      await fetchCurrentUser();
      return true;
    } catch (e) {
      _setError('Lỗi đăng ký: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send login OTP
  Future<bool> sendLoginOtp(String phoneNumber) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.sendLoginOtp(phoneNumber);

      if (!result['success']) {
        _setError(result['message']);
        return false;
      }

      return true;
    } catch (e) {
      _setError('Lỗi gửi OTP: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login with OTP
  Future<bool> loginWithOtp(String phoneNumber, String otp) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.loginWithOtp(phoneNumber, otp);
      if (!result['success']) {
        _setError(result['message']);
        return false;
      }

      _isAuthenticated = true;
      await fetchCurrentUser();
      return true;
    } catch (e) {
      _setError('Lỗi đăng nhập: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login with password
  Future<bool> loginWithPassword(String phoneNumber, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result =
          await _authService.loginWithPassword(phoneNumber, password);

      if (result['success']) {
        _isAuthenticated = true;
        _setSuccess('Đăng nhập thành công');
        await fetchCurrentUser();
        return true;
      } else {
        _setError(result['message'] ?? 'Đăng nhập thất bại');
        return false;
      }
    } catch (e) {
      _setError('Lỗi đăng nhập: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Lỗi đăng xuất: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch current user data
  Future<bool> fetchCurrentUser() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.getCurrentUser();
      print('fetchCurrentUser result: $result');

      if (result['success']) {
        // Thử các cách parse khác nhau
        Map<String, dynamic>? userData;

        // Kiểm tra raw data trước
        if (result['raw'] != null) {
          final raw = result['raw'];
          print('Raw response data: $raw');

          // Nếu raw data có trực tiếp các field của user
          if (raw.containsKey('phone_number') ||
              raw.containsKey('phoneNumber')) {
            userData = raw;
          } else if (raw.containsKey('user')) {
            userData = raw['user'];
          } else if (raw.containsKey('data') && raw['data'] != null) {
            if (raw['data'].containsKey('user')) {
              userData = raw['data']['user'];
            } else {
              userData = raw['data'];
            }
          }
        }

        // Fallback to original parsing
        if (userData == null && result['data'] != null) {
          if (result['data']['user'] != null) {
            userData = result['data']['user'];
          } else if (result['data'] is Map<String, dynamic>) {
            userData = result['data'];
          }
        }

        if (userData != null) {
          print('Parsing user data: $userData');
          _currentUser = UserModel.fromJson(userData);
          print('User parsed successfully: ${_currentUser?.phoneNumber}');
          notifyListeners();
          return true;
        } else {
          _setError('Không tìm thấy dữ liệu người dùng trong response');
          print('No user data found in response: $result');
          return false;
        }
      } else {
        _setError(result['message'] ?? 'Không thể lấy thông tin người dùng');
        return false;
      }
    } catch (e) {
      print('Error in fetchCurrentUser: $e');
      _setError('Lỗi lấy thông tin người dùng: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Format error message to handle different types
  String _formatErrorMessage(dynamic message) {
    if (message == null) return 'An unknown error occurred';

    if (message is String) {
      return message;
    } else if (message is List) {
      return message.join(', ');
    } else {
      return message.toString();
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String? message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Get current user data
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      _setLoading(true);
      final response = await _authService.getCurrentUser();

      print('Response in getCurrentUser: $response');

      // Nếu response body có id, nghĩa là đây là dữ liệu user trực tiếp
      if (response['id'] != null) {
        try {
          _currentUser = UserModel.fromJson(response);
          notifyListeners();
          return response;
        } catch (e) {
          print('Error parsing user data: $e');
          _setError('Lỗi xử lý dữ liệu người dùng');
        }
      }
      // Nếu response là wrapper và có data
      else if (response['success'] && response['data'] != null) {
        try {
          _currentUser = UserModel.fromJson(response['data']);
          notifyListeners();
          return response['data'];
        } catch (e) {
          print('Error parsing user data: $e');
          _setError('Lỗi xử lý dữ liệu người dùng');
        }
      }
      // Nếu response là wrapper nhưng data null, thử parse response body
      else if (response['success'] && response['data'] == null) {
        try {
          // Lấy response body từ AuthService
          final responseBody = await _authService.getResponseBody();
          if (responseBody != null) {
            _currentUser = UserModel.fromJson(responseBody);
            notifyListeners();
            return responseBody;
          }
        } catch (e) {
          print('Error parsing response body: $e');
        }
      }

      _setError('Không thể tải thông tin người dùng');
      return {};
    } catch (e) {
      print('Error in getCurrentUser: ${e.toString()}');
      _setError('Lỗi tải thông tin người dùng: ${e.toString()}');
      return {};
    } finally {
      _setLoading(false);
    }
  }

  // Helper method để tìm kiếm số điện thoại
  void _printPhoneNumber(Map<String, dynamic> data) {
    final keys = [
      'phone',
      'phone_number',
      'phoneNumber',
      'mobile',
      'mobileNumber',
      'mobile_number',
      'phoneNo'
    ];

    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        print('AuthProvider found phone number in key: $key = ${data[key]}');
      }
    }

    // Kiểm tra các key lồng nhau phổ biến
    if (data.containsKey('data') && data['data'] is Map) {
      final nestedData = data['data'] as Map;
      for (final key in keys) {
        if (nestedData.containsKey(key) && nestedData[key] != null) {
          print(
              'AuthProvider found phone number in data.$key = ${nestedData[key]}');
        }
      }
    }

    if (data.containsKey('user') && data['user'] is Map) {
      final nestedUser = data['user'] as Map;
      for (final key in keys) {
        if (nestedUser.containsKey(key) && nestedUser[key] != null) {
          print(
              'AuthProvider found phone number in user.$key = ${nestedUser[key]}');
        }
      }
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    required double lat,
    required double lon,
    required String addressDesc,
  }) async {
    try {
      // Đảm bảo có số điện thoại từ currentUser
      if (_currentUser == null || _currentUser!.phoneNumber.isEmpty) {
        throw 'Không tìm thấy thông tin người dùng';
      }

      final result = await _authService.updateProfile({
        if (name != null && name.isNotEmpty) 'name': name,
        'phone_number':
            _currentUser!.phoneNumber, // Thêm số điện thoại vào request
        'address': {
          'lat': lat,
          'lon': lon,
          'desc': addressDesc,
        },
      });

      if (result['success'] && result['data'] != null) {
        _currentUser = UserModel.fromJson(result['data']);
        notifyListeners();
        return true;
      } else {
        throw result['message'] ?? 'Không thể cập nhật thông tin';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Update user avatar
  Future<bool> updateAvatar(File imageFile) async {
    _setLoading(true);

    try {
      final response = await _authService.updateAvatar(imageFile);

      if (response['success']) {
        // Refresh user data ngay sau khi upload thành công
        await getCurrentUser(); // Gọi API lấy thông tin user mới
        notifyListeners(); // Thông báo UI cập nhật
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating avatar: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user avatar with URL
  Future<bool> updateAvatarWithUrl(String avatarUrl) async {
    _setLoading(true);

    try {
      final response = await _authService.updateAvatarWithUrl(avatarUrl);

      if (response['success']) {
        // Refresh user data ngay sau khi upload thành công
        await getCurrentUser(); // Gọi API lấy thông tin user mới
        notifyListeners(); // Thông báo UI cập nhật
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating avatar with URL: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set password
  Future<bool> setPassword(String password, String passwordConfirmation) async {
    _setLoading(true);
    _clearError();

    try {
      final result =
          await _authService.setPassword(password, passwordConfirmation);

      if (!result['success']) {
        _setError(result['message']);
        return false;
      }

      _setSuccess(result['message'] ?? 'Password set successfully');
      return true;
    } catch (e) {
      _setError('Error setting password: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
