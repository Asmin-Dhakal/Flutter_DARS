import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/bill.dart';
import '../../../models/payment_method.dart';
import '../../../providers/bill_provider.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/theme/app_theme.dart';

class PaymentModal extends StatefulWidget {
  final Bill bill;

  const PaymentModal({super.key, required this.bill});

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
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final isVerySmall = size.width < 320;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: size.height * 0.9,
        ),
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                isSmall ? 'Mark as Paid' : 'Mark Bill as Paid',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmall ? 20 : null,
                ),
              ),
              SizedBox(height: isSmall ? 6 : 8),
              Text(
                'Bill: ${widget.bill.billNumber}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: isSmall ? 13 : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmall ? 16 : 24),

              // Total Amount Display
              Container(
                padding: EdgeInsets.all(isSmall ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Rs. ${widget.bill.totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isSmall ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmall ? 16 : 24),

              // Payment Option Dropdown
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmall ? 13 : null,
                ),
              ),
              SizedBox(height: isSmall ? 6 : 8),

              if (provider.isLoading && paymentMethods.isEmpty)
                _buildSkeleton(isSmall)
              else if (provider.error != null)
                _buildErrorState(provider, isSmall)
              else
                _buildDropdown(paymentMethods, isSmall),

              // QR Code Display
              if (_showQrCode && _selectedMethod != null) ...[
                SizedBox(height: isSmall ? 16 : 24),
                _buildQrCode(isSmall),
              ],

              // Cash payment note
              if (_selectedMethod != null && _selectedMethod!.isCash) ...[
                SizedBox(height: isSmall ? 12 : 16),
                _buildCashNote(isSmall),
              ],

              SizedBox(height: isSmall ? 16 : 24),

              // Notes field
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 12 : 16,
                    vertical: isSmall ? 10 : 12,
                  ),
                  labelStyle: TextStyle(fontSize: isSmall ? 13 : null),
                ),
                maxLines: 2,
                style: TextStyle(fontSize: isSmall ? 13 : 14),
              ),

              SizedBox(height: isSmall ? 16 : 24),

              // Action Buttons
              _buildButtons(provider, isSmall, isVerySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isSmall) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBox(width: double.infinity, height: isSmall ? 14 : 16),
          SizedBox(height: isSmall ? 6 : AppTokens.space2),
          SkeletonBox(width: double.infinity, height: isSmall ? 14 : 16),
        ],
      ),
    );
  }

  Widget _buildErrorState(BillProvider provider, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      margin: EdgeInsets.only(bottom: isSmall ? 12 : 16),
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
                size: isSmall ? 18 : 20,
              ),
              SizedBox(width: isSmall ? 6 : 8),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: isSmall ? 13 : null,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 3 : 4),
          Text(
            provider.error!,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: isSmall ? 12 : 13,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          TextButton(
            onPressed: () => provider.loadPaymentMethods(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(List<PaymentMethod> paymentMethods, bool isSmall) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedMethodId,
          hint: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
            child: Text(
              'Select method',
              style: TextStyle(
                fontSize: isSmall ? 13 : 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
          style: TextStyle(fontSize: isSmall ? 13 : 14, color: Colors.black87),
          // FIXED: Use selectedItemBuilder for better control
          selectedItemBuilder: (context) {
            return paymentMethods.map((method) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  method.displayName,
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              );
            }).toList();
          },
          items: paymentMethods.map((method) {
            return DropdownMenuItem<String>(
              value: method.id,
              // FIXED: Use Container with constraints for proper width
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  method.displayName,
                  style: TextStyle(fontSize: isSmall ? 13 : 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
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
    );
  }

  Widget _buildQrCode(bool isSmall) {
    final qrSize = isSmall ? 150.0 : 200.0;

    if (_selectedMethod?.imageUrl != null) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _selectedMethod!.imageUrl!,
              height: qrSize,
              width: qrSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildQrPlaceholder(qrSize);
              },
            ),
          ),
        ),
      );
    }

    return Center(child: _buildQrPlaceholder(qrSize));
  }

  Widget _buildQrPlaceholder(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code, size: size * 0.3, color: Colors.grey[400]),
          SizedBox(height: size * 0.04),
          Text(
            'No QR Available',
            style: TextStyle(color: Colors.grey[600], fontSize: size * 0.06),
          ),
        ],
      ),
    );
  }

  Widget _buildCashNote(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 12),
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
            size: isSmall ? 18 : 20,
          ),
          SizedBox(width: isSmall ? 6 : 8),
          Expanded(
            child: Text(
              'Collect Rs. ${widget.bill.totalAmount.toStringAsFixed(0)} in cash',
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: isSmall ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BillProvider provider, bool isSmall, bool isVerySmall) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isSmall ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: isSmall ? 13 : 14),
            ),
          ),
        ),
        SizedBox(width: isSmall ? 8 : 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _selectedMethodId == null || provider.isLoading
                ? null
                : () => _confirmPayment(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a237e),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isSmall ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[400],
              minimumSize: Size.zero,
            ),
            child: provider.isLoading
                ? SizedBox(
                    height: isSmall ? 16 : 20,
                    width: isSmall ? 16 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isVerySmall ? 'Confirm' : 'Confirm Payment',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmall ? 13 : 14,
                    ),
                  ),
          ),
        ),
      ],
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
          content: Text('Payment confirmed!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
