import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_snackbar.dart';
import '../../../providers/game_provider.dart';
import '../../../services/auth_service.dart';

class StartSessionDialog extends StatefulWidget {
  final String gameType;
  final int tableNumber;

  const StartSessionDialog({
    super.key,
    required this.gameType,
    required this.tableNumber,
  });

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog> {
  late final TextEditingController _customerNameController;
  late final TextEditingController _notesController;
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController();
    _notesController = TextEditingController();
    _loadUserId();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadUserId() async {
    final user = await AuthService.getUser();
    if (mounted && user != null) {
      setState(() {
        _userId = user.id;
      });
    }
  }

  Future<void> _startSession() async {
    final customerName = _customerNameController.text.trim();
    final notes = _notesController.text.trim();

    if (customerName.isEmpty) {
      ModernSnackBar.error(context, 'Please enter customer name');
      return;
    }

    if (_userId == null) {
      ModernSnackBar.error(context, 'Not authenticated');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = await context.read<GameProvider>().startSession(
        gameType: widget.gameType,
        tableNumber: widget.tableNumber,
        customerName: customerName,
        createdBy: _userId!,
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        if (session != null) {
          Navigator.pop(context);
          ModernSnackBar.success(
            context,
            'Session started for Table ${widget.tableNumber}',
          );
        } else {
          ModernSnackBar.error(context, 'Failed to start session');
        }
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Start Session - Table ${widget.tableNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start a new game session on this table.',
              style: TextStyle(color: AppColors.gray600, fontSize: 13),
            ),
            const SizedBox(height: AppTokens.space4),

            // Customer Name
            _buildLabel('Customer Name (optional)'),
            const SizedBox(height: AppTokens.space2),
            TextField(
              controller: _customerNameController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Walk-in customer name',
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

            // Notes
            _buildLabel('Notes (optional)'),
            const SizedBox(height: AppTokens.space2),
            TextField(
              controller: _notesController,
              enabled: !_isLoading,
              maxLines: 3,
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
        ElevatedButton(
          onPressed: _isLoading ? null : _startSession,
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
              : const Text('Start Session'),
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
}
