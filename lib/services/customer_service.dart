import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import 'auth_service.dart';

class CustomerService {
  static const String baseUrl = 'https://dars-resturant-management.vercel.app';

  /// Get all customers with optional filters
  static Future<List<Customer>> getAllCustomers({
    String? searchByName,
    int? page,
    int? limit,
    bool? getAll,
    String? gender,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (searchByName != null && searchByName.isNotEmpty) {
        queryParams['searchByName'] = searchByName;
      }
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (getAll != null) queryParams['getAll'] = getAll.toString();
      if (gender != null) queryParams['gender'] = gender;

      // Build URL with query params
      final uri = Uri.parse(
        '$baseUrl/customers',
      ).replace(queryParameters: queryParams);

      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('DEBUG: Fetching customers from $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Customers response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        // Handle different response formats
        List<dynamic> customersJson;

        if (data is List) {
          // Direct array: [{...}, {...}]
          customersJson = data;
        } else if (data is Map) {
          // Wrapped object - check common keys
          if (data.containsKey('docs')) {
            customersJson = data['docs'] as List;
          } else if (data.containsKey('data')) {
            customersJson = data['data'] as List;
          } else if (data.containsKey('customers')) {
            customersJson = data['customers'] as List;
          } else if (data.containsKey('results')) {
            customersJson = data['results'] as List;
          } else {
            // Try to find any list in the object
            for (var value in data.values) {
              if (value is List) {
                customersJson = value;
                break;
              }
            }
            // If no list found, throw error
            throw Exception(
              'Unexpected response format. Keys: ${data.keys.toList()}',
            );
          }
        } else {
          throw Exception('Unexpected response type: ${data.runtimeType}');
        }

        return customersJson.map((json) => Customer.fromJson(json)).toList();
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['message'] ?? error['error'] ?? 'Failed to fetch customers';
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error fetching customers: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Search customers by name (convenience method)
  static Future<List<Customer>> searchCustomers(String name) async {
    return getAllCustomers(searchByName: name, getAll: true);
  }

  /// Create a new customer
  static Future<Customer> createCustomer({
    required String name,
    String? number,
    String? email,
    String? gender,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/customers');

      final token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final body = {
        'name': name,
        if (number != null && number.isNotEmpty) 'number': number,
        if (email != null && email.isNotEmpty) 'email': email,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // If API wraps the created object, try common keys
        if (data is Map && data.containsKey('customer')) {
          final customerObj = data['customer'];
          if (customerObj is Map) {
            return Customer.fromJson(Map<String, dynamic>.from(customerObj));
          }
        }

        if (data is Map &&
            (data.containsKey('data') || data.containsKey('docs'))) {
          final payload = data['data'] ?? data['docs'];
          if (payload is Map) {
            return Customer.fromJson(Map<String, dynamic>.from(payload));
          }
        }

        if (data is Map) {
          return Customer.fromJson(Map<String, dynamic>.from(data));
        }

        throw Exception('Unexpected response when creating customer');
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['message'] ?? error['error'] ?? 'Failed to create customer';
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
