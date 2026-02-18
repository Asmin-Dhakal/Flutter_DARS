import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class OrderService {
  static const String baseUrl = 'https://dars-resturant-management.vercel.app';

  /// Create new order
  static Future<Order> createOrder({
    required String customerId,
    required List<Map<String, dynamic>> orderedItems,
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get current user ID from token or stored user
      final user = await AuthService.getUser();
      final createdBy = user?.id;

      final body = {
        'customer': customerId,
        'orderedItems': orderedItems,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'createdBy': ?createdBy,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/cafe/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data);
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['message'] ?? error['error'] ?? 'Failed to create order';
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get orders with pagination and billing status filter
  static Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
    String? billingStatus,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (billingStatus != null && billingStatus.isNotEmpty) {
        queryParams['billingStatus'] = billingStatus;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse(
        '$baseUrl/cafe/orders',
      ).replace(queryParameters: queryParams);

      final token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get all orders with optional filters
  static Future<List<Order>> getAllOrders({
    String? status,
    String? billingStatus,
    int? page,
    int? limit,
    bool? getAll,
    String? customer,
    String? createdBy,
    String? receivedBy,
    String? date,
    String? dateRange,
    String? orderNumber,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (billingStatus != null) queryParams['billingStatus'] = billingStatus;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (getAll != null) queryParams['getAll'] = getAll.toString();
      if (customer != null) queryParams['customer'] = customer;
      if (createdBy != null) queryParams['createdBy'] = createdBy;
      if (receivedBy != null) queryParams['receivedBy'] = receivedBy;
      if (date != null) queryParams['date'] = date;
      if (dateRange != null) queryParams['dateRange'] = dateRange;
      if (orderNumber != null) queryParams['orderNumber'] = orderNumber;

      final uri = Uri.parse(
        '$baseUrl/cafe/orders',
      ).replace(queryParameters: queryParams);

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        // ignore: unused_local_variable
        List<dynamic> ordersJson;

        if (data is List) {
          ordersJson = data;
        } else if (data is Map) {
          if (data.containsKey('docs')) {
            ordersJson = data['docs'] as List;
          } else if (data.containsKey('data')) {
            ordersJson = data['data'] as List;
          } else if (data.containsKey('orders')) {
            ordersJson = data['orders'] as List;
          } else {
            for (var value in data.values) {
              if (value is List) {
                ordersJson = value;
                break;
              }
            }
            throw Exception(
              'Unexpected response format. Keys: ${data.keys.toList()}',
            );
          }
        } else {
          throw Exception('Unexpected response type: ${data.runtimeType}');
        }

        return await compute(_parseOrders, data);
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['message'] ?? error['error'] ?? 'Failed to fetch orders';
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Static method for compute
  static List<Order> _parseOrders(dynamic data) {
    List<dynamic> ordersJson;

    if (data is List) {
      ordersJson = data;
    } else if (data is Map && data.containsKey('docs')) {
      ordersJson = data['docs'] as List;
    } else {
      ordersJson = [];
    }

    return ordersJson
        .map((json) => Order.fromJson(json))
        .where((order) => order.isDeleted != true)
        .toList();
  }

  /// Update existing order
  static Future<Order> updateOrder({
    required String orderId,
    required String customerId,
    required List<Map<String, dynamic>> orderedItems,
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = {
        'customer': customerId,
        'orderedItems': orderedItems,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/cafe/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data);
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['message'] ?? error['error'] ?? 'Failed to update order';
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Update order status (receive, cancel, etc.)
  static Future<Order> updateOrderStatus({
    required String orderId,
    required String status,
    String? receivedBy,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get current user ID for receivedBy
      final user = await AuthService.getUser();
      final userId = user?.id;

      final body = {
        'status': status,
        'receivedBy': ?receivedBy,
        if (userId != null && status == 'received') 'receivedBy': userId,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/cafe/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data);
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['message'] ?? error['error'] ?? 'Failed to update status';
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Delete order (soft delete)
  static Future<void> deleteOrder(String orderId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/cafe/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return; // Success
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['message'] ?? error['error'] ?? 'Failed to delete order';
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
