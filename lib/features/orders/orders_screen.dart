import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int selectedTab = 0;
  final tabs = ['All', 'Completed', 'Pending', 'Failed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 3),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Row(children: [
              const Expanded(child: Text('Orders', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
              IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.file_download_outlined)),
            ]),
            const SizedBox(height: 18),
            const TextField(decoration: InputDecoration(hintText: 'Search order or customer', prefixIcon: Icon(Icons.search_rounded), suffixIcon: Icon(Icons.tune_rounded))),
            const SizedBox(height: 16),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ChoiceChip(label: Text(tabs[index]), selected: selectedTab == index, onSelected: (_) => setState(() => selectedTab = index)),
              ),
            ),
            const SizedBox(height: 18),
            _OrderTile(flag: '🇹🇷', title: 'Orange · Turkey', date: 'Today, 10:30', amount: '\$15.00', status: 'Completed', color: AppColors.success, onTap: () => context.push('/orders/detail')),
            const SizedBox(height: 12),
            _OrderTile(flag: '🇺🇸', title: 'T-Mobile · USA', date: 'Yesterday, 14:20', amount: '\$25.00', status: 'Completed', color: AppColors.success, onTap: () => context.push('/orders/detail')),
            const SizedBox(height: 12),
            _OrderTile(flag: '🇬🇧', title: 'Vodafone · UK', date: '05 Aug 2026', amount: '\$19.00', status: 'Pending', color: AppColors.warning, onTap: () => context.push('/orders/detail')),
            const SizedBox(height: 12),
            _OrderTile(flag: '🇫🇷', title: 'Orange · France', date: '04 Aug 2026', amount: '\$17.00', status: 'Failed', color: AppColors.danger, onTap: () => context.push('/orders/detail')),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String flag;
  final String title;
  final String date;
  final String amount;
  final String status;
  final Color color;
  final VoidCallback onTap;
  const _OrderTile({required this.flag, required this.title, required this.date, required this.amount, required this.status, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Container(height: 48, width: 48, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)), child: Text(flag, style: const TextStyle(fontSize: 24))),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(amount, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 7), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(999)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)))]),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ]),
          ),
        ),
      );
}
