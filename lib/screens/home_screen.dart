import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/widgets/custom_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                final success = await authProvider.logout();

                if (success && context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                } else if (context.mounted) {
                  Fluttertoast.showToast(
                    msg: 'Failed to logout',
                    backgroundColor: Colors.red,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${authProvider.currentUser?.name ?? 'User'}!',
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Phone Number: ${authProvider.currentUser?.phoneNumber ?? 'Not available'}',
                style: const TextStyle(
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Email: ${authProvider.currentUser?.email ?? 'Not available'}',
                style: const TextStyle(
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 32.0),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Features',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.0),
                      Text('• Feature 1'),
                      Text('• Feature 2'),
                      Text('• Feature 3'),
                      Text('• Feature 4'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (authProvider.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              if (!authProvider.isLoading)
                CustomButton(
                  text: 'Refresh Profile',
                  onPressed: () async {
                    await authProvider.initAuthState();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
