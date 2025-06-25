import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/utils/validators.dart';
import 'package:customer_app/widgets/custom_button.dart';
import 'package:customer_app/widgets/custom_text_field.dart';

class PasswordLoginScreen extends StatefulWidget {
  final String phoneNumber;

  const PasswordLoginScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends State<PasswordLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.loginWithPassword(
        widget.phoneNumber,
        _passwordController.text,
      );

      if (success && mounted) {
        // Navigate to main app screen (replace current stack)
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (mounted) {
        Fluttertoast.showToast(
          msg: authProvider.error.isNotEmpty
              ? authProvider.error
              : 'Login failed',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Display formatted phone number for UI
    final displayPhoneNumber = widget.phoneNumber.startsWith('+')
        ? widget.phoneNumber
        : '+${widget.phoneNumber}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login with Password'),
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
                  'Welcome Back!',
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Login with your password for $displayPhoneNumber',
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32.0),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24.0),
                CustomButton(
                  text: 'Login',
                  isLoading: authProvider.isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to phone input
                    },
                    child: const Text('Use OTP instead'),
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
