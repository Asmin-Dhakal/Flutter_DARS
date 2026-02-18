import 'package:flutter/material.dart';

class StatusFilter extends StatelessWidget {
  final String selectedStatus;
  final List<String> statusOptions;
  final Function(String) onStatusChanged;

  const StatusFilter({
    Key? key,
    required this.selectedStatus,
    required this.statusOptions,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: statusOptions.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(
                _formatStatus(status),
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onStatusChanged(value);
            }
          },
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'all':
        return 'All Status';
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'partially_paid':
        return 'Partially Paid';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
