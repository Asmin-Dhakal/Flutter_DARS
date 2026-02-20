import 'dart:convert';

class JwtHelper {
  /// Decode JWT token payload without verification
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded);
    } catch (e) {
      return null;
    }
  }

  /// Check if token is expired
  static bool isTokenExpired(String token) {
    final payload = decodeToken(token);
    if (payload == null) return true;

    final exp = payload['exp'] as int?;
    if (exp == null) return true;

    // Convert exp (seconds) to milliseconds and compare with current time
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiryDate);
  }

  /// Get token expiry date
  static DateTime? getExpiryDate(String token) {
    final payload = decodeToken(token);
    if (payload == null) return null;

    final exp = payload['exp'] as int?;
    if (exp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }

  /// Get time until expiry
  static Duration? getTimeUntilExpiry(String token) {
    final expiryDate = getExpiryDate(token);
    if (expiryDate == null) return null;

    return expiryDate.difference(DateTime.now());
  }
}
