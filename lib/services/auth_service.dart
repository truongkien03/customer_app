import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:customer_app/models/user_model.dart';
import 'package:customer_app/constants/api_constants.dart';
import 'package:customer_app/utils/validators.dart';

class AuthService {
  static const storage = FlutterSecureStorage();
  static const String TOKEN_KEY = 'access_token';
  String? _lastResponseBody; // Biến để lưu response body cuối cùng

  // ======== PHẦN XỬ LÝ TOKEN ========

  // Lưu token vào secure storage
  Future<bool> saveToken(String token) async {
    try {
      print(
          '🔐 Attempting to save token: ${token.substring(0, math.min<int>(10, token.length))}...');
      await storage.write(key: TOKEN_KEY, value: token);
      final savedToken = await storage.read(key: TOKEN_KEY);
      final success = savedToken != null && savedToken.isNotEmpty;
      print('🔐 Token saved successfully: $success');
      if (success) {
        print(
            '🔐 Verified saved token: ${savedToken.substring(0, math.min<int>(10, savedToken.length))}...');
      }
      return success;
    } catch (e) {
      print('❌ Error saving token: $e');
      return false;
    }
  }

  // Đọc token từ secure storage
  Future<String?> getToken() async {
    try {
      return await storage.read(key: TOKEN_KEY);
    } catch (e) {
      print('Lỗi khi đọc token: $e');
      return null;
    }
  }

  // Xóa token khỏi secure storage
  Future<bool> deleteToken() async {
    try {
      await storage.delete(key: TOKEN_KEY);
      return true;
    } catch (e) {
      print('Lỗi khi xóa token: $e');
      return false;
    }
  }

  // Kiểm tra xem người dùng đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Tạo headers cho request API
  Future<Map<String, String>> getHeaders({bool withAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await getToken();
      print(
          'Token in getHeaders: ${token != null ? token.substring(0, math.min<int>(10, token.length)) : 'null'}...');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('Final headers with auth: $headers');
      } else {
        print('No token available for headers');
      }
    }

    return headers;
  }

  // ======== PHẦN XỬ LÝ API ========

  // Xử lý response từ API
  Map<String, dynamic> processResponse(http.Response response) {
    try {
      print('Processing response with status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Lưu response body
      _lastResponseBody = response.body;

      // Xử lý response trống
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'data': {}};
        } else {
          return {
            'success': false,
            'message': 'Response trống với mã: ${response.statusCode}'
          };
        }
      }

      // Phân tích JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('Error parsing JSON: $e');
        print('Raw response body: ${response.body}');
        return {
          'success': false,
          'message': 'Lỗi xử lý dữ liệu từ server: ${e.toString()}'
        };
      }

      // Xử lý response thành công
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message']
        };
      }

      // Xử lý response lỗi
      String errorMessage = 'Có lỗi xảy ra';
      if (responseData.containsKey('message')) {
        if (responseData['message'] is Map) {
          // Trường hợp message là một object chứa các field errors
          final Map<String, dynamic> messageObj = responseData['message'];
          if (messageObj.containsKey('field')) {
            final List<dynamic> errors = messageObj['field'];
            errorMessage = errors.join(', ');
          }
        } else {
          // Trường hợp message là string
          errorMessage = responseData['message'].toString();
        }
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('Error in processResponse: $e');
      return {
        'success': false,
        'message': 'Lỗi xử lý response: ${e.toString()}'
      };
    }
  }

  // Lấy response body cuối cùng
  Map<String, dynamic>? getResponseBody() {
    if (_lastResponseBody == null) return null;
    try {
      return jsonDecode(_lastResponseBody!);
    } catch (e) {
      print('Error parsing last response body: $e');
      return null;
    }
  }

  // ======== PHẦN ĐĂNG NHẬP/ĐĂNG KÝ ========

  // Gửi OTP đăng ký
  Future<Map<String, dynamic>> sendRegisterOtp(String phoneNumber) async {
    try {
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerOtp}'),
        headers: await getHeaders(withAuth: false),
        body: jsonEncode({'phone_number': formattedPhoneNumber}),
      );

      return processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Đăng ký với OTP
  Future<Map<String, dynamic>> register(String phoneNumber, String otp) async {
    try {
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
        headers: await getHeaders(withAuth: false),
        body: jsonEncode({
          'phone_number': formattedPhoneNumber,
          'otp': otp,
        }),
      );

      print('📱 Register response status: ${response.statusCode}');
      print('📱 Raw response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        print('📦 Parsed response data: $responseData');

        if (responseData != null &&
            responseData['data'] != null &&
            responseData['data']['accessToken'] != null) {
          final accessToken = responseData['data']['accessToken'];
          print(
              '🎟️ Access token received: ${accessToken.substring(0, math.min<int>(10, accessToken.length))}...');

          final saved = await saveToken(accessToken);
          print('💾 Token save attempt result: $saved');

          // Verify token was saved
          final savedToken = await getToken();
          print('🔍 Verifying saved token...');
          if (savedToken != null) {
            print(
                '✅ Token verified: ${savedToken.substring(0, math.min<int>(10, savedToken.length))}...');
            return {
              'success': true,
              'data': responseData['data'],
              'message': 'Đăng ký thành công'
            };
          } else {
            print('❌ No token found after save attempt');
            return {'success': false, 'message': 'Lỗi lưu token đăng ký'};
          }
        } else {
          print('❌ Invalid response data structure');
          print('📦 Available data: $responseData');
          return {
            'success': false,
            'message': 'Không tìm thấy token trong response'
          };
        }
      } else {
        print('❌ Register failed with status: ${response.statusCode}');
        return processResponse(response);
      }
    } catch (e) {
      print('❌ Error during registration: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Gửi OTP đăng nhập
  Future<Map<String, dynamic>> sendLoginOtp(String phoneNumber) async {
    try {
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginWithPassword}'),
        headers: await getHeaders(withAuth: false),
        body: jsonEncode({'phone_number': formattedPhoneNumber}),
      );

      return processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Đăng nhập với OTP
  Future<Map<String, dynamic>> loginWithOtp(
      String phoneNumber, String otp) async {
    try {
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);

      print('📱 Sending login request for phone: $formattedPhoneNumber');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginOtp}'),
        headers: await getHeaders(withAuth: false),
        body: jsonEncode({
          'phone_number': formattedPhoneNumber,
          'otp': otp,
        }),
      );

      print('📱 Login response status: ${response.statusCode}');
      print('📱 Raw response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        print('📦 Parsed response data: $responseData');

        if (responseData != null &&
            responseData['data'] != null &&
            responseData['data']['accessToken'] != null) {
          final accessToken = responseData['data']['accessToken'];
          print(
              '🎟️ Access token received: ${accessToken.substring(0, math.min<int>(10, accessToken.length))}...');

          final saved = await saveToken(accessToken);
          print('💾 Token save attempt result: $saved');

          // Verify token was saved
          final savedToken = await getToken();
          print('🔍 Verifying saved token...');
          if (savedToken != null) {
            print(
                '✅ Token verified: ${savedToken.substring(0, math.min<int>(10, savedToken.length))}...');
            return {
              'success': true,
              'data': responseData['data'],
              'message': 'Đăng nhập thành công'
            };
          } else {
            print('❌ No token found after save attempt');
            return {'success': false, 'message': 'Lỗi lưu token đăng nhập'};
          }
        } else {
          print('❌ Invalid response data structure');
          print('📦 Available data: $responseData');
          return {
            'success': false,
            'message': 'Không tìm thấy token trong response'
          };
        }
      } else {
        print('❌ Login failed with status: ${response.statusCode}');
        return processResponse(response);
      }
    } catch (e, stackTrace) {
      print('❌ Error during login: $e');
      print('📛 Stack trace: $stackTrace');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Đăng nhập bằng mật khẩu
  Future<Map<String, dynamic>> loginWithPassword(
      String phoneNumber, String password) async {
    try {
      print('Attempting to login with password for phone: $phoneNumber');

      // Format phone number to international format
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);
      print('Formatted phone number: $formattedPhoneNumber');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginWithPassword}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone_number': formattedPhoneNumber,
          'password': password,
        }),
      );

      print('Login with password response status: ${response.statusCode}');
      print('Login with password response body: ${response.body}');

      final result = processResponse(response);

      if (result['success']) {
        // Lưu token
        if (result['data'] != null && result['data']['token'] != null) {
          final token = result['data']['token'] as String;
          await saveToken(token);
          print('Token saved successfully');
        } else {
          print('Warning: No token received in successful login response');
        }
      }

      return result;
    } catch (e) {
      print('Error in loginWithPassword: ${e.toString()}');
      return {'success': false, 'message': 'Lỗi đăng nhập: ${e.toString()}'};
    }
  }

  // Đăng xuất
  Future<bool> logout() async {
    return await deleteToken();
  }

  // ======== PHẦN THÔNG TIN NGƯỜI DÙNG ========

  // Lấy thông tin người dùng hiện tại
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userProfile}'),
        headers: await getHeaders(),
      );

      return processResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi lấy thông tin người dùng: ${e.toString()}'
      };
    }
  }

  // Cập nhật thông tin người dùng
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    try {
      print('Updating profile with data: $profileData');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateProfile}'),
        headers: await getHeaders(),
        body: jsonEncode({
          'name': profileData['name'],
          'phone_number': profileData['phone_number'],
          'address': {
            'lat': profileData['address']['lat'],
            'lon': profileData['address']['lon'],
            'desc': profileData['address']['desc'],
          },
        }),
      );

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response body: ${response.body}');

      return processResponse(response);
    } catch (e) {
      print('Error updating profile: $e');
      return {
        'success': false,
        'message': 'Lỗi cập nhật thông tin: ${e.toString()}'
      };
    }
  }

  // Cập nhật avatar
  Future<Map<String, dynamic>> updateAvatar(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      var request = http.MultipartRequest('POST',
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userAvatar}'));

      // Add headers
      final headers = await getHeaders();
      request.headers.addAll(headers);

      // Add file
      var pic = await http.MultipartFile.fromPath('avatar', imageFile.path,
          filename: fileName);
      request.files.add(pic);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return processResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi cập nhật avatar: ${e.toString()}'
      };
    }
  }

  // Đặt mật khẩu
  Future<Map<String, dynamic>> setPassword(
      String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.setPassword}'),
        headers: await getHeaders(),
        body: jsonEncode({
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      return processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi đặt mật khẩu: ${e.toString()}'};
    }
  }
}
