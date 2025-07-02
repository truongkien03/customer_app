import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/utils/validators.dart';
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
            '/otp',
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

  String _getButtonText() {
    if (widget.isLogin) {
      if (_isPasswordLogin) {
        return 'Đăng nhập với mật khẩu';
      } else {
        return 'Gửi mã OTP';
      }
    } else {
      return 'Đăng ký';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLogin ? 'Đăng nhập' : 'Đăng ký'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
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

              // Phone Number Field
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

              // Login Method Selection (Only for Login)
              if (widget.isLogin) ...[
                const SizedBox(height: 20.0),
                Text(
                  'Chọn phương thức đăng nhập',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 12.0),

                // Login Method Toggle Cards
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPasswordLogin = false;
                            _passwordController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: !_isPasswordLogin
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1)
                                : Colors.grey[100],
                            border: Border.all(
                              color: !_isPasswordLogin
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.message,
                                color: !_isPasswordLogin
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Đăng nhập\nbằng OTP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: !_isPasswordLogin
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Mã xác thực qua SMS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPasswordLogin = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: _isPasswordLogin
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1)
                                : Colors.grey[100],
                            border: Border.all(
                              color: _isPasswordLogin
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lock,
                                color: _isPasswordLogin
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Đăng nhập\nbằng mật khẩu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _isPasswordLogin
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Nhanh chóng và tiện lợi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Password Field (Only when password login is selected)
                if (_isPasswordLogin) ...[
                  const SizedBox(height: 24.0),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu của bạn',
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

              const SizedBox(height: 32.0),

              // Submit Button
              CustomButton(
                text: _isSubmitting ? 'Đang xử lý...' : _getButtonText(),
                onPressed: () {
                  if (!_isSubmitting) {
                    _handleSubmit();
                  }
                },
                isLoading: _isSubmitting,
              ),

              // Navigation Links
              if (widget.isLogin) ...[
                const SizedBox(height: 24.0),
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
                const SizedBox(height: 24.0),
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
