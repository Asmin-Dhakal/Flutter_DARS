import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/order.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/bill_provider.dart';
import 'services/auth_service.dart';
import 'services/bill_service.dart';
import 'services/payment_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart'; // ADD THIS
import 'screens/orders/edit_order/edit_order_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Listen for logout events to navigate to login screen
    AuthService.addLogoutListener(_navigateToLogin);
  }

  @override
  void dispose() {
    AuthService.removeLogoutListener(_navigateToLogin);
    super.dispose();
  }

  /// Navigate to login screen when logout is triggered
  void _navigateToLogin() {
    // Use post-frame callback to ensure we're not in the middle of a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey.currentState != null) {
        _navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String baseUrl = AuthService.baseUrl.trim();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    baseUrl = baseUrl.trim();

    print('Base URL: $baseUrl');

    final billService = BillService(baseUrl: baseUrl);

    return MultiProvider(
      providers: [
        Provider(create: (_) => billService),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProxyProvider<AuthProvider, BillProvider>(
          create: (context) =>
              BillProvider(billService: billService, paymentService: null),
          update: (context, authProvider, previousBillProvider) {
            PaymentService? paymentService;
            if (authProvider.token != null && authProvider.token!.isNotEmpty) {
              paymentService = PaymentService(
                baseUrl: baseUrl,
                token: authProvider.token!,
              );
            }
            return BillProvider(
              billService: billService,
              paymentService: paymentService,
            );
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey, // Add navigator key for global navigation
        title: 'DARS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        routes: {
          '/edit-order': (context) {
            final order = ModalRoute.of(context)!.settings.arguments as Order;
            return EditOrderScreen(order: order);
          },
        },
      ),
    );
  }
}
