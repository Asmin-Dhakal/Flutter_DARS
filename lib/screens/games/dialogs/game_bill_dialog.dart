import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_snackbar.dart';
import '../../../models/game_session.dart';
import '../../../models/payment_method.dart';
import '../../../providers/bill_provider.dart';
import '../../../services/game_service.dart';
import '../../../services/auth_service.dart';

class GameBillDialog extends StatefulWidget {
  final String gameType; // 'table-tennis' or 'snooker-pool'
  final GameSession session;
  final double pricePerUnit; // Price per minute (tennis) or per game (snooker)
  final int? gameCount; // Number of games played (for snooker)

  const GameBillDialog({
    super.key,
    required this.gameType,
    required this.session,
    required this.pricePerUnit,
    this.gameCount,
  });

  @override
  State<GameBillDialog> createState() => _GameBillDialogState();
}

class _GameBillDialogState extends State<GameBillDialog> {
  late final TextEditingController _discountController;
  late final TextEditingController _notesController;

  bool _isLoading = false;
  String? _userId;
  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedPaymentMethod;
  bool _showQrCode = false;
  double _discount = 0;
  double? _totalAmount;
  double? _finalAmount;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController();
    _notesController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadData() async {
    // Get user ID
    final user = await AuthService.getUser();
    if (mounted && user != null) {
      setState(() {
        _userId = user.id;
      });
    }

    // Load payment methods from BillProvider
    if (mounted) {
      context.read<BillProvider>().loadPaymentMethods();
    }

    // Calculate total amount based on game type
    _calculateTotal();
  }

  void _calculateTotal() {
    double total = 0;

    if (widget.gameType == 'table-tennis') {
      // For tennis: calculate duration from startTime to now
      final now = DateTime.now();
      final duration = now.difference(widget.session.startTime);
      final minutes = duration.inMinutes;
      total = minutes * widget.pricePerUnit;
    } else if (widget.gameType == 'snooker-pool') {
      // For snooker: use actual gameCount or default to 1
      final games = widget.gameCount ?? 1;
      total = games * widget.pricePerUnit;
    }

    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final finalAmount = (total - discount).clamp(0.0, double.infinity);

    setState(() {
      _totalAmount = total;
      _discount = discount;
      _finalAmount = finalAmount;
    });
  }

  void _onDiscountChanged(String value) {
    _calculateTotal();
  }

  Future<void> _createAndPayBill(bool shouldPay) async {
    if (_userId == null) {
      ModernSnackBar.error(context, 'Not authenticated');
      return;
    }

    if (shouldPay && _selectedPaymentMethod == null) {
      ModernSnackBar.error(context, 'Please select a payment method');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First, stop the session if it's still active
      if (widget.session.isActive) {
        try {
          if (widget.gameType == 'table-tennis') {
            await GameService.stopTennisSession(widget.session.id);
          } else if (widget.gameType == 'snooker-pool') {
            await GameService.stopSnookerSession(widget.session.id);
          }
        } catch (e) {
          if (mounted) {
            ModernSnackBar.error(
              context,
              'Warning: Could not stop session: $e',
            );
          }
        }
      }

      // Create bill
      final bill = widget.gameType == 'table-tennis'
          ? await GameService.createTennisBill(
              sessionId: widget.session.id,
              createdBy: _userId!,
              discount: _discount,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            )
          : await GameService.createSnookerBill(
              sessionId: widget.session.id,
              createdBy: _userId!,
              gameCount: widget.gameCount ?? 1,
              discount: _discount,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );

      if (!mounted) return;

      // If paying now, mark as paid
      if (shouldPay) {
        await GameService.markGameBillAsPaid(
          bill.id,
          paymentMethodId: _selectedPaymentMethod!.id,
        );

        if (mounted) {
          ModernSnackBar.success(context, 'Bill paid successfully');
        }
      } else {
        if (mounted) {
          ModernSnackBar.success(context, 'Bill created');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Error creating bill';
        if (e.toString().contains('snooker')) {
          errorMsg = 'Error: Snooker bill creation failed - ${e.toString()}';
        } else if (e.toString().contains('tennis')) {
          errorMsg = 'Error: Tennis bill creation failed - ${e.toString()}';
        } else {
          errorMsg = 'Error: ${e.toString()}';
        }
        ModernSnackBar.error(context, errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTennis = widget.gameType == 'table-tennis';
    final billNumber =
        '${isTennis ? 'TT' : 'SP'}-${DateTime.now().toString().split(' ')[0].replaceAll('-', '')}-XXX';
    final billProvider = context.watch<BillProvider>();
    final paymentMethods = billProvider.paymentMethods;

    // Calculate live duration for tennis
    final now = DateTime.now();
    final duration = now.difference(widget.session.startTime);
    final durationMinutes = duration.inMinutes;

    // Update local payment methods from provider
    if (paymentMethods.isNotEmpty && _paymentMethods.isEmpty) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _paymentMethods = paymentMethods;
            if (_selectedPaymentMethod == null && paymentMethods.isNotEmpty) {
              _selectedPaymentMethod = paymentMethods.first;
            }
          });
        }
      });
    }

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTennis ? Icons.sports_tennis_rounded : Icons.casino_rounded,
                size: 24,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppTokens.space2),
              const Expanded(child: Text('Create Bill')),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            '${isTennis ? 'Table Tennis' : 'Snooker & Pool'} - Table ${widget.session.tableNumber}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer
            _buildLabeledValue('Customer', widget.session.customerName),
            const SizedBox(height: AppTokens.space4),

            // Duration/Games
            if (isTennis)
              _buildLabeledValue(
                'Duration',
                '$durationMinutes min @ Rs.${widget.pricePerUnit.toStringAsFixed(0)}/min',
              )
            else
              _buildLabeledValue(
                'Games',
                '${widget.gameCount ?? 1} game${widget.gameCount != 1 ? 's' : ''} @ Rs.${widget.pricePerUnit.toStringAsFixed(0)}/game',
              ),
            const SizedBox(height: AppTokens.space4),

            // Gross Amount
            _buildLabeledValue(
              'Gross Amount',
              'Rs. ${_totalAmount?.toStringAsFixed(2) ?? '0.00'}',
              valueColor: AppColors.gray800,
            ),
            const SizedBox(height: AppTokens.space4),

            // Discount
            _buildLabel('Discount (Rs.)'),
            const SizedBox(height: AppTokens.space2),
            TextField(
              controller: _discountController,
              enabled: !_isLoading,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _onDiscountChanged,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: AppColors.gray500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space2,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space4),

            // Net Amount
            _buildLabeledValue(
              'Net Amount',
              'Rs. ${_finalAmount?.toStringAsFixed(2) ?? '0.00'}',
              valueColor: AppColors.primary,
              valueFontWeight: FontWeight.bold,
            ),
            const SizedBox(height: AppTokens.space4),

            // Payment Method
            _buildLabel('Payment Method'),
            const SizedBox(height: AppTokens.space2),
            if (_paymentMethods.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppTokens.space3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  border: Border.all(color: AppColors.warning),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                ),
                child: Text(
                  'No payment methods available',
                  style: TextStyle(color: AppColors.warning, fontSize: 13),
                ),
              )
            else
              DropdownButtonFormField<PaymentMethod>(
                value: _selectedPaymentMethod,
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.paymentName),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                          _showQrCode = value != null && value.imageUrl != null;
                        });
                      },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space3,
                    vertical: AppTokens.space2,
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.space4),

            // QR Code Display
            if (_showQrCode && _selectedPaymentMethod != null) ...[
              _buildQrCode(),
              const SizedBox(height: AppTokens.space4),
            ],

            // Notes
            _buildLabel('Notes (optional)'),
            const SizedBox(height: AppTokens.space2),
            TextField(
              controller: _notesController,
              enabled: !_isLoading,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Any additional notes...',
                hintStyle: TextStyle(color: AppColors.gray500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space2,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => _createAndPayBill(false),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              : const Text('Pay Later'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _createAndPayBill(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.onPrimary,
                    ),
                  ),
                )
              : const Text('Pay Now'),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.gray800,
      ),
    );
  }

  Widget _buildLabeledValue(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.gray600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: valueFontWeight ?? FontWeight.w500,
            color: valueColor ?? AppColors.gray800,
          ),
        ),
      ],
    );
  }

  Widget _buildQrCode() {
    if (_selectedPaymentMethod?.imageUrl == null) {
      return const SizedBox.shrink();
    }

    const qrSize = 180.0;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _selectedPaymentMethod!.imageUrl!,
                height: qrSize,
                width: qrSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: qrSize,
                    width: qrSize,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.qr_code,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              'Scan to pay via ${_selectedPaymentMethod!.paymentName}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
