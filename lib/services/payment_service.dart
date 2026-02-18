import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/payment_method.dart';

class PaymentService {
  final String baseUrl;
  String token;

  PaymentService({required this.baseUrl, required this.token});

  void updateToken(String newToken) {
    token = newToken;
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    // FIXED: Correct endpoint is /payment-options, not /cafe/payment-methods
    final url = '$baseUrl/payment-options';
    developer.log(
      'Fetching payment methods from: $url',
      name: 'PaymentService',
    );

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      developer.log(
        'Response status: ${response.statusCode}',
        name: 'PaymentService',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle the response format from your backend
        if (data is Map && data.containsKey('docs')) {
          final docs = data['docs'] as List<dynamic>;
          return docs.map((e) => PaymentMethod.fromJson(e)).toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error: $e',
        name: 'PaymentService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markBillAsPaid({
    required String billId,
    required String paymentMethodId,
    String? notes,
  }) async {
    // Keep the existing bill payment endpoint (this one was correct)
    final url = '$baseUrl/cafe/bills/$billId/pay';
    developer.log('Marking bill as paid: $url', name: 'PaymentService');

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paidOn': paymentMethodId,
          'notes': notes ?? 'Payment received',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to mark bill as paid: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error marking bill as paid: $e', name: 'PaymentService');
      rethrow;
    }
  }
}
