import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  List<Order> get orders => _orders;

  // For backward compatibility with OrderStats and OrderList
  List<Order> get filteredOrders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalDocs = 0;
  final int _limit = 10;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalDocs => _totalDocs;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPrevPage => _currentPage > 1;

  // Filters - Default to unbilled and partially billed
  String _billingStatusFilter = 'unbilledAndPartiallyBilled';
  String get billingStatusFilter => _billingStatusFilter;

  final Map<String, String> _billingStatusOptions = {
    'unbilledAndPartiallyBilled': 'Unbilled & Partial',
    'unbilled': 'Unbilled Only',
    'partiallyBilled': 'Partially Billed',
    'fullyBilled': 'Fully Billed',
    'all': 'All',
  };

  Map<String, String> get billingStatusOptions => _billingStatusOptions;

  // For backward compatibility
  String get statusFilter => 'All';

  /// Add a new order to the list (for real-time sync from Firestore)
  void addOrder(Order order) {
    // Check if order already exists
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      // Update existing order
      _orders[index] = order;
    } else {
      // Add new order at the beginning
      _orders.insert(0, order);
    }
    notifyListeners();
  }

  /// Update an existing order (for real-time sync from Firestore)
  void updateOrder(Order order) {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      _orders[index] = order;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadOrders({int page = 1, String? billingStatus}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = billingStatus ?? _billingStatusFilter;

      final response = await OrderService.getOrders(
        page: page,
        limit: _limit,
        billingStatus: status == 'all' ? null : status,
      );

      final List<dynamic> docs = response['docs'] ?? [];
      _orders = docs.map((json) => Order.fromJson(json)).toList();

      // Update pagination
      _currentPage = response['page'] ?? 1;
      _totalPages = response['totalPages'] ?? 1;
      _totalDocs = response['totalDocs'] ?? 0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // For backward compatibility
  void setStatusFilter(String status) {
    // No-op or implement if needed
    notifyListeners();
  }

  void setBillingStatusFilter(String status) {
    _billingStatusFilter = status;
    notifyListeners();
    loadOrders();
  }

  // For backward compatibility
  void setBillingFilter(String billing) {
    setBillingStatusFilter(billing);
  }

  /// Remove an order from the list immediately (for UI updates)
  void removeOrder(String orderId) {
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  Future<void> nextPage() async {
    if (hasNextPage) {
      await loadOrders(page: _currentPage + 1);
    }
  }

  Future<void> prevPage() async {
    if (hasPrevPage) {
      await loadOrders(page: _currentPage - 1);
    }
  }

  Future<void> refresh() async {
    await loadOrders(page: 1);
  }
}
