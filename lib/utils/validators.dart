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

  // Format phone number for API that accepts + sign
  static String formatPhoneNumberForApi(String phoneNumber) {
    // Just use the standard format with + sign
    return formatPhoneNumber(phoneNumber);
  }
}
