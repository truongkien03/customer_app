import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

      // Phân tích JSON an toàn
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ JSON parse error: $e');
        print('📱 Raw response body: ${response.body}');

        // Nếu là response thành công nhưng không parse được JSON
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {
            'success': false,
            'message': 'Server trả về dữ liệu không đúng định dạng'
          };
        } else {
          return {
            'success': false,
            'message': 'Lỗi xử lý dữ liệu từ server: ${e.toString()}'
          };
        }
      }

      // Xử lý response thành công
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Trả về cả responseData và data riêng biệt để dễ xử lý
        return {
          'success': true,
          'data': responseData.containsKey('data')
              ? responseData['data']
              : responseData,
          'message': responseData['message'],
          'raw': responseData, // Thêm raw data để debug
        };
      }

      // Xử lý response lỗi
      String errorMessage = 'Có lỗi xảy ra';

      // Kiểm tra error format mới với errorCode
      if (responseData.containsKey('error') && responseData['error'] == true) {
        if (responseData.containsKey('errorCode')) {
          final errorCodeData = responseData['errorCode'];
          if (errorCodeData is Map<String, dynamic>) {
            // Xử lý từng field error
            List<String> errors = [];
            errorCodeData.forEach((field, codes) {
              if (codes is List) {
                for (var code in codes) {
                  errors.add(_getErrorMessageByCode(field, code.toString()));
                }
              }
            });
            if (errors.isNotEmpty) {
              errorMessage = errors.join(', ');
            }
          }
        }
      } else if (responseData.containsKey('message')) {
        // Xử lý format message cũ
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

      return {
        'success': false,
        'message': errorMessage,
        'errorCode': responseData.containsKey('errorCode')
            ? responseData['errorCode']
            : null,
      };
    } catch (e) {
      print('Error in processResponse: $e');
      return {
        'success': false,
        'message': 'Lỗi xử lý response: ${e.toString()}'
      };
    }
  }

  // Helper method để convert error code thành message
  String _getErrorMessageByCode(String field, String code) {
    switch (field) {
      case 'password':
        switch (code) {
          case '4071':
            return 'Số điện thoại chưa đăng ký hoặc chưa thiết lập mật khẩu';
          default:
            return 'Lỗi mật khẩu ($code)';
        }
      case 'phone_number':
        switch (code) {
          case '4001':
            return 'Số điện thoại không hợp lệ';
          case '4002':
            return 'Số điện thoại đã được đăng ký';
          case '4003':
            return 'Số điện thoại chưa đăng ký';
          default:
            return 'Lỗi số điện thoại ($code)';
        }
      case 'otp':
        switch (code) {
          case '4101':
            return 'Mã OTP không đúng';
          case '4102':
            return 'Mã OTP đã hết hạn';
          default:
            return 'Lỗi mã OTP ($code)';
        }
      default:
        return 'Lỗi $field ($code)';
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

      print('📱 Sending login OTP request for phone: $formattedPhoneNumber');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginOtp}'),
        headers: await getHeaders(withAuth: false),
        body: jsonEncode({'phone_number': formattedPhoneNumber}),
      );

      print('📱 Login OTP response status: ${response.statusCode}');
      print('📱 Login OTP response body: ${response.body}');

      return processResponse(response);
    } catch (e) {
      print('❌ Error sending login OTP: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Đăng nhập với OTP
  Future<Map<String, dynamic>> loginWithOtp(
      String phoneNumber, String otp) async {
    try {
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);

      print(
          '📱 Sending login verification for phone: $formattedPhoneNumber, OTP: $otp');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: await getHeaders(withAuth: false),
        body: jsonEncode({
          'phone_number': formattedPhoneNumber,
          'otp': otp,
        }),
      );

      print('📱 Login verification response status: ${response.statusCode}');
      print('📱 Login verification response body: ${response.body}');

      // Xử lý response trống
      if (response.body.isEmpty) {
        print('❌ Empty response body');
        return {'success': false, 'message': 'Server trả về response trống'};
      }

      // Parse JSON an toàn
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ JSON parse error: $e');
        print('📱 Raw response: ${response.body}');
        return {'success': false, 'message': 'Lỗi xử lý dữ liệu từ server'};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('📦 Parsed response data: $responseData');

        if (responseData['data'] != null &&
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
        print(
            '❌ Login verification failed with status: ${response.statusCode}');
        return processResponse(response);
      }
    } catch (e, stackTrace) {
      print('❌ Error during login verification: $e');
      print('📛 Stack trace: $stackTrace');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Đăng nhập bằng mật khẩu
  Future<Map<String, dynamic>> loginWithPassword(
      String phoneNumber, String password) async {
    try {
      print('Attempting to login with password for phone: $phoneNumber');

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

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Xử lý token từ response data
        if (responseData['data'] != null &&
            responseData['data']['accessToken'] != null) {
          final token = responseData['data']['accessToken'] as String;
          await saveToken(token);
          print('Token saved successfully');
        }

        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message']
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Đăng nhập thất bại'
      };
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

  // Cập nhật avatar bằng URL
  Future<Map<String, dynamic>> updateAvatarWithUrl(String avatarUrl) async {
    try {
      // Kiểm tra độ dài URL
      if (avatarUrl.length > 2048) {
        return {
          'success': false,
          'message': 'URL ảnh quá dài (tối đa 2048 ký tự)'
        };
      }

      final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userAvatar}'),
          headers: await getHeaders(),
          body: jsonEncode({'avatar': avatarUrl}));

      print('Update avatar URL response status: ${response.statusCode}');
      print('Update avatar URL response body: ${response.body}');

      // Xử lý response thành công
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData, // Trả về toàn bộ response data
          'message': 'Cập nhật ảnh đại diện thành công'
        };
      }

      // Xử lý response lỗi
      return {
        'success': false,
        'message': 'Lỗi cập nhật ảnh đại diện: ${response.statusCode}'
      };
    } catch (e) {
      print('Error updating avatar URL: $e');
      return {
        'success': false,
        'message': 'Lỗi cập nhật avatar: ${e.toString()}'
      };
    }
  }

  // Cập nhật avatar bằng file
  Future<Map<String, dynamic>> updateAvatar(File imageFile) async {
    try {
      // Kiểm tra kích thước file
      final fileSize = await imageFile.length();
      if (fileSize > 2 * 1024 * 1024) {
        // 2MB
        return {
          'success': false,
          'message': 'Kích thước ảnh không được vượt quá 2MB'
        };
      }

      String fileName = imageFile.path.split('/').last;
      var request = http.MultipartRequest('POST',
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userAvatar}'));

      // Add headers
      final headers = await getHeaders();
      request.headers.addAll(headers);

      // Add file với key là 'avatar' theo yêu cầu API
      var pic = await http.MultipartFile.fromPath('avatar', imageFile.path,
          filename: fileName);
      request.files.add(pic);

      print('Sending avatar file request...');
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Update avatar file response status: ${response.statusCode}');
      print('Update avatar file response body: ${response.body}');

      return processResponse(response);
    } catch (e) {
      print('Error updating avatar file: $e');
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
