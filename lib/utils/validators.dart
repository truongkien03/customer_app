class Validators {
  // Validate Vietnamese phone number format (both +84... and 0... formats)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // If it already starts with +84, do standard validation
    if (value.startsWith('+84')) {
      String digitsAfterCountryCode = value.substring(3);
      if (!RegExp(r'^\d{9,10}$').hasMatch(digitsAfterCountryCode)) {
        return 'Invalid phone number format';
      }
    }
    // If it starts with 0, consider as valid but will be formatted in the API call
    else if (value.startsWith('0')) {
      String digitsAfter0 = value.substring(1);
      if (!RegExp(r'^\d{8,9}$').hasMatch(digitsAfter0)) {
        return 'Invalid phone number format';
      }
    } else {
      return 'Phone number must start with +84 or 0';
    }

    return null; // Return null if validation passes
  }

  // Validate OTP code
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }

    // Check if OTP consists of 4 digits
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'OTP must be 4 digits';
    }

    return null; // Return null if validation passes
  }

  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // Check if password is at least 6 characters
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null; // Return null if validation passes
  }

  // Format phone number to ensure +84 format
  static String formatPhoneNumber(String phoneNumber) {
    // Remove any whitespace and special characters
    phoneNumber = phoneNumber.replaceAll(' ', '').replaceAll('-', '');

    // If starts with 0, replace with +84
    if (phoneNumber.startsWith('0')) {
      return '+84${phoneNumber.substring(1)}';
    }

    // If doesn't start with +84, add it
    if (!phoneNumber.startsWith('+84')) {
      return '+84$phoneNumber';
    }

    return phoneNumber;
  }

  // Kiểm tra số điện thoại hợp lệ
  static bool isValidPhoneNumber(String phone) {
    // Loại bỏ khoảng trắng và dấu gạch ngang
    phone = phone.replaceAll(RegExp(r'[\s-]'), '');

    // Kiểm tra số điện thoại Việt Nam
    // 1. Bắt đầu bằng +84 hoặc 84 hoặc 0
    // 2. Tiếp theo là 9 số
    // 3. Tổng độ dài từ 10-12 số (tùy vào có mã quốc gia hay không)
    final RegExp regex = RegExp(
        r'^(?:\+?84|0)(?:3[2-9]|5[2689]|7[06-9]|8[1-9]|9[0-9])[0-9]{7}$');

    return regex.hasMatch(phone);
  }

  // Format số điện thoại cho API
  static String formatPhoneNumberForApi(String phone) {
    // Loại bỏ khoảng trắng và dấu gạch ngang
    phone = phone.replaceAll(RegExp(r'[\s-]'), '');

    // Nếu số điện thoại bắt đầu bằng 0, thay thế bằng +84
    if (phone.startsWith('0')) {
      phone = '+84${phone.substring(1)}';
    }
    // Nếu số điện thoại bắt đầu bằng 84 nhưng không có dấu +
    else if (phone.startsWith('84')) {
      phone = '+$phone';
    }
    // Nếu số điện thoại không bắt đầu bằng +
    else if (!phone.startsWith('+')) {
      phone = '+84$phone';
    }

    return phone;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Name is optional
    }
    if (value.length > 255) {
      return 'Name must not exceed 255 characters';
    }
    return null;
  }

  static String? validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Latitude is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Latitude must be a number';
    }
    if (number < -90 || number > 90) {
      return 'Latitude must be between -90 and 90';
    }
    return null;
  }

  static String? validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Longitude is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Longitude must be a number';
    }
    if (number < -180 || number > 180) {
      return 'Longitude must be between -180 and 180';
    }
    return null;
  }
}
