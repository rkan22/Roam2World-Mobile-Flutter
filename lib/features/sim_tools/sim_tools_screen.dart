import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';

class SimToolsScreen extends StatelessWidget {
  const SimToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _SimTool(
        title: 'My SIMs & eSIMs',
        description: 'View installed eSIMs, activation details and lifecycle actions.',
        icon: Icons.sim_card_outlined,
        route: AppRoutes.esims,
      ),
      _SimTool(
        title: 'eSIM History',
        description: 'Review lifecycle records and live TGT usage where supported.',
        icon: Icons.history_rounded,
        route: AppRoutes.esimHistory,
      ),
      _SimTool(
        title: 'SIM Converter',
        description: 'Convert eligible SIM profiles and continue with the LPA flow.',
        icon: Icons.sync_alt_rounded,
        route: AppRoutes.simConverter,
      ),
      _SimTool(
        title: 'TGT Bulk Operations',
        description: 'Run supported TGT bulk actions for reseller and dealer accounts.',
        icon: Icons.playlist_add_check_circle_outlined,
        route: AppRoutes.tgtBulkOperations,
      ),
      _SimTool(
        title: 'Physical SIM Stock',
        description: 'Order physical SIM inventory from the live B2B catalog.',
        icon: Icons.inventory_2_outlined,
        route: AppRoutes.simCards,
      ),
      _SimTool(
        title: 'SIM Orders',
        description: 'Track physical SIM stock orders and fulfillment status.',
        icon: Icons.local_shipping_outlined,
        route: AppRoutes.simCardOrders,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIM Tools'),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.dashboard),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.md, B2BSpacing.lg, B2BSpacing.xxl),
        children: [
          Text('SIM operations', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: B2BSpacing.xs),
          const Text(
            'One place for the SIM and eSIM workflows already available in the mobile backend integration.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: B2BSpacing.lg),
          for (final tool in tools) ...[
            B2BSurface(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(tool.icon, color: AppColors.primary),
                ),
                title: Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(tool.description),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(tool.route),
              ),
            ),
            const SizedBox(height: B2BSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SimTool {
  const _SimTool({required this.title, required this.description, required this.icon, required this.route});

  final String title;
  final String description;
  final IconData icon;
  final String route;
}
