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
  int selectedProvider = 0;
  int selectedRegion = 0;

  final providers = ['All', 'Orange', 'Vodafone', 'TGT', 'Flexnet'];
  final regions = ['Europe', 'Turkey', 'Balkans', 'Global'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Store',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search country, package or provider',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.public_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _HorizontalChips(
              items: providers,
              selectedIndex: selectedProvider,
              onSelected: (index) {
                setState(() => selectedProvider = index);
              },
            ),
            const SizedBox(height: 14),
            _HorizontalChips(
              items: regions,
              selectedIndex: selectedRegion,
              compact: true,
              onSelected: (index) {
                setState(() => selectedRegion = index);
              },
            ),
            const SizedBox(height: 22),
            const _FeaturedCard(),
            const SizedBox(height: 24),
            const Text(
              'Popular packages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            const _PackageCard(
              provider: 'Orange Europe',
              region: 'Europe · 41 Countries',
              data: '100GB',
              validity: '30 Days',
              cost: '\$28.00',
              sell: '\$35.00',
              profit: '\$7.00',
              color: AppColors.orange,
            ),
            const SizedBox(height: 14),
            const _PackageCard(
              provider: 'Vodafone EU',
              region: 'Europe · Premium Network',
              data: '200GB',
              validity: '30 Days',
              cost: '\$34.00',
              sell: '\$40.00',
              profit: '\$6.00',
              color: AppColors.vodafone,
            ),
            const SizedBox(height: 14),
            const _PackageCard(
              provider: 'Flexnet Europe',
              region: 'Europe · Big Data',
              data: '300GB',
              validity: '30 Days',
              cost: '\$42.00',
              sell: '\$50.00',
              profit: '\$8.00',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalChips extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool compact;

  const _HorizontalChips({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 42 : 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                items[index],
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Featured',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Europe Big Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '300GB · 30 days · Best seller',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String provider;
  final String region;
  final String data;
  final String validity;
  final String cost;
  final String sell;
  final String profit;
  final Color color;

  const _PackageCard({
    required this.provider,
    required this.region,
    required this.data,
    required this.validity,
    required this.cost,
    required this.sell,
    required this.profit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.public_rounded, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      region,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    validity,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _PriceBox(label: 'Cost', value: cost),
              const SizedBox(width: 10),
              _PriceBox(label: 'Sell', value: sell),
              const SizedBox(width: 10),
              _PriceBox(label: 'Profit', value: profit, highlight: true),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () {}, child: const Text('Buy Now')),
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _PriceBox({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: highlight ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
