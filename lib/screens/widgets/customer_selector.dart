import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';

class CustomerSelector extends StatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer) onSelect;

  const CustomerSelector({
    super.key,
    this.selectedCustomer,
    required this.onSelect,
  });

  @override
  State<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<CustomerSelector> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  void _showCustomerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusXLarge),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: AppTokens.space3),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.all(AppTokens.space4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select Customer',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space4,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.searchCustomers('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (_searchController.text == value) {
                              provider.searchCustomers(value);
                            }
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: AppTokens.space3),

                    // Add New Customer Button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space4,
                      ),
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddCustomerDialog();
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create New Customer'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTokens.space3),

                    // Results Count
                    if (!provider.isLoading && provider.customers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.space4,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${provider.customers.length} customer${provider.customers.length == 1 ? '' : 's'} found',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),

                    const SizedBox(height: AppTokens.space2),

                    // Customer List
                    Expanded(
                      child: _buildCustomerList(provider, scrollController),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerList(
    CustomerProvider provider,
    ScrollController scrollController,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.customers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTokens.space4),
      itemCount: provider.customers.length,
      itemBuilder: (context, index) {
        final customer = provider.customers[index];
        final isSelected = widget.selectedCustomer?.id == customer.id;

        return _CustomerListTile(
          customer: customer,
          isSelected: isSelected,
          onTap: () {
            widget.onSelect(customer);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            'No customers found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Try a different search or create a new customer',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String? selectedGender;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final provider = context.read<CustomerProvider>();
          final isCreating = provider.isLoading;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
            ),
            title: const Text('Add New Customer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'Customer name',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppTokens.space3),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Phone number',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppTokens.space3),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Email address',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppTokens.space3),
                DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => selectedGender = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isCreating ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isCreating
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        final email = emailController.text.trim();

                        if (name.isEmpty) return;

                        // Call provider to create customer
                        final created = await provider.createCustomer(
                          name: name,
                          number: phone.isEmpty ? null : phone,
                          email: email.isEmpty ? null : email,
                          gender: selectedGender,
                        );

                        if (created != null) {
                          // Auto-select the new customer
                          widget.onSelect(created);
                          Navigator.pop(context);
                        } else {
                          // Keep dialog open; provider.error will show elsewhere
                        }
                      },
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showCustomerModal,
      borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          color: widget.selectedCustomer != null
              ? AppColors.primaryContainer
              : AppColors.surface,
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_outline_rounded,
              color: widget.selectedCustomer != null
                  ? AppColors.primary
                  : AppColors.gray600,
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: widget.selectedCustomer != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.selectedCustomer!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.selectedCustomer!.number != null)
                          Text(
                            widget.selectedCustomer!.number!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.gray600,
                            ),
                          ),
                      ],
                    )
                  : Text(
                      'Select Customer *',
                      style: TextStyle(fontSize: 16, color: AppColors.gray500),
                    ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: AppColors.gray600),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Helper Widget
class _CustomerListTile extends StatelessWidget {
  final Customer customer;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomerListTile({
    required this.customer,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.space2),
      elevation: 0,
      color: isSelected ? AppColors.primaryContainer : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : AppColors.outline.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space1,
        ),
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? AppColors.primary
              : AppColors.primaryContainer,
          child: Text(
            customer.name[0].toUpperCase(),
            style: TextStyle(
              color: isSelected ? AppColors.onPrimary : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          customer.number ?? customer.email ?? 'No contact info',
          style: TextStyle(color: AppColors.gray600, fontSize: 13),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}
