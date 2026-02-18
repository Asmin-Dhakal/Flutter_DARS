import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  User? _user;
  String? _token; // Add token field
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  String? get token => _token; // Add token getter
  bool get isAuthenticated => _isAuthenticated;

  /// Check if already logged in (for app startup)
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      _user = await AuthService.getUser();
      _token = await AuthService.getToken(); // Load token
      _isAuthenticated = true;
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
      _token = result.token; // Store token
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
    _token = null; // Clear token
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
