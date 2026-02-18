import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';

class OrderPagination extends StatelessWidget {
  const OrderPagination({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    if (provider.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Page
          IconButton(
            onPressed: provider.hasPrevPage ? () => provider.prevPage() : null,
            icon: const Icon(Icons.chevron_left),
            color: provider.hasPrevPage ? Colors.orange.shade800 : Colors.grey,
          ),

          // Page Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page ${provider.currentPage} of ${provider.totalPages}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // Next Page
          IconButton(
            onPressed: provider.hasNextPage ? () => provider.nextPage() : null,
            icon: const Icon(Icons.chevron_right),
            color: provider.hasNextPage ? Colors.orange.shade800 : Colors.grey,
          ),
        ],
      ),
    );
  }
}
