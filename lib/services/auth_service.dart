import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:customer_app/models/user_model.dart';
import 'package:customer_app/constants/api_constants.dart';
import 'package:customer_app/utils/validators.dart';

class AuthService {
  static const storage = FlutterSecureStorage();

  // Headers for API requests
  Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      String? token = await storage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        print('Adding auth token to headers: $token');
        headers['Authorization'] = 'Bearer $token';
      } else {
        print('No auth token available');
      }
    }

    return headers;
  }

  // Send OTP for registration
  Future<Map<String, dynamic>> sendRegisterOtp(String phoneNumber) async {
    try {
      // Format the phone number without + sign for API
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);
      print('Sending OTP to: $formattedPhoneNumber');
      print('URL: ${ApiConstants.baseUrl}${ApiConstants.registerOtp}');

      final requestBody = {'phone_number': formattedPhoneNumber};
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerOtp}'),
        headers: await _getHeaders(withAuth: false),
        body: jsonEncode(requestBody),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Print detailed information about response structure
      if (response.body.isNotEmpty) {
        try {
          final jsonResponse = jsonDecode(response.body);
          print('Response type: ${jsonResponse.runtimeType}');
          if (jsonResponse is Map<String, dynamic>) {
            print('Response keys: ${jsonResponse.keys.toList()}');

            // Check message field type
            if (jsonResponse.containsKey('message')) {
              print('Message type: ${jsonResponse['message'].runtimeType}');
              if (jsonResponse['message'] is List) {
                print(
                    'Message list length: ${(jsonResponse['message'] as List).length}');
                print('Message list content: ${jsonResponse['message']}');
              }
            }
          }
        } catch (e) {
          print('Could not parse response as JSON: $e');
        }
      }

      return _processResponse(response);
    } catch (e) {
      print('Network error: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Register with OTP
  Future<Map<String, dynamic>> register(String phoneNumber, String otp) async {
    try {
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);
      final requestBody = {
        'phone_number': formattedPhoneNumber,
        'otp': otp,
      };
      print('Register request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
        headers: await _getHeaders(withAuth: false),
        body: jsonEncode(requestBody),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      final result = _processResponse(response);

      if (result['success'] &&
          result['data'] != null &&
          result['data']['token'] != null) {
        await storage.write(key: 'auth_token', value: result['data']['token']);
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Send OTP for login
  Future<Map<String, dynamic>> sendLoginOtp(String phoneNumber) async {
    try {
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);
      print('Login OTP request for: $formattedPhoneNumber');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginOtp}'),
        headers: await _getHeaders(withAuth: false),
        body: jsonEncode({'phone_number': formattedPhoneNumber}),
      );

      print('Login OTP response status: ${response.statusCode}');
      print('Login OTP response body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Login with OTP
  Future<Map<String, dynamic>> loginWithOtp(
      String phoneNumber, String otp) async {
    try {
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: await _getHeaders(withAuth: false),
        body: jsonEncode({
          'phone_number': formattedPhoneNumber,
          'otp': otp,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final jsonData = jsonDecode(response.body);
      print('Login JSON structure: $jsonData');

      // Check if the response contains user data
      Map<String, dynamic>? userData;
      if (jsonData is Map<String, dynamic>) {
        if (jsonData.containsKey('user')) {
          userData = jsonData['user'] as Map<String, dynamic>;
          print('Found user data in login response: $userData');
        } else if (jsonData.containsKey('data') && jsonData['data'] is Map) {
          final data = jsonData['data'] as Map<String, dynamic>;
          if (data.containsKey('user')) {
            userData = data['user'] as Map<String, dynamic>;
            print('Found user data in login response data.user: $userData');
          }
        }

        // Phone number detection from login response
        _checkForPhoneNumber(jsonData);
      }

      final result = _processResponse(response);

      if (result['success'] &&
          result['data'] != null &&
          result['data']['token'] != null) {
        final token = result['data']['token'];
        print('Saving token to secure storage: $token');
        await storage.write(key: 'auth_token', value: token);

        // If we have user data from login response, save it too
        if (userData != null) {
          // Ensure phone number is included in user data if possible
          if (!userData.containsKey('phone') &&
              !userData.containsKey('phone_number')) {
            userData['phone_number'] = formattedPhoneNumber;
          }
          print('Adding user data to result: $userData');
          result['data']['user'] = userData;
        } else if (!result['data'].containsKey('phone') &&
            !result['data'].containsKey('phone_number')) {
          // Add phone number to result data if not already present
          result['data']['phone_number'] = formattedPhoneNumber;
          print('Added phone number to result data');
        }
      } else {
        print('No token found in login response');
      }

      return result;
    } catch (e) {
      print('Login error: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Check for phone number in response
  void _checkForPhoneNumber(dynamic data) {
    if (data is! Map) return;

    final phoneKeys = ['phone', 'phone_number', 'phoneNumber', 'mobile'];
    for (final key in phoneKeys) {
      if (data.containsKey(key)) {
        print('Found phone number in response with key: $key = ${data[key]}');
      }
    }

    // Check in nested objects
    for (final entry in data.entries) {
      if (entry.value is Map) {
        for (final key in phoneKeys) {
          if ((entry.value as Map).containsKey(key)) {
            print(
                'Found phone number in response.${entry.key}.$key = ${(entry.value as Map)[key]}');
          }
        }
      }
    }
  }

  // Login with password
  Future<Map<String, dynamic>> loginWithPassword(
      String phoneNumber, String password) async {
    try {
      final formattedPhoneNumber =
          Validators.formatPhoneNumberForApi(phoneNumber);

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginWithPassword}'),
        headers: await _getHeaders(withAuth: false),
        body: jsonEncode({
          'phone_number': formattedPhoneNumber,
          'password': password,
        }),
      );

      print('Password login response status: ${response.statusCode}');
      print('Password login response body: ${response.body}');

      final jsonData = jsonDecode(response.body);
      print('Password login JSON structure: $jsonData');

      // Check if the response contains user data
      Map<String, dynamic>? userData;
      if (jsonData is Map<String, dynamic>) {
        if (jsonData.containsKey('user')) {
          userData = jsonData['user'] as Map<String, dynamic>;
          print('Found user data in password login response: $userData');
        } else if (jsonData.containsKey('data') && jsonData['data'] is Map) {
          final data = jsonData['data'] as Map<String, dynamic>;
          if (data.containsKey('user')) {
            userData = data['user'] as Map<String, dynamic>;
            print(
                'Found user data in password login response data.user: $userData');
          }
        }

        // Phone number detection from login response
        _checkForPhoneNumber(jsonData);
      }

      final result = _processResponse(response);

      if (result['success'] &&
          result['data'] != null &&
          result['data']['token'] != null) {
        final token = result['data']['token'];
        print('Saving token to secure storage: $token');
        await storage.write(key: 'auth_token', value: token);

        // If we have user data from login response, save it too
        if (userData != null) {
          // Ensure phone number is included in user data if possible
          if (!userData.containsKey('phone') &&
              !userData.containsKey('phone_number')) {
            userData['phone_number'] = formattedPhoneNumber;
          }
          print('Adding user data to result: $userData');
          result['data']['user'] = userData;
        } else if (!result['data'].containsKey('phone') &&
            !result['data'].containsKey('phone_number')) {
          // Add phone number to result data if not already present
          result['data']['phone_number'] = formattedPhoneNumber;
          print('Added phone number to result data');
        }
      } else {
        print('No token found in password login response');
      }

      return result;
    } catch (e) {
      print('Login with password error: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      // Lấy token để debug
      String? token = await storage.read(key: 'auth_token');
      print('Using token for API call: $token');

      print('Calling API: ${ApiConstants.baseUrl}${ApiConstants.userProfile}');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userProfile}'),
        headers: await _getHeaders(),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body RAW: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Response JSON structure: $jsonResponse');

        // Print detailed structure
        if (jsonResponse is Map<String, dynamic>) {
          print('Response is a Map with keys: ${jsonResponse.keys.toList()}');

          // Kiểm tra xem data nằm ở đâu
          if (jsonResponse.containsKey('data')) {
            print('Data structure: ${jsonResponse['data']}');
            if (jsonResponse['data'] is Map) {
              print(
                  'Data keys: ${(jsonResponse['data'] as Map).keys.toList()}');
            }
          } else if (jsonResponse.containsKey('user')) {
            print('User structure: ${jsonResponse['user']}');
            if (jsonResponse['user'] is Map) {
              print(
                  'User keys: ${(jsonResponse['user'] as Map).keys.toList()}');
            }
          }

          // Kiểm tra các key có thể chứa số điện thoại
          final possibleKeys = [
            'phone',
            'phone_number',
            'phoneNumber',
            'mobile'
          ];
          for (final key in possibleKeys) {
            if (jsonResponse.containsKey(key)) {
              print(
                  'Found phone number at root level with key: $key = ${jsonResponse[key]}');
            } else if (jsonResponse.containsKey('data') &&
                jsonResponse['data'] is Map) {
              final data = jsonResponse['data'] as Map;
              if (data.containsKey(key)) {
                print(
                    'Found phone number in data with key: $key = ${data[key]}');
              }
            } else if (jsonResponse.containsKey('user') &&
                jsonResponse['user'] is Map) {
              final user = jsonResponse['user'] as Map;
              if (user.containsKey(key)) {
                print(
                    'Found phone number in user with key: $key = ${user[key]}');
              }
            }
          }
        }

        // Return theo đúng cấu trúc API
        return {
          'success': true,
          'data': jsonResponse,
        };
      } else {
        print('API error: Status code ${response.statusCode}');
        return {'success': false, 'message': 'Failed to get profile info'};
      }
    } catch (e) {
      print('Error in getCurrentUser service: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userProfile}'),
        headers: await _getHeaders(),
        body: jsonEncode(profileData),
      );

      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update user avatar
  Future<Map<String, dynamic>> updateAvatar(File imageFile) async {
    try {
      final uri =
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userAvatar}');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add the image file
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'avatar',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.changePassword}'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      await storage.delete(key: 'auth_token');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if user is logged in (has token)
  Future<bool> isLoggedIn() async {
    try {
      String? token = await storage.read(key: 'auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Process API response
  Map<String, dynamic> _processResponse(http.Response response) {
    try {
      // Handle empty response
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'data': {}};
        } else {
          return {
            'success': false,
            'message': 'Empty response with status code: ${response.statusCode}'
          };
        }
      }

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        // Handle error message that might be a List
        var errorMessage = 'Unknown error occurred';
        if (data['message'] != null) {
          if (data['message'] is List) {
            // Join all error messages from the list
            errorMessage = (data['message'] as List).join(', ');
          } else if (data['message'] is String) {
            errorMessage = data['message'];
          } else {
            errorMessage = data['message'].toString();
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'error_code': data['error_code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Response parsing error: ${e.toString()}. Raw response: ${response.body}'
      };
    }
  }
}
