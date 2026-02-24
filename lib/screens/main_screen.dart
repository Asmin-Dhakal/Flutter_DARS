import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/theme/app_theme.dart';
import 'orders/orders_tab.dart';
import 'orders/order_details_page.dart';
import 'bills/bills_tab.dart';
import 'games_tab.dart';
import 'package:restaurant_order_app/services/notification_service.dart';
import 'package:restaurant_order_app/services/firestore_order_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<AnimationController> _animationControllers;

  final NotificationServices _notificationServices = NotificationServices();
  final FirestoreOrderService _firestoreOrderService = FirestoreOrderService();

  final List<Widget> _tabs = [
    const OrdersTab(),
    const BillsTab(),
    const GamesTab(),
  ];

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Orders',
    ),
    const NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Bills',
    ),
    const NavigationDestination(
      icon: Icon(Icons.sports_esports_outlined),
      selectedIcon: Icon(Icons.sports_esports),
      label: 'Games',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _notificationServices.initLocalNotifications(context, RemoteMessage());
    _notificationServices.requestNotificationPersmissions();
    _notificationServices.firebaseInit();
    _notificationServices.handleBackgroundMessage();
    _notificationServices.isTokenRefresh();

    // Get device token and save to Firestore
    _notificationServices.getDeviceToken().then(
      (value) => {debugPrint('✅ Device Token obtained and saved to Firestore')},
    );

    // Start listening for order changes in Firestore
    _firestoreOrderService.startListening();

    // Register callback for notification taps
    NotificationServices.onNotificationTapped = _handleNotificationTap;

    // Handle notification tap to navigate to order details
    _setupNotificationTapHandler();

    _animationControllers = List.generate(
      _tabs.length,
      (index) =>
          AnimationController(vsync: this, duration: AppTokens.durationFast),
    );
    _animationControllers[_currentIndex].value = 1.0;
  }

  /// Setup handler for when user taps on a notification
  void _setupNotificationTapHandler() {
    // Handle notification tap when app is launched from notification
    _notificationServices.flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails()
        .then((details) {
          if (details?.didNotificationLaunchApp ?? false) {
            final payload = details?.notificationResponse?.payload;
            if (payload != null && payload.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _handleNotificationTap(payload);
              });
            }
          }
        });
  }

  /// Handle notification tap from either launch details or callback
  void _handleNotificationTap(String payload) {
    debugPrint('📲 Handling notification tap with payload: $payload');
    _navigateToOrderDetails(payload);
  }

  /// Navigate to order details page when notification is tapped
  void _navigateToOrderDetails(String payload) {
    // Payload format: "orderId|orderNumber"
    final parts = payload.split('|');
    if (parts.length == 2) {
      final orderId = parts[0];
      final orderNumber = parts[1];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OrderDetailsPage(orderId: orderId, orderNumber: orderNumber),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Stop listening for order changes
    _firestoreOrderService.stopListening();

    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;

    // Animate out current tab
    _animationControllers[_currentIndex].reverse();

    setState(() {
      _currentIndex = index;
    });

    // Animate in new tab
    _animationControllers[_currentIndex].forward();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.gray100,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: AnimatedSwitcher(
        duration: AppTokens.durationNormal,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: AppColors.gray100,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: AppTokens.durationNormal,
        destinations: _destinations.map((destination) {
          return NavigationDestination(
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
            label: destination.label,
          );
        }).toList(),
      ),
    );
  }
}
