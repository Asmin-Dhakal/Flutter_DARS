import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Load all customers
  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await CustomerService.getAllCustomers(getAll: true);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Search customers by name
  Future<void> searchCustomers(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (query.isEmpty) {
        _customers = await CustomerService.getAllCustomers(getAll: true);
      } else {
        _customers = await CustomerService.searchCustomers(query);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    loadCustomers();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Create a new customer and insert into the local list
  Future<Customer?> createCustomer({
    required String name,
    String? number,
    String? email,
    String? gender,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customer = await CustomerService.createCustomer(
        name: name,
        number: number,
        email: email,
        gender: gender,
      );

      // Prepend to local list for immediate UX
      _customers.insert(0, customer);
      _isLoading = false;
      notifyListeners();
      return customer;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
