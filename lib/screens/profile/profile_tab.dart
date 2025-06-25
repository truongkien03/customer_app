import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/widgets/custom_button.dart';
import 'package:customer_app/widgets/custom_text_field.dart';
import 'package:customer_app/screens/profile/change_password_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isEditing = false;
  bool _isSubmitting = false;
  final _imagePicker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Load user data from provider
  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    if (userData.isEmpty) {
      await authProvider.getCurrentUser();
    }

    if (mounted) {
      // In toàn bộ dữ liệu để debug
      print('User data in profile tab: ${authProvider.userData}');

      final extractedData = _extractUserData(authProvider.userData);
      print('Extracted data: $extractedData');

      setState(() {
        // Cập nhật các trường từ dữ liệu đã được xử lý
        _nameController.text = extractedData['name'] ?? '';
        _phoneController.text = extractedData['phone'] ?? '';
        _addressController.text = extractedData['address'] ?? '';
      });
    }
  }

  // Helper method to extract user data from various JSON structures
  Map<String, String> _extractUserData(Map<String, dynamic> rawData) {
    final result = <String, String>{};

    // Kiểm tra các cấu trúc phổ biến nhất
    final Map<String, dynamic> dataToCheck = {};

    // Trường hợp 1: Dữ liệu ở root level
    dataToCheck.addAll(rawData);

    // Trường hợp 2: Dữ liệu trong key 'data'
    if (rawData.containsKey('data') && rawData['data'] is Map) {
      dataToCheck.addAll(rawData['data'] as Map<String, dynamic>);
    }

    // Trường hợp 3: Dữ liệu trong key 'user'
    if (rawData.containsKey('user') && rawData['user'] is Map) {
      dataToCheck.addAll(rawData['user'] as Map<String, dynamic>);
    }

    // Kiểm tra các key cho tên người dùng
    final nameKeys = ['name', 'fullName', 'full_name', 'username', 'userName'];
    for (final key in nameKeys) {
      if (dataToCheck.containsKey(key) && dataToCheck[key] != null) {
        result['name'] = dataToCheck[key].toString();
        print('Found name with key: $key = ${result['name']}');
        break;
      }
    }

    // Kiểm tra các key cho số điện thoại
    final phoneKeys = [
      'phone',
      'phone_number',
      'phoneNumber',
      'mobile',
      'mobileNumber',
      'mobile_number',
      'phoneNo'
    ];
    for (final key in phoneKeys) {
      if (dataToCheck.containsKey(key) && dataToCheck[key] != null) {
        result['phone'] = dataToCheck[key].toString();
        print('Found phone with key: $key = ${result['phone']}');
        break;
      }
    }

    // Kiểm tra các key cho địa chỉ
    final addressKeys = [
      'address',
      'addr',
      'location',
      'homeAddress',
      'home_address'
    ];
    for (final key in addressKeys) {
      if (dataToCheck.containsKey(key) && dataToCheck[key] != null) {
        result['address'] = dataToCheck[key].toString();
        print('Found address with key: $key = ${result['address']}');
        break;
      }
    }

    return result;
  }

  // Toggle edit mode
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset form when canceling edit
        _loadUserData();
      }
    });
  }

  // Save user profile changes
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileData = {
        'name': _nameController.text,
        'address': _addressController.text,
      };

      final success = await authProvider.updateProfile(profileData);

      setState(() {
        _isSubmitting = false;
      });

      if (success && mounted) {
        Fluttertoast.showToast(
          msg: 'Profile updated successfully',
          backgroundColor: Colors.green,
        );
        _toggleEditMode();
      } else if (mounted) {
        Fluttertoast.showToast(
          msg: authProvider.error.isNotEmpty
              ? authProvider.error
              : 'Failed to update profile',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Upload image immediately
        await _uploadImage();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to pick image: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  // Upload image to server
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateAvatar(_selectedImage!);

    setState(() {
      _isSubmitting = false;
      if (success) {
        _selectedImage = null; // Clear selected image after successful upload
      }
    });

    if (success && mounted) {
      Fluttertoast.showToast(
        msg: 'Profile picture updated successfully',
        backgroundColor: Colors.green,
      );
    } else if (mounted) {
      Fluttertoast.showToast(
        msg: authProvider.error.isNotEmpty
            ? authProvider.error
            : 'Failed to update profile picture',
        backgroundColor: Colors.red,
      );
    }
  }

  // Show image source selection dialog
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Handle logout
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.logout();

    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else if (mounted) {
      Fluttertoast.showToast(
        msg: 'Failed to logout. Please try again.',
        backgroundColor: Colors.red,
      );
    }
  }

  // Navigate to change password screen
  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final bool isLoading = authProvider.isLoading || _isSubmitting;

    // Debug information
    print('Building profile with userData: $userData');

    // Kiểm tra key của userData để phục vụ debug
    if (userData.isNotEmpty) {
      print('Available keys in userData: ${userData.keys.toList()}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          if (!isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
            ),
        ],
      ),
      body: isLoading && userData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar section
                    GestureDetector(
                      onTap: _isEditing ? _showImagePickerOptions : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!) as ImageProvider
                                : _getAvatarImageProvider(userData),
                            child: _shouldShowDefaultAvatar(userData)
                                ? const Icon(Icons.person,
                                    size: 50, color: Colors.grey)
                                : null,
                          ),
                          if (_isEditing)
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
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // User info form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            labelText: 'Tên',
                            readOnly: !_isEditing,
                            prefixIcon: const Icon(Icons.person),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập tên';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _phoneController,
                            labelText: 'Số điện thoại',
                            readOnly: true, // Cannot edit phone number
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _addressController,
                            labelText: 'Địa chỉ',
                            readOnly: !_isEditing,
                            prefixIcon: const Icon(Icons.location_on),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 24),

                          // Action buttons
                          if (_isEditing)
                            CustomButton(
                              text: 'Lưu thay đổi',
                              isLoading: isLoading,
                              onPressed: _saveProfile,
                            ),
                          if (!_isEditing) ...[
                            CustomButton(
                              text: 'Đổi mật khẩu',
                              onPressed: _navigateToChangePassword,
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Đăng xuất',
                              isLoading: isLoading,
                              onPressed: _handleLogout,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper method to get avatar image provider
  ImageProvider? _getAvatarImageProvider(Map<String, dynamic> userData) {
    // Thử các key khác nhau cho avatar
    final avatarUrl = userData['avatar_url'] ??
        userData['avatar'] ??
        userData['profile_picture'] ??
        userData['image'];

    if (avatarUrl != null && avatarUrl.toString().isNotEmpty) {
      try {
        return NetworkImage(avatarUrl.toString());
      } catch (e) {
        print('Error loading avatar: $e');
        return null;
      }
    }
    return null;
  }

  // Helper method to check if default avatar should be shown
  bool _shouldShowDefaultAvatar(Map<String, dynamic> userData) {
    if (_selectedImage != null) {
      return false; // Có ảnh được chọn
    }

    // Kiểm tra các key có thể chứa avatar
    final hasAvatar = userData['avatar_url'] != null ||
        userData['avatar'] != null ||
        userData['profile_picture'] != null ||
        userData['image'] != null;

    return !hasAvatar;
  }
}
