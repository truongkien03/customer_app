import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/providers/order_provider.dart';
import 'package:customer_app/providers/notification_provider.dart';
import 'package:customer_app/screens/auth/phone_input_screen.dart';
import 'package:customer_app/screens/auth/otp_verification_screen.dart';
import 'package:customer_app/screens/main_screen.dart';
import 'package:customer_app/screens/test/notification_test_screen.dart';
import 'package:customer_app/screens/test/order_detail_demo_screen.dart';
import 'package:customer_app/screens/test/order_list_test_screen.dart';
import 'package:customer_app/screens/order/order_detail_screen.dart';
import 'package:customer_app/services/navigation_service.dart';
import 'package:customer_app/services/fcm_service_v2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize FCM Service theo FCM v1 API documentation
  await FcmService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Customer App',
        navigatorKey: NavigationService.navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const PhoneInputScreen(isLogin: true),
          '/register': (context) => const PhoneInputScreen(isLogin: false),
          '/home': (context) => const MainScreen(),
          '/test-notifications': (context) => const NotificationTestScreen(),
          '/test-order-detail': (context) => const OrderDetailDemoScreen(),
          '/test-order-list': (context) => const OrderListTestScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/otp') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: args['phoneNumber'] as String,
                isLogin: args['isLogin'] as bool,
              ),
            );
          }
          if (settings.name == '/order-detail') {
            final orderId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: orderId),
            );
          }
          return null;
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Delay để hiển thị splash screen ít nhất 2 giây
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Debug token storage
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    print('Token from secure storage: $token');

    await authProvider.initAuthState();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      print('User is authenticated, navigating to home screen');
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      print('User is not authenticated, navigating to login screen');
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 24),
            Text(
              'Customer App',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
