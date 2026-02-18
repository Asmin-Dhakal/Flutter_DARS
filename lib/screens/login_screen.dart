import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    // Set system UI overlay style
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.space6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    _buildLogoSection(),

                    const SizedBox(height: AppTokens.space8),

                    // Login Card
                    _buildLoginCard(theme, authProvider),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo Container with subtle shadow
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(AppTokens.radiusXXLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusXXLarge),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Image.asset(
                'assets/images/dars_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppTokens.space5),

        // App Name
        Text(
          'DARS',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.gray800,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: AppTokens.space1),

        // Tagline
        Text(
          'Restaurant Management',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.gray600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(ThemeData theme, AuthProvider authProvider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
        side: BorderSide(color: AppColors.outline.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Welcome Back',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: AppTokens.space1),
              Text(
                'Sign in to continue',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: AppTokens.space5),

              // Error Message
              if (authProvider.error != null)
                _buildErrorMessage(authProvider.error!),

              // Email Field
              _buildEmailField(),
              const SizedBox(height: AppTokens.space4),

              // Password Field
              _buildPasswordField(),
              const SizedBox(height: AppTokens.space5),

              // Login Button
              _buildLoginButton(authProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space4),
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: AppTokens.space1),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !(_isLoading || context.read<AuthProvider>().isLoading),
          style: TextStyle(color: AppColors.gray800),
          decoration: InputDecoration(
            hintText: 'arun@admin.com',
            hintStyle: TextStyle(color: AppColors.gray500),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColors.gray600,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.gray200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space4,
              vertical: AppTokens.space3,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: AppTokens.space1),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          enabled: !(_isLoading || context.read<AuthProvider>().isLoading),
          style: TextStyle(color: AppColors.gray800),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: AppColors.gray500),
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: AppColors.gray600,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.gray600,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: AppColors.gray200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space4,
              vertical: AppTokens.space3,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 4) {
              return 'Password must be at least 4 characters';
            }
            return null;
          },
          onFieldSubmitted: (_) => _handleLogin(),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthProvider authProvider) {
    final isLoading = _isLoading || authProvider.isLoading;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.onPrimary,
                  ),
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Clear previous error
    context.read<AuthProvider>().clearError();

    // Unfocus keyboard
    _focusNode.unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        // Navigate with fade transition
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    }
  }
}
