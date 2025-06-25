import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/widgets/custom_button.dart';
import 'package:customer_app/widgets/custom_text_field.dart';
import 'package:customer_app/utils/validators.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        Fluttertoast.showToast(
          msg: 'New passwords do not match',
          backgroundColor: Colors.red,
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (success && mounted) {
        Fluttertoast.showToast(
          msg: 'Password changed successfully',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      } else if (mounted) {
        Fluttertoast.showToast(
          msg: authProvider.error.isNotEmpty
              ? authProvider.error
              : 'Failed to change password',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _currentPasswordController,
                labelText: 'Current Password',
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _newPasswordController,
                labelText: 'New Password',
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: 'Confirm New Password',
                obscureText: true,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return Validators.validatePassword(value);
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Change Password',
                isLoading: authProvider.isLoading || _isSubmitting,
                onPressed: _changePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
