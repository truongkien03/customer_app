import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/screens/auth/otp_verification_screen.dart';
import 'package:customer_app/screens/auth/password_login_screen.dart';
import 'package:customer_app/utils/validators.dart';
import 'package:customer_app/utils/logger.dart';
import 'package:customer_app/widgets/custom_button.dart';
import 'package:customer_app/widgets/custom_text_field.dart';

class PhoneInputScreen extends StatefulWidget {
  final bool isLogin;

  const PhoneInputScreen({
    Key? key,
    this.isLogin = false,
  }) : super(key: key);

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _hasPassword = false; // Will be checked during OTP request
  String _debugInfo = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      print(
          'Submitting phone number: ${_phoneController.text} for ${widget.isLogin ? 'login' : 'registration'}');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = false;

      if (widget.isLogin) {
        success = await authProvider.sendLoginOtp(_phoneController.text);
      } else {
        success = await authProvider.sendRegisterOtp(_phoneController.text);
      }

      setState(() {
        _isSubmitting = false;
      });

      if (success && mounted) {
        print('OTP sent successfully');
        // Navigate to OTP verification screen
        Navigator.pushNamed(
          context,
          '/otp',
          arguments: {
            'phoneNumber': _phoneController.text,
            'isLogin': widget.isLogin,
          },
        );
      } else if (mounted) {
        print('Failed to send OTP: ${authProvider.error}');
        // Show error toast
        Fluttertoast.showToast(
          msg: authProvider.error.isNotEmpty
              ? authProvider.error
              : 'Failed to send OTP',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _navigateToOtpScreen(String phoneNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(
          phoneNumber: phoneNumber,
          isLogin: widget.isLogin,
        ),
      ),
    );
  }

  void _showPasswordOption(String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Options'),
          content: const Text(
              'You have a password set. Would you like to log in with your password instead?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Use OTP'),
              onPressed: () {
                Navigator.pop(context);
                _navigateToOtpScreen(phoneNumber);
              },
            ),
            TextButton(
              child: const Text('Use Password'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PasswordLoginScreen(
                      phoneNumber: phoneNumber,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLogin ? 'Login' : 'Register'),
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
                  widget.isLogin ? 'Welcome Back!' : 'Create Your Account',
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  widget.isLogin
                      ? 'Please enter your phone number to log in'
                      : 'Please enter your phone number to create an account',
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32.0),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  hintText: '+84...',
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhoneNumber,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\+]')),
                  ],
                  prefixIcon: const Icon(Icons.phone),
                ),
                const SizedBox(height: 24.0),
                CustomButton(
                  text: 'Send OTP',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleSubmit,
                ),
                if (widget.isLogin)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PhoneInputScreen(isLogin: false),
                          ),
                        );
                      },
                      child: const Text('Don\'t have an account? Register'),
                    ),
                  ),
                const SizedBox(height: 16.0),
                if (_debugInfo.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Debug Info:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_debugInfo),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
