import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// HTTP Client that automatically handles authentication and token expiry
class AuthenticatedHttpClient {
  final http.Client _client = http.Client();

  /// GET request with auth header and auto-logout on 401
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final requestHeaders = await _buildHeaders(headers);
    final response = await _client.get(url, headers: requestHeaders);
    await _handleResponse(response);
    return response;
  }

  /// POST request with auth header and auto-logout on 401
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final requestHeaders = await _buildHeaders(headers);
    final response = await _client.post(
      url,
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );
    await _handleResponse(response);
    return response;
  }

  /// PUT request with auth header and auto-logout on 401
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final requestHeaders = await _buildHeaders(headers);
    final response = await _client.put(
      url,
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );
    await _handleResponse(response);
    return response;
  }

  /// PATCH request with auth header and auto-logout on 401
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final requestHeaders = await _buildHeaders(headers);
    final response = await _client.patch(
      url,
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );
    await _handleResponse(response);
    return response;
  }

  /// DELETE request with auth header and auto-logout on 401
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final requestHeaders = await _buildHeaders(headers);
    final response = await _client.delete(
      url,
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );
    await _handleResponse(response);
    return response;
  }

  /// Build headers with authorization token
  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? extraHeaders,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth token if available
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      // Check if token is expired before making request
      if (AuthService.validateTokenOrLogout() == false) {
        throw UnauthorizedException('Token expired');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    // Merge with extra headers
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// Handle response and trigger logout on 401
  Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      print('DEBUG: Received 401 Unauthorized - Logging out');
      await AuthService.logout();
      throw UnauthorizedException('Session expired. Please login again.');
    }
  }

  void close() {
    _client.close();
  }
}

/// Custom exception for unauthorized requests
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => message;
}
