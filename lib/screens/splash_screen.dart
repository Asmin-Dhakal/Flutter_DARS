import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'main_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthAndNavigate();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Optimized for 60fps
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Minimum splash duration for branding (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    // Navigate with fade transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return authProvider.isAuthenticated
              ? const MainScreen()
              : const LoginScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lock orientation to portrait for splash
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusXXLarge,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gray900.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: AppColors.gray900.withOpacity(0.04),
                              blurRadius: 60,
                              offset: const Offset(0, 20),
                              spreadRadius: -10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusXXLarge,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/images/dars_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTokens.space8),

                      // App Name
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Column(
                          children: [
                            Text(
                              'DARS',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gray800,
                                    letterSpacing: 4,
                                  ),
                            ),
                            const SizedBox(height: AppTokens.space2),
                            Text(
                              'Restaurant Management',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.gray600,
                                    letterSpacing: 1,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTokens.space12),

                      // Loading Indicator
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.gray600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTokens.space6),

                      // Version
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Text(
                          'v1.0.0',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.gray500),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
