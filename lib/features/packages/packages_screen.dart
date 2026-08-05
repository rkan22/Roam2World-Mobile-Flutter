import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});
  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  int selectedFilter = 0;
  final filters = ['All', 'Data', 'Voice', 'Data + Voice'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Row(children: [
              const Expanded(child: Text('Packages', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
              IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
            ]),
            const SizedBox(height: 18),
            const TextField(decoration: InputDecoration(hintText: 'Search countries or packages', prefixIcon: Icon(Icons.search_rounded))),
            const SizedBox(height: 22),
            Row(children: [const Text('Popular Countries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const Spacer(), TextButton(onPressed: () {}, child: const Text('View All'))]),
            const SizedBox(height: 10),
            const SizedBox(height: 76, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _Country(flag: '🇹🇷', name: 'Turkey'),
              _Country(flag: '🇺🇸', name: 'USA'),
              _Country(flag: '🇬🇧', name: 'UK'),
              _Country(flag: '🇫🇷', name: 'France'),
              _Country(flag: '🇩🇪', name: 'Germany'),
            ])),
            const SizedBox(height: 20),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == filters.length) return IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.tune_rounded));
                  final selected = selectedFilter == index;
                  return ChoiceChip(label: Text(filters[index]), selected: selected, onSelected: (_) => setState(() => selectedFilter = index));
                },
              ),
            ),
            const SizedBox(height: 18),
            _PackageTile(flag: '🇹🇷', country: 'Turkey', provider: 'Orange', data: '10 GB', validity: '30 Days', price: '\$15.00', onTap: () => context.push('/packages/detail')),
            const SizedBox(height: 12),
            _PackageTile(flag: '🇺🇸', country: 'USA', provider: 'T-Mobile', data: '20 GB', validity: '30 Days', price: '\$25.00', onTap: () => context.push('/packages/detail')),
            const SizedBox(height: 12),
            _PackageTile(flag: '🇬🇧', country: 'United Kingdom', provider: 'Vodafone', data: '15 GB', validity: '30 Days', price: '\$19.00', onTap: () => context.push('/packages/detail')),
          ],
        ),
      ),
    );
  }
}

class _Country extends StatelessWidget {
  final String flag;
  final String name;
  const _Country({required this.flag, required this.name});
  @override
  Widget build(BuildContext context) => Column(children: [Container(height: 48, width: 48, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: Text(flag, style: const TextStyle(fontSize: 24))), const SizedBox(height: 6), Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]);
}

class _PackageTile extends StatelessWidget {
  final String flag;
  final String country;
  final String provider;
  final String data;
  final String validity;
  final String price;
  final VoidCallback onTap;
  const _PackageTile({required this.flag, required this.country, required this.provider, required this.data, required this.validity, required this.price, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Container(height: 52, width: 52, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(17)), child: Text(flag, style: const TextStyle(fontSize: 27))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(country, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 3), Text(provider, style: const TextStyle(color: AppColors.textSecondary)), const SizedBox(height: 8), Row(children: [const Icon(Icons.data_usage_rounded, size: 15, color: AppColors.textSecondary), const SizedBox(width: 4), Text(data, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(width: 12), const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textSecondary), const SizedBox(width: 4), Text(validity, style: const TextStyle(fontWeight: FontWeight.w800))])])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), const SizedBox(height: 10), FilledButton(onPressed: onTap, style: FilledButton.styleFrom(minimumSize: const Size(76, 38), padding: const EdgeInsets.symmetric(horizontal: 16)), child: const Text('Buy'))]),
            ]),
          ),
        ),
      );
}
