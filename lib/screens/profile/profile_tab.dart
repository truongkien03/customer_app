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
import 'package:customer_app/models/address_model.dart';
import 'package:customer_app/utils/validators.dart';
import 'package:customer_app/widgets/address_picker.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading || _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = authProvider.userData;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Không thể tải thông tin người dùng'),
                if (authProvider.errorMessage != null)
                  Text(authProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: () => authProvider.getCurrentUser(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildAvatar(user),
              const SizedBox(height: 24),
              const ProfileForm(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(UserModel user) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: user.avatar != null
              ? NetworkImage(
                  '${user.avatar}?v=${DateTime.now().millisecondsSinceEpoch}')
              : null,
          child:
              user.avatar == null ? const Icon(Icons.person, size: 50) : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: CircleAvatar(
            backgroundColor: Colors.blue,
            radius: 18,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              onPressed: _showImageSourceDialog,
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ảnh đại diện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Nhập URL ảnh'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog() {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập URL ảnh'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            labelText: 'URL ảnh',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (urlController.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() => _isLoading = true);

                try {
                  final authProvider = context.read<AuthProvider>();
                  final success = await authProvider
                      .updateAvatarWithUrl(urlController.text);
                  if (success) {
                    // Chỉ refresh data user khi thành công
                    await authProvider.fetchCurrentUser();
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // Kiểm tra kích thước file
      final file = File(image.path);
      final fileSize = await file.length();
      if (fileSize > 2 * 1024 * 1024) {
        // 2MB
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.updateAvatar(File(image.path));

      if (success) {
        // Chỉ refresh data user khi thành công
        await authProvider.fetchCurrentUser();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
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
  AddressModel? _address;
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
        _address = user.address;
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().updateProfile(
            name: _nameController.text.trim(),
            lat: _address!.lat,
            lon: _address!.lon,
            addressDesc: _address!.desc,
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userData!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          AddressPicker(
            label: 'Địa chỉ',
            hint: 'Chọn địa chỉ của bạn',
            address: _address,
            onAddressSelected: (address) {
              setState(() {
                _address = address;
              });
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Cập nhật thông tin',
            onPressed: _isLoading ? () {} : () => _updateProfile(),
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Đặt mật khẩu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SetPasswordScreen(),
                ),
              );
            },
            backgroundColor: Colors.deepPurple[100],
            textColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
