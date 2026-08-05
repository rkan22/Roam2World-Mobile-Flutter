import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _customers = const [
    ('Mehmet Yılmaz', 'mehmet@example.com', '+90 555 123 4567', 8),
    ('Ali Demir', 'ali@example.com', '+90 532 888 1122', 4),
    ('Ayşe Kaya', 'ayse@example.com', '+90 542 777 3344', 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Customers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomer(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add customer'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search name, email or phone',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('Recent customers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('${_customers.length} customers', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ..._customers.map((customer) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CustomerCard(
                  name: customer.$1,
                  email: customer.$2,
                  phone: customer.$3,
                  orders: customer.$4,
                ),
              )),
        ],
      ),
    );
  }

  void _showAddCustomer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New customer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            const TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email address')),
            const SizedBox(height: 12),
            const TextField(keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone number')),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Customer added')));
              },
              child: const Text('Save customer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final int orders;

  const _CustomerCard({required this.name, required this.email, required this.phone, required this.orders});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').take(2).map((part) => part[0]).join();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primaryLight,
            child: Text(initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$orders', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const Text('orders', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
