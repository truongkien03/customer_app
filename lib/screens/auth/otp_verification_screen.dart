import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/widgets/custom_button.dart';
import 'package:customer_app/utils/validators.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isLogin;

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.isLogin,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _enableResend = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 60;
      _enableResend = false;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _enableResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _getTimerText {
    final minutes = (_resendSeconds / 60).floor();
    final seconds = _resendSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendOtp() async {
    if (!_enableResend) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (widget.isLogin) {
      success = await authProvider.sendLoginOtp(widget.phoneNumber);
    } else {
      success = await authProvider.sendRegisterOtp(widget.phoneNumber);
    }

    if (success && mounted) {
      Fluttertoast.showToast(
        msg: 'OTP sent successfully',
        backgroundColor: Colors.green,
      );
      _startResendTimer();
    } else if (mounted) {
      Fluttertoast.showToast(
        msg: authProvider.error.isNotEmpty
            ? authProvider.error
            : 'Failed to send OTP',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success;

      print(
          'Verifying OTP for ${widget.phoneNumber}, isLogin=${widget.isLogin}');

      if (widget.isLogin) {
        success = await authProvider.loginWithOtp(
            widget.phoneNumber, _otpController.text);

        print('Login result: $success');

        if (success) {
          // Kiểm tra token và dữ liệu người dùng
          final storage = const FlutterSecureStorage();
          final token = await storage.read(key: 'auth_token');
          print('Token after successful login: $token');
          print('User data: ${authProvider.userData}');
        }
      } else {
        success = await authProvider.register(
            widget.phoneNumber, _otpController.text);

        print('Registration result: $success');
      }

      setState(() {
        _isSubmitting = false;
      });

      if (success && mounted) {
        print('Navigating to home screen after successful verification');
        // Navigate to main app screen (replace current stack)
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (mounted) {
        print('Verification failed: ${authProvider.error}');
        Fluttertoast.showToast(
          msg: authProvider.error.isNotEmpty
              ? authProvider.error
              : 'Verification failed',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Display formatted phone number for UI, but keep original for API calls
    final displayPhoneNumber = widget.phoneNumber.startsWith('+')
        ? widget.phoneNumber
        : '+${widget.phoneNumber}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLogin
            ? 'Login Verification'
            : 'Registration Verification'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter Verification Code',
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'OTP has been sent to $displayPhoneNumber',
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32.0),
                PinCodeTextField(
                  appContext: context,
                  length: 4,
                  obscureText: false,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 50,
                    fieldWidth: 50,
                    activeFillColor: Colors.white,
                    inactiveFillColor: Colors.white,
                    selectedFillColor: Colors.white,
                    activeColor: Theme.of(context).primaryColor,
                    inactiveColor: Colors.grey[300],
                    selectedColor: Theme.of(context).primaryColor,
                  ),
                  cursorColor: Colors.black,
                  animationDuration: const Duration(milliseconds: 300),
                  enableActiveFill: true,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateOtp,
                  onCompleted: (v) {
                    // Auto submit when 4 digits are entered
                    _verifyOtp();
                  },
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Did not receive code?'),
                    TextButton(
                      onPressed: _enableResend ? _resendOtp : null,
                      child: _enableResend
                          ? const Text('Resend OTP')
                          : Text('Resend in $_getTimerText'),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                CustomButton(
                  text: 'Verify',
                  isLoading: authProvider.isLoading || _isSubmitting,
                  onPressed: _verifyOtp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
