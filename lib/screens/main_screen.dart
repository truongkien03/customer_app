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
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Chỉ tải lại dữ liệu user nếu tab profile được chọn và chưa có dữ liệu
    if (index == 4) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userData == null) {
        authProvider.getCurrentUser();
      }
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
              final user = authProvider.userData;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user?.name != null && user!.name!.isNotEmpty)
                    Text(
                      user.name!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (user?.phoneNumber != null)
                    Text(
                      user!.phoneNumber,
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer App'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: Colors.deepPurple,
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final user = authProvider.userData;
                          return CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: user?.avatar != null
                                ? NetworkImage(
                                    '${user!.avatar}?v=${DateTime.now().millisecondsSinceEpoch}')
                                : null,
                            child: user?.avatar == null
                                ? const Icon(Icons.person,
                                    size: 35, color: Colors.grey)
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Xin chào,',
                        style: TextStyle(color: Colors.white),
                      ),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return Text(
                            authProvider.userData?.name ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.person_outline, color: Colors.black87),
                title: const Text('Thông tin tài khoản'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 4;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.black87),
                title: const Text('Lịch sử đơn hàng'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.black87),
                title: const Text('Cài đặt'),
                trailing: const Icon(Icons.chevron_right),
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
