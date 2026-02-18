import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'create_order/create_order_screen.dart';
import 'widgets/order_filters.dart';
import 'widgets/order_list.dart';
import 'widgets/order_stats.dart';
import 'widgets/order_pagination.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: RefreshIndicator(
        onRefresh: () => context.read<OrderProvider>().loadOrders(),
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            const SliverToBoxAdapter(child: OrderFilters()),
            const SliverToBoxAdapter(child: OrderStats()),
            const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space4)),
            if (provider.error != null)
              SliverToBoxAdapter(child: _buildError(provider.error!)),
            const OrderList(),
            const SliverToBoxAdapter(child: OrderPagination()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space4,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Orders',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Manage customer orders',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconButton(
                  icon: Icons.refresh_rounded,
                  onTap: () => context.read<OrderProvider>().loadOrders(),
                ),
                const SizedBox(width: AppTokens.space2),
                _IconButton(
                  icon: Icons.logout_rounded,
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space2,
      ),
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.error, size: 20),
            onPressed: () => context.read<OrderProvider>().loadOrders(),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
      ).then((_) => context.read<OrderProvider>().loadOrders()),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Order',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space2),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}
