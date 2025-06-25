import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:customer_app/models/user_model.dart';
import 'package:customer_app/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  User? _currentUser;
  String _error = '';
  Map<String, dynamic> _userData = {};

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  String get error => _error;
  Map<String, dynamic> get userData => _userData;

  // Initialize auth state
  Future<void> initAuthState() async {
    _setLoading(true);
    print('Initializing auth state...');

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      print('isLoggedIn check result: $isLoggedIn');

      if (isLoggedIn) {
        _isAuthenticated = true;
        // Thử lấy thông tin người dùng
        final userResult = await _authService.getCurrentUser();

        if (userResult['success']) {
          _userData = userResult['data'];
          print('User data loaded: $_userData');
        } else {
          print(
              'Failed to load user data while initializing: ${userResult['message']}');
          // Nếu không lấy được thông tin user, có thể token không hợp lệ
          // Trong trường hợp này, nên đăng xuất
          await logout();
        }
      } else {
        _isAuthenticated = false;
        print('User is not logged in');
      }
    } catch (e) {
      print('Error during auth initialization: $e');
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
        _setError(_formatErrorMessage(result['message']));
        return false;
      }

      return true;
    } catch (e) {
      _setError('Failed to send OTP: ${e.toString()}');
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
        _setError(_formatErrorMessage(result['message']));
        return false;
      }

      _isAuthenticated = true;
      await _fetchCurrentUser();
      return true;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
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
        _setError(_formatErrorMessage(result['message']));
        return false;
      }

      return true;
    } catch (e) {
      _setError('Failed to send OTP: ${e.toString()}');
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
      final response = await _authService.loginWithOtp(phoneNumber, otp);
      print('Login response: $response');

      if (response['success']) {
        _isAuthenticated = true;

        // Kiểm tra token có được lưu thành công không
        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'auth_token');
        print('Token after login: $token');

        if (response['data'] != null) {
          _userData = response['data'];

          // Lưu số điện thoại trực tiếp vào userData nếu chưa có
          if (!_userData.containsKey('phone') &&
              !_userData.containsKey('phone_number') &&
              !_userData.containsKey('phoneNumber')) {
            print('Adding phone number directly to userData: $phoneNumber');
            _userData['phone_number'] = phoneNumber;
          }

          print('Login user data: $_userData');
        } else {
          // Nếu không có data trong response, thử lấy dữ liệu người dùng
          await getCurrentUser();
        }

        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Login with password
  Future<bool> loginWithPassword(String phoneNumber, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result =
          await _authService.loginWithPassword(phoneNumber, password);
      print('Login with password response: $result');

      if (result['success']) {
        _isAuthenticated = true;

        // Kiểm tra token có được lưu thành công không
        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'auth_token');
        print('Token after password login: $token');

        if (result['data'] != null) {
          _userData = result['data'];

          // Lưu số điện thoại trực tiếp vào userData nếu chưa có
          if (!_userData.containsKey('phone') &&
              !_userData.containsKey('phone_number') &&
              !_userData.containsKey('phoneNumber')) {
            print(
                'Adding phone number directly to userData in password login: $phoneNumber');
            _userData['phone_number'] = phoneNumber;
          }

          print('Password login user data: $_userData');
        } else {
          // Nếu không có data trong response, thử lấy dữ liệu người dùng
          await getCurrentUser();
        }

        return true;
      } else {
        _setError(_formatErrorMessage(result['message']));
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<bool> logout() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.logout();

      if (result) {
        _isAuthenticated = false;
        _currentUser = null;
      } else {
        _setError('Logout failed');
      }

      return result;
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch current user data
  Future<void> _fetchCurrentUser() async {
    try {
      final result = await _authService.getCurrentUser();

      if (result['success'] && result['data'] != null) {
        _currentUser = User.fromJson(result['data']['user']);
      } else {
        _setError(_formatErrorMessage(result['message']));
      }
    } catch (e) {
      _setError('Failed to fetch user data: ${e.toString()}');
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

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = '';
    notifyListeners();
  }

  // Get current user data
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      _setLoading(true);
      final response = await _authService.getCurrentUser();

      // Print the response for debugging
      print('getCurrentUser API response: $response');

      if (response['success']) {
        // Kiểm tra cấu trúc data
        if (response['data'] != null) {
          if (response['data'] is Map<String, dynamic>) {
            // Có thể dữ liệu người dùng nằm trong các key khác nhau
            _userData = response['data'];

            // Nếu có key 'data' lồng bên trong
            if (_userData.containsKey('data') && _userData['data'] is Map) {
              _userData = {
                ..._userData,
                ..._userData['data'] as Map<String, dynamic>
              };
            }

            // Nếu có key 'user' lồng bên trong
            if (_userData.containsKey('user') && _userData['user'] is Map) {
              _userData = {
                ..._userData,
                ..._userData['user'] as Map<String, dynamic>
              };
            }
          } else if (response['data'] is String) {
            // Trường hợp data là JSON string
            try {
              _userData = jsonDecode(response['data']);
            } catch (e) {
              print('Error parsing user data: $e');
              _userData = {};
            }
          } else {
            print('Unexpected data type: ${response['data'].runtimeType}');
            _userData = {};
          }
        } else {
          _userData = {};
        }

        print('Final user data set in provider: $_userData');
        _printPhoneNumber(_userData);
      } else {
        _setError(response['message'] ?? 'Failed to load profile');
      }

      _setLoading(false);
      return _userData;
    } catch (e) {
      print('Error in getCurrentUser: ${e.toString()}');
      _setError('Failed to load profile: ${e.toString()}');
      _setLoading(false);
      return {};
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
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.updateProfile(profileData);

      if (response['success']) {
        _userData = response['data'];
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to update profile');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Update user avatar
  Future<bool> updateAvatar(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.updateAvatar(imageFile);

      if (response['success']) {
        _userData = response['data'];
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to update avatar');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to update avatar: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _authService.changePassword(currentPassword, newPassword);

      if (response['success']) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to change password');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to change password: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}
