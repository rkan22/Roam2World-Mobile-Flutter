import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int quantity = 1;
  bool sendEmail = true;
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    final total = 15 * quantity;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Checkout'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ElevatedButton(
          onPressed: accepted ? () => context.go('/checkout/success') : null,
          child: Text('Confirm Order  •  \$$total.00'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _SectionCard(
            title: 'Package',
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                  child: const Text('🇹🇷', style: TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Turkey · Orange', style: TextStyle(fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('10 GB · 30 Days · 5G', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Text('\$15.00', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _SectionCard(
            title: 'Customer',
            child: Column(
              children: [
                TextField(decoration: InputDecoration(labelText: 'Customer name', prefixIcon: Icon(Icons.person_outline_rounded))),
                SizedBox(height: 12),
                TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Customer email', prefixIcon: Icon(Icons.mail_outline_rounded))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Order settings',
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w800))),
                    IconButton.filledTonal(onPressed: quantity > 1 ? () => setState(() => quantity--) : null, icon: const Icon(Icons.remove_rounded)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    IconButton.filled(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add_rounded)),
                  ],
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: sendEmail,
                  onChanged: (value) => setState(() => sendEmail = value),
                  title: const Text('Email QR code to customer'),
                  subtitle: const Text('The customer receives installation details.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Order summary',
            child: Column(
              children: [
                _SummaryRow(label: 'Package', value: '\$${15 * quantity}.00'),
                const _SummaryRow(label: 'Service fee', value: '\$0.00'),
                const Divider(height: 28),
                _SummaryRow(label: 'Total', value: '\$$total.00', emphasized: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: accepted,
            onChanged: (value) => setState(() => accepted = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('I confirm the customer and package information is correct.'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  const _SummaryRow({required this.label, required this.value, this.emphasized = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(label, style: TextStyle(color: emphasized ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: emphasized ? 18 : 14, fontWeight: FontWeight.w900)),
        ]),
      );
}
