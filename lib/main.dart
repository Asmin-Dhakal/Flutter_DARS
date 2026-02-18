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
    // Also remove any trailing spaces
    baseUrl = baseUrl.trim();

    print('Base URL: $baseUrl'); // Debug

    final billService = BillService(baseUrl: baseUrl);

    return MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => billService),

        // Auth Provider first
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Other providers
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),

        // BillProvider with PaymentService that updates when auth changes
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
              print('PaymentService created with token'); // Debug
            } else {
              print('No token available'); // Debug
            }

            // Return new instance with updated payment service
            return BillProvider(
              billService: billService,
              paymentService: paymentService,
            );
          },
        ),
      ],
      child: MaterialApp(
        title: 'Restaurant POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
        home: const SplashScreen(),
      ),
    );
  }
}
