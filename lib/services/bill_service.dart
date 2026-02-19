import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bill.dart';
import '../models/paginated_response.dart';
import 'auth_service.dart';

class BillService {
  final String baseUrl;

  BillService({required this.baseUrl});

  Future<Map<String, String>> get _headers async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get customers with unbilled orders
  Future<List<UnbilledCustomer>> getCustomersWithUnbilledOrders() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/cafe/orders/customers-with-unbilled'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => UnbilledCustomer.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load customers with unbilled orders: ${response.body}',
      );
    }
  }

  // Get all bills with optional filters - NOW RETURNS PAGINATED RESPONSE
  Future<PaginatedResponse<Bill>> getAllBills({
    int page = 1,
    int limit = 10,
    String? paymentStatus,
  }) async {
    final headers = await _headers;

    // Build query parameters
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (paymentStatus != null && paymentStatus != 'all') {
      queryParams['paymentStatus'] = paymentStatus;
    }

    final uri = Uri.parse(
      '$baseUrl/cafe/bills',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return PaginatedResponse<Bill>.fromJson(
        data,
        (json) => Bill.fromJson(json),
      );
    } else {
      throw Exception('Failed to load bills: ${response.body}');
    }
  }

  // Create bill
  Future<Bill> createBill({
    required String customerId,
    required List<Map<String, dynamic>> items,
    required String createdBy,
    String? notes,
  }) async {
    final headers = await _headers;
    final body = {
      'customer': customerId,
      'items': items,
      'createdBy': createdBy,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/cafe/bills'),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Bill.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create bill: ${response.body}');
    }
  }

  // Get bill by ID
  Future<Bill> getBillById(String id) async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/cafe/bills/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Bill.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load bill: ${response.body}');
    }
  }

  // Delete bill
  Future<void> deleteBill(String id) async {
    final headers = await _headers;
    final response = await http.delete(
      Uri.parse('$baseUrl/cafe/bills/$id'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete bill: ${response.body}');
    }
  }
}
