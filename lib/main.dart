import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Clean baseUrl (remove trailing space and slash)
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
        title: 'DARS',
        debugShowCheckedModeBanner: false,
        // FIXED: Use the new theme
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
