import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../models/bill.dart';

/// Modular Bill Item Card used in Create Bill flow
class BillItemCard extends StatefulWidget {
  final SelectableBillItem item;
  final ValueChanged<bool> onSelectChanged;
  final ValueChanged<int> onQuantityChanged;

  const BillItemCard({
    super.key,
    required this.item,
    required this.onSelectChanged,
    required this.onQuantityChanged,
  });

  @override
  State<BillItemCard> createState() => _BillItemCardState();
}

class _BillItemCardState extends State<BillItemCard> {
  late TextEditingController _controller;
  Timer? _debounce;
  bool _isPending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.item.selectedQuantity.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant BillItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.selectedQuantity != widget.item.selectedQuantity) {
      _controller.text = widget.item.selectedQuantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFullyBilled = widget.item.availableQuantity == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space2),
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        color: isFullyBilled
            ? AppColors.gray200
            : AppColors.onPrimaryContainer.withOpacity(0.02),
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: Row(
        children: [
          isFullyBilled
              ? Icon(Icons.check_circle, color: AppColors.success, size: 22)
              : Checkbox(
                  value: widget.item.isSelected,
                  onChanged: (v) => widget.onSelectChanged(v ?? false),
                ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.menuItemName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isFullyBilled
                              ? AppColors.gray500
                              : AppColors.gray800,
                          decoration: isFullyBilled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFullyBilled) ...[
                      const SizedBox(width: AppTokens.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.space2,
                          vertical: AppTokens.space1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSmall,
                          ),
                        ),
                        child: Text(
                          'Billed',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTokens.space1),
                Text(
                  '${widget.item.orderNumber} · Rs. ${widget.item.priceAtOrder.toStringAsFixed(0)} each',
                  style: TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppTokens.space3),

          isFullyBilled
              ? Text(
                  'Billed',
                  style: TextStyle(
                    color: AppColors.gray600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space2,
                            vertical: AppTokens.space2,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSmall,
                            ),
                            borderSide: BorderSide(
                              color: _isPending
                                  ? AppColors.primary.withOpacity(0.3)
                                  : AppColors.gray300,
                            ),
                          ),
                          suffixIcon: _isPending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Padding(
                                    padding: EdgeInsets.all(3.0),
                                    child: SkeletonBox(width: 12, height: 12),
                                  ),
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          final qty = int.tryParse(val) ?? 0;
                          final clamped = qty.clamp(
                            0,
                            widget.item.availableQuantity,
                          );
                          // debounce updates to reduce re-renders on low-end devices
                          _debounce?.cancel();
                          setState(() => _isPending = true);
                          _debounce = Timer(AppTokens.durationNormal, () {
                            if (mounted) {
                              widget.onQuantityChanged(clamped);
                              setState(() => _isPending = false);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppTokens.space2),
                    Text(
                      '/ ${widget.item.availableQuantity}',
                      style: TextStyle(color: AppColors.gray600, fontSize: 12),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
