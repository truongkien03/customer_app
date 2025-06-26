import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/screens/auth/otp_verification_screen.dart';
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
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isPasswordLogin = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      bool success;

      if (_isPasswordLogin) {
        success = await authProvider.loginWithPassword(
          _phoneController.text,
          _passwordController.text,
        );
      } else {
        if (widget.isLogin) {
          success = await authProvider.sendLoginOtp(_phoneController.text);
        } else {
          success = await authProvider.sendRegisterOtp(_phoneController.text);
        }
      }

      if (!mounted) return;

      if (success) {
        if (_isPasswordLogin) {
          // Đăng nhập thành công, chuyển đến màn hình chính
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Gửi OTP thành công, chuyển đến màn hình xác thực OTP
          Navigator.pushNamed(
            context,
            '/otp_verification',
            arguments: {
              'phoneNumber': _phoneController.text,
              'isLogin': widget.isLogin,
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Có lỗi xảy ra. Vui lòng thử lại.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLogin ? 'Đăng nhập' : 'Đăng ký'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isLogin ? 'Chào mừng trở lại!' : 'Tạo tài khoản mới',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isLogin
                    ? 'Đăng nhập để tiếp tục'
                    : 'Đăng ký để bắt đầu sử dụng ứng dụng',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Số điện thoại',
                hintText: 'Nhập số điện thoại',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (!Validators.isValidPhoneNumber(value)) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
                prefixIcon: const Icon(Icons.phone),
              ),
              if (widget.isLogin) ...[
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isPasswordLogin = !_isPasswordLogin;
                          });
                        },
                        icon: Icon(
                            _isPasswordLogin ? Icons.message : Icons.password),
                        label: Text(_isPasswordLogin
                            ? 'Đăng nhập bằng OTP'
                            : 'Đăng nhập bằng mật khẩu'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isPasswordLogin) ...[
                  const SizedBox(height: 16.0),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu',
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24.0),
              CustomButton(
                text: _isSubmitting
                    ? 'Đang xử lý...'
                    : (widget.isLogin ? 'Đăng nhập' : 'Đăng ký'),
                onPressed: () {
                  if (!_isSubmitting) {
                    _handleSubmit();
                  }
                },
                isLoading: _isSubmitting,
              ),
              if (widget.isLogin) ...[
                const SizedBox(height: 16.0),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PhoneInputScreen(isLogin: false),
                        ),
                      );
                    },
                    child: const Text('Chưa có tài khoản? Đăng ký'),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16.0),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PhoneInputScreen(isLogin: true),
                        ),
                      );
                    },
                    child: const Text('Đã có tài khoản? Đăng nhập'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
