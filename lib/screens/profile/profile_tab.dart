import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/widgets/custom_button.dart';
import 'package:customer_app/widgets/custom_text_field.dart';
import 'package:customer_app/screens/profile/set_password_screen.dart';
import 'package:customer_app/models/user_model.dart';
import 'package:customer_app/utils/validators.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final user = authProvider.userData;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Không thể tải thông tin người dùng',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (authProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      authProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => authProvider.getCurrentUser(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        return const ProfileForm();
      },
    );
  }
}

class ProfileForm extends StatefulWidget {
  const ProfileForm({Key? key}) : super(key: key);

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _addressDescController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final user = context.read<AuthProvider>().userData;
    if (user != null) {
      _nameController.text = user.name ?? '';
      if (user.address != null) {
        _latController.text = user.address!.lat.toString();
        _lonController.text = user.address!.lon.toString();
        _addressDescController.text = user.address!.desc;
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().updateProfile(
            name: _nameController.text.trim(),
            lat: double.parse(_latController.text),
            lon: double.parse(_lonController.text),
            addressDesc: _addressDescController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAvatar(UserModel user) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                user.avatar != null ? NetworkImage(user.avatar!) : null,
            child: user.avatar == null
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAvatar(user),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _nameController,
              labelText: 'Họ tên (không bắt buộc)',
              validator: (value) => Validators.validateName(value),
            ),
            const SizedBox(height: 16),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) => CustomTextField(
                controller: TextEditingController(
                  text: authProvider.userData?.phoneNumber ?? '',
                ),
                labelText: 'Số điện thoại',
                enabled: false,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _latController,
              labelText: 'Vĩ độ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => Validators.validateLatitude(value),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _lonController,
              labelText: 'Kinh độ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => Validators.validateLongitude(value),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _addressDescController,
              labelText: 'Địa chỉ chi tiết',
              validator: (value) =>
                  Validators.validateRequired(value, 'Địa chỉ'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Cập nhật thông tin',
              onPressed: _isLoading ? () {} : _updateProfile,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _addressDescController.dispose();
    super.dispose();
  }
}
