import 'dart:developer' as developer;

class Logger {
  static bool _enableVerbose = true;
  static bool _enableDebug = true;
  static bool _enableInfo = true;
  static bool _enableWarning = true;
  static bool _enableError = true;

  static void configure({
    bool enableVerbose = true,
    bool enableDebug = true,
    bool enableInfo = true,
    bool enableWarning = true,
    bool enableError = true,
  }) {
    _enableVerbose = enableVerbose;
    _enableDebug = enableDebug;
    _enableInfo = enableInfo;
    _enableWarning = enableWarning;
    _enableError = enableError;
  }

  static void v(String tag, String message) {
    if (_enableVerbose) {
      developer.log('VERBOSE: $message', name: tag);
    }
  }

  static void d(String tag, String message) {
    if (_enableDebug) {
      developer.log('DEBUG: $message', name: tag);
    }
  }

  static void i(String tag, String message) {
    if (_enableInfo) {
      developer.log('INFO: $message', name: tag);
    }
  }

  static void w(String tag, String message) {
    if (_enableWarning) {
      developer.log('WARNING: $message', name: tag);
    }
  }

  static void e(String tag, String message) {
    if (_enableError) {
      developer.log('ERROR: $message', name: tag);
    }
  }
}
