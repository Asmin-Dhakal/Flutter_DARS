import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/jwt_helpers.dart';

class AuthService {
  static const String baseUrl = 'https://dars-resturant-management.vercel.app';
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';

  /// Stream controller for logout events (for global logout notification)
  static final List<VoidCallback> _logoutListeners = [];

  /// Add logout listener
  static void addLogoutListener(VoidCallback listener) {
    _logoutListeners.add(listener);
  }

  /// Remove logout listener
  static void removeLogoutListener(VoidCallback listener) {
    _logoutListeners.remove(listener);
  }

  /// Notify all listeners to logout
  static void notifyLogout() {
    for (final listener in _logoutListeners) {
      listener();
    }
  }

  /// Login with email and password
  static Future<LoginResult> login(String email, String password) async {
    try {
      print('DEBUG: Logging in to $baseUrl/login');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Validate token expiry immediately
        final token = data['access_token'] as String?;
        if (token == null || JwtHelper.isTokenExpired(token)) {
          return LoginResult.error('Invalid or expired token received');
        }

        // Save token and user data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, jsonEncode(data['admin']));

        return LoginResult.success(
          token: token,
          user: User.fromJson(data['admin']),
        );
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['message'] ?? 'Login failed';
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        return LoginResult.error(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error: $e');
      return LoginResult.error('Network error: $e');
    }
  }

  /// Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get stored user
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return User.fromJson(jsonDecode(userStr));
    }
    return null;
  }

  /// Check if user is logged in AND token is valid
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    // Check if token is expired
    if (JwtHelper.isTokenExpired(token)) {
      // Auto logout if expired
      await logout();
      return false;
    }
    return true;
  }

  /// Check if token will expire soon (within 5 minutes)
  static Future<bool> isTokenExpiringSoon() async {
    final token = await getToken();
    if (token == null) return true;

    final timeUntilExpiry = JwtHelper.getTimeUntilExpiry(token);
    if (timeUntilExpiry == null) return true;

    // Consider "soon" as less than 5 minutes
    return timeUntilExpiry.inMinutes < 5;
  }

  /// Logout - clear stored data and notify listeners
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    // Notify all listeners to redirect to login
    notifyLogout();
  }

  /// Validate token and logout if invalid
  static Future<bool> validateTokenOrLogout() async {
    final isValid = await isLoggedIn();
    if (!isValid) {
      notifyLogout();
      return false;
    }
    return true;
  }
}

/// User model from your backend
class User {
  final String id;
  final String name;
  final String email;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }
}

/// Login result wrapper
class LoginResult {
  final bool success;
  final String? token;
  final User? user;
  final String? error;

  LoginResult._({required this.success, this.token, this.user, this.error});

  factory LoginResult.success({required String token, required User user}) {
    return LoginResult._(success: true, token: token, user: user);
  }

  factory LoginResult.error(String message) {
    return LoginResult._(success: false, error: message);
  }
}

typedef VoidCallback = void Function();
