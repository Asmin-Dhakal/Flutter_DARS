import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Change this to your backend URL
  // Your deployed backend URL - USE HTTPS!
  static const String baseUrl = 'https://dars-resturant-management.vercel.app';

  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';

  /// Login with email and password
  static Future<LoginResult> login(String email, String password) async {
    try {
      print('DEBUG: Logging in to $baseUrl/login'); // Debug print

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Explicitly request JSON
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('DEBUG: Response status: ${response.statusCode}'); // Debug print
      print('DEBUG: Response body: ${response.body}'); // Debug print

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save token and user data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['access_token']);
        await prefs.setString(_userKey, jsonEncode(data['admin']));

        return LoginResult.success(
          token: data['access_token'],
          user: User.fromJson(data['admin']),
        );
      } else {
        // Handle non-200 responses
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['message'] ?? 'Login failed';
        } catch (e) {
          // If response is not JSON (HTML error page)
          errorMessage = 'Server error: ${response.statusCode}';
        }
        return LoginResult.error(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error: $e'); // Debug print
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

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout - clear stored data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
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
