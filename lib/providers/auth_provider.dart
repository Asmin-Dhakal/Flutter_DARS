import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  User? _user;
  String? _token;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    // Listen for logout events from AuthService
    AuthService.addLogoutListener(_handleAutoLogout);
  }

  /// Handle auto-logout event
  void _handleAutoLogout() {
    _user = null;
    _token = null;
    _isAuthenticated = false;
    _error = 'Session expired. Please login again.';
    notifyListeners();
  }

  /// Check if already logged in (for app startup)
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    // This will also check token expiry and logout if expired
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      _user = await AuthService.getUser();
      _token = await AuthService.getToken();
      _isAuthenticated = true;
    } else {
      _user = null;
      _token = null;
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login method
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await AuthService.login(email, password);

    _isLoading = false;

    if (result.success) {
      _user = result.user;
      _token = result.token;
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      _isAuthenticated = false;
      _token = null;
      notifyListeners();
      return false;
    }
  }

  /// Logout method
  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Remove listener when provider is disposed
    AuthService.removeLogoutListener(_handleAutoLogout);
    super.dispose();
  }
}
