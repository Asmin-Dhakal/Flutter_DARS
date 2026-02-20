import 'dart:convert';
import '../models/bill.dart';
import '../models/paginated_response.dart';
import 'authenticated_http_client.dart';

class BillService {
  final String baseUrl;
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  BillService({required this.baseUrl});

  // Get customers with unbilled orders
  Future<List<UnbilledCustomer>> getCustomersWithUnbilledOrders() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/cafe/orders/customers-with-unbilled'),
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

  // Get all bills with optional filters
  Future<PaginatedResponse<Bill>> getAllBills({
    int page = 1,
    int limit = 10,
    String? paymentStatus,
  }) async {
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

    final response = await _httpClient.get(uri);

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
    final body = {
      'customer': customerId,
      'items': items,
      'createdBy': createdBy,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/cafe/bills'),
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
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/cafe/bills/$id'),
    );

    if (response.statusCode == 200) {
      return Bill.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load bill: ${response.body}');
    }
  }

  // Delete bill
  Future<void> deleteBill(String id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/cafe/bills/$id'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete bill: ${response.body}');
    }
  }
}
