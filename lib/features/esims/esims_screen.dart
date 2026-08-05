import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';

class EsimsScreen extends StatefulWidget {
  const EsimsScreen({super.key});

  @override
  State<EsimsScreen> createState() => _EsimsScreenState();
}

class _EsimsScreenState extends State<EsimsScreen> {
  int selectedTab = 0;
  final tabs = ['All', 'Active', 'Expired', 'Installed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.qr_code_scanner_rounded),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const Row(
              children: [
                Expanded(child: Text('eSIMs', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
                Badge(child: Icon(Icons.notifications_none_rounded)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Track installation, usage and expiration.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            const TextField(decoration: InputDecoration(hintText: 'Search customer, ICCID or package', prefixIcon: Icon(Icons.search_rounded))),
            const SizedBox(height: 16),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ChoiceChip(
                  label: Text(tabs[index]),
                  selected: selectedTab == index,
                  onSelected: (_) => setState(() => selectedTab = index),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _EsimCard(
              country: '🇹🇷', provider: 'Orange · Turkey', state: 'Installed', status: 'Active',
              usage: '1.6 GB / 10 GB', progress: .16, expires: '04 Sep 2026',
              onTap: () => context.push('/esims/detail'),
            ),
            const SizedBox(height: 12),
            _EsimCard(
              country: '🇺🇸', provider: 'T-Mobile · USA', state: 'Installed', status: 'Active',
              usage: '7.9 GB / 20 GB', progress: .395, expires: '18 Sep 2026',
              onTap: () => context.push('/esims/detail'),
            ),
            const SizedBox(height: 12),
            _EsimCard(
              country: '🇬🇧', provider: 'Vodafone · UK', state: 'Not installed', status: 'Ready',
              usage: '0 GB / 15 GB', progress: 0, expires: 'Not started',
              onTap: () => context.push('/esims/detail'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EsimCard extends StatelessWidget {
  final String country;
  final String provider;
  final String state;
  final String status;
  final String usage;
  final double progress;
  final String expires;
  final VoidCallback onTap;

  const _EsimCard({required this.country, required this.provider, required this.state, required this.status, required this.usage, required this.progress, required this.expires, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              Row(
                children: [
                  Text(country, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(provider, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 3), Text(state, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(999)), child: Text(status, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 16),
              Row(children: [Text(usage, style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), const Icon(Icons.network_cell_rounded, size: 17, color: AppColors.textSecondary), const SizedBox(width: 4), const Text('5G', style: TextStyle(color: AppColors.textSecondary))]),
              const SizedBox(height: 9),
              ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: AppColors.primaryLight)),
              const SizedBox(height: 10),
              Row(children: [const Text('Expires', style: TextStyle(color: AppColors.textSecondary)), const Spacer(), Text(expires, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 6), const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary)]),
            ],
          ),
        ),
      );
}
