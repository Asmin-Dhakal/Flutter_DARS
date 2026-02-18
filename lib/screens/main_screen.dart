import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import 'orders/orders_tab.dart';
import 'bills/bills_tab.dart';
import 'games_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<AnimationController> _animationControllers;

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
    _animationControllers = List.generate(
      _tabs.length,
      (index) =>
          AnimationController(vsync: this, duration: AppTokens.durationFast),
    );
    _animationControllers[_currentIndex].value = 1.0;
  }

  @override
  void dispose() {
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
