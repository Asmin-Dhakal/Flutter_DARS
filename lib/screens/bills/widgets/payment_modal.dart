import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/bill.dart';
import '../../../models/payment_method.dart';
import '../../../providers/bill_provider.dart';

class PaymentModal extends StatefulWidget {
  final Bill bill;

  const PaymentModal({Key? key, required this.bill}) : super(key: key);

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String? _selectedMethodId;
  bool _showQrCode = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadPaymentMethods();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  PaymentMethod? get _selectedMethod {
    final provider = context.read<BillProvider>();
    if (_selectedMethodId == null) return null;
    try {
      return provider.paymentMethods.firstWhere(
        (m) => m.id == _selectedMethodId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final paymentMethods = provider.paymentMethods;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Mark Bill as Paid',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirm payment for bill ${widget.bill.billNumber}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Total Amount Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    Text(
                      'Rs. ${widget.bill.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Option Dropdown
              Text(
                'Payment Option',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              if (provider.isLoading && paymentMethods.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (provider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Error',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => provider.loadPaymentMethods(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedMethodId,
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Select payment option'),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      items: paymentMethods.map((method) {
                        return DropdownMenuItem<String>(
                          value: method.id,
                          child: Text(method.displayName),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedMethodId = value;
                          final method = _selectedMethod;
                          _showQrCode = method != null && !method.isCash;
                        });
                      },
                    ),
                  ),
                ),

              // QR Code Display (for e-sewa)
              if (_showQrCode && _selectedMethod != null) ...[
                const SizedBox(height: 24),
                if (_selectedMethod!.imageUrl != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _selectedMethod!.imageUrl!,
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  width: 200,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.qr_code_2,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No QR Code Available',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      final method = _selectedMethod;
                      if (method != null) {
                        _showPaymentDetails(context, method);
                      }
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Show details of payment'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                ),
              ],

              // Cash payment note
              if (_selectedMethod != null && _selectedMethod!.isCash) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Collect Rs. ${widget.bill.totalAmount.toStringAsFixed(0)} in cash from customer',
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Notes field (optional)
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add payment notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedMethodId == null || provider.isLoading
                          ? null
                          : () => _confirmPayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1a237e),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Confirm Payment',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(method.paymentName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details: ${method.paymentDetails}'),
            const SizedBox(height: 8),
            Text('Admin: ${method.admin.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment(BuildContext context) async {
    if (_selectedMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.bill.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Bill ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<BillProvider>();

    final success = await provider.markBillAsPaid(
      billId: widget.bill.id!,
      paymentMethodId: _selectedMethodId!,
      notes: _notesController.text.isEmpty
          ? 'Payment received'
          : _notesController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
