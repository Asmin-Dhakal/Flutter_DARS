import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load customers when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          customerProvider.clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                // Debounce search - wait for user to stop typing
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    customerProvider.searchCustomers(value);
                  }
                });
              },
            ),
          ),

          // Error Message
          if (customerProvider.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customerProvider.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => customerProvider.loadCustomers(),
                  ),
                ],
              ),
            ),

          // Loading or Content
          Expanded(
            child: customerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customerProvider.customers.isEmpty
                ? _buildEmptyState()
                : _buildCustomerList(customerProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(CustomerProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadCustomers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.customers.length,
        itemBuilder: (context, index) {
          final customer = provider.customers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                customer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (customer.email != null)
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer.email!,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  if (customer.number != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer.number!,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                  if (customer.gender != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: customer.gender == 'male'
                            ? Colors.blue.shade50
                            : Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        customer.gender!,
                        style: TextStyle(
                          fontSize: 12,
                          color: customer.gender == 'male'
                              ? Colors.blue.shade700
                              : Colors.pink.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              onTap: () {
                // TODO: Navigate to customer detail or select for order
                _showCustomerOptions(customer);
              },
            ),
          );
        },
      ),
    );
  }

  void _showCustomerOptions(dynamic customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                customer.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.shopping_cart,
                  color: Colors.orange.shade800,
                ),
                title: const Text('Create Order for Customer'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to menu with pre-selected customer
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('View Order History'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to order history
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Customer'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to edit screen
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
