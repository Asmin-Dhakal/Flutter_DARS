import 'package:flutter/foundation.dart';
import '../models/bill.dart';
import '../models/paginated_response.dart';
import '../services/bill_service.dart';
import '../services/payment_service.dart';
import '../models/payment_method.dart';

class BillProvider extends ChangeNotifier {
  final BillService _billService;
  final PaymentService? _paymentService;

  BillProvider({
    required BillService billService,
    PaymentService? paymentService,
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

  // Pagination fields
  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  int _totalDocs = 0;
  int get totalDocs => _totalDocs;

  final int _limit = 10;
  int get limit => _limit;

  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPrevPage => _currentPage > 1;

  String? _currentPaymentStatus;
  String? get currentPaymentStatus => _currentPaymentStatus;

  Future<void> loadPaymentMethods() async {
    if (_paymentService == null) {
      _error = 'Payment service not initialized';
      notifyListeners();
      return;
    }

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

  void selectPaymentMethod(PaymentMethod? method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

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

      final index = _bills.indexWhere((b) => b.id == billId);
      if (index != -1) {
        await loadBillsFiltered(
          page: _currentPage,
          paymentStatus: _currentPaymentStatus,
        );
      }

      _isLoading = false;
      _selectedPaymentMethod = null;
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

  Future<void> loadBills() async {
    await loadBillsFiltered(page: 1);
  }

  // Updated to handle pagination properly
  Future<void> loadBillsFiltered({
    int page = 1,
    int limit = 10,
    String? paymentStatus,
  }) async {
    _isLoading = true;
    _error = null;
    _currentPage = page;
    _currentPaymentStatus = paymentStatus;
    notifyListeners();

    try {
      final PaginatedResponse<Bill> result = await _billService.getAllBills(
        page: page,
        limit: limit,
        paymentStatus: paymentStatus,
      );

      _bills = result.docs;
      _currentPage = result.page;
      _totalPages = result.totalPages;
      _totalDocs = result.totalDocs;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Pagination navigation methods
  Future<void> nextPage() async {
    if (hasNextPage) {
      await loadBillsFiltered(
        page: _currentPage + 1,
        limit: _limit,
        paymentStatus: _currentPaymentStatus,
      );
    }
  }

  Future<void> prevPage() async {
    if (hasPrevPage) {
      await loadBillsFiltered(
        page: _currentPage - 1,
        limit: _limit,
        paymentStatus: _currentPaymentStatus,
      );
    }
  }

  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages) {
      await loadBillsFiltered(
        page: page,
        limit: _limit,
        paymentStatus: _currentPaymentStatus,
      );
    }
  }

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

  void selectCustomer(UnbilledCustomer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  Future<Bill?> createBill({
    required String customerId,
    required List<Map<String, dynamic>> orderedItems,
    required String createdBy,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bill = await _billService.createBill(
        customerId: customerId,
        items: orderedItems,
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

  Future<bool> deleteBill(String id) async {
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
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

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
