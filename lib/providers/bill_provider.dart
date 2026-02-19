import 'package:flutter/foundation.dart';
import '../models/bill.dart';
import '../services/bill_service.dart';
import '../services/payment_service.dart';
import '../models/payment_method.dart';

class BillProvider extends ChangeNotifier {
  final BillService _billService;
  final PaymentService? _paymentService;

  BillProvider({
    required BillService billService,
    PaymentService? paymentService, // Optional for backward compatibility
  }) : _billService = billService,
       _paymentService = paymentService;

  List<Bill> _bills = [];
  List<Bill> get bills => _bills;

  List<UnbilledCustomer> _unbilledCustomers = [];
  List<UnbilledCustomer> get unbilledCustomers => _unbilledCustomers;

  List<PaymentMethod> _paymentMethods = [];
  List<PaymentMethod> get paymentMethods => _paymentMethods;

  PaymentMethod? _selectedPaymentMethod;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  UnbilledCustomer? _selectedCustomer;
  UnbilledCustomer? get selectedCustomer => _selectedCustomer;

  Future<void> loadPaymentMethods() async {
    if (_paymentService == null) {
      _error = 'Payment service not initialized';
      notifyListeners();
      return;
    }

    // Check if token is empty
    if (_paymentService.token.isEmpty) {
      _error = 'Authentication token is missing. Please login again.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _paymentMethods = await _paymentService.getPaymentMethods();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Select payment method
  void selectPaymentMethod(PaymentMethod? method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  // Mark bill as paid
  Future<bool> markBillAsPaid({
    required String billId,
    required String paymentMethodId,
    String? notes,
  }) async {
    if (_paymentService == null) {
      _error = 'Payment service not initialized';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _paymentService.markBillAsPaid(
        billId: billId,
        paymentMethodId: paymentMethodId,
        notes: notes,
      );

      // Update the bill in the list with new status
      final index = _bills.indexWhere((b) => b.id == billId);
      if (index != -1) {
        // Reload bills to get updated status
        await loadBills();
      }

      _isLoading = false;
      _selectedPaymentMethod = null; // Reset selection
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load all bills
  Future<void> loadBills() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bills = await _billService.getAllBills();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load bills with optional filters (page, limit, paymentStatus)
  Future<void> loadBillsFiltered({
    int page = 1,
    int limit = 10,
    String? paymentStatus,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bills = await _billService.getAllBills(
        page: page,
        limit: limit,
        paymentStatus: paymentStatus,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load customers with unbilled orders
  Future<void> loadUnbilledCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _unbilledCustomers = await _billService.getCustomersWithUnbilledOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Select customer for bill creation
  void selectCustomer(UnbilledCustomer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  // Create bill - FIXED: changed 'items' to 'orderedItems' to match API
  Future<Bill?> createBill({
    required String customerId,
    required List<Map<String, dynamic>> orderedItems, // Changed from 'items'
    required String createdBy,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bill = await _billService.createBill(
        customerId: customerId,
        items: orderedItems, // Pass as orderedItems
        createdBy: createdBy,
        notes: notes,
      );
      _bills.insert(0, bill);
      _isLoading = false;
      notifyListeners();
      return bill;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Delete bill
  Future<bool> deleteBill(String id) async {
    // Remove from list immediately for UI update
    _bills.removeWhere((bill) => bill.id == id);
    notifyListeners();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _billService.deleteBill(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // If failed, reload to restore
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Set bills directly (used by filtered loading)
  void setBills(List<Bill> bills) {
    _bills = bills;
    _isLoading = false;
    notifyListeners();
  }

  void clearSelectedCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }
}
