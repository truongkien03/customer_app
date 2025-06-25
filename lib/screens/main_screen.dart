import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/screens/home/home_tab.dart';
import 'package:customer_app/screens/orders/orders_tab.dart';
import 'package:customer_app/screens/create_order/create_order_tab.dart';
import 'package:customer_app/screens/notifications/notifications_tab.dart';
import 'package:customer_app/screens/profile/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const OrdersTab(),
    const CreateOrderTab(),
    const NotificationsTab(),
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Khi chuyển đến tab profile, tải lại thông tin user
    if (index == 4) {
      // Tab profile được chọn
      print('Profile tab selected, refreshing user data');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.getCurrentUser();
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 35,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Xin chào,',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // Cố gắng lấy thông tin từ các key phổ biến
              final name = _getValueFromKeys(authProvider.userData,
                  ['name', 'fullName', 'full_name', 'username']);

              final phone = _getValueFromKeys(authProvider.userData,
                  ['phone', 'phone_number', 'phoneNumber', 'mobile']);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name != null && name.isNotEmpty)
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (phone != null && phone.isNotEmpty)
                    Text(
                      phone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const Text(
                      'Khách hàng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  // Helper để lấy giá trị từ danh sách các key khả dụng
  String? _getValueFromKeys(Map<String, dynamic> data, List<String> keys) {
    // Kiểm tra trực tiếp
    for (final key in keys) {
      if (data.containsKey(key) &&
          data[key] != null &&
          data[key].toString().isNotEmpty) {
        return data[key].toString();
      }
    }

    // Kiểm tra trong data nếu có
    if (data.containsKey('data') && data['data'] is Map) {
      final nestedData = data['data'] as Map;
      for (final key in keys) {
        if (nestedData.containsKey(key) &&
            nestedData[key] != null &&
            nestedData[key].toString().isNotEmpty) {
          return nestedData[key].toString();
        }
      }
    }

    // Kiểm tra trong user nếu có
    if (data.containsKey('user') && data['user'] is Map) {
      final nestedUser = data['user'] as Map;
      for (final key in keys) {
        if (nestedUser.containsKey(key) &&
            nestedUser[key] != null &&
            nestedUser[key].toString().isNotEmpty) {
          return nestedUser[key].toString();
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer App'),
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerHeader(context),
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('Thông tin tài khoản'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedIndex = 4;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Lịch sử đơn hàng'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Cài đặt'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Đơn hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'Tạo đơn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Thông báo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
