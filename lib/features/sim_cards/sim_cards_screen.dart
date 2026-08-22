import 'package:flutter/material.dart';

import '../../shared/widgets/r2w_toast.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'sim_card_models.dart';
import 'sim_cards_repository.dart';

class SimCardsScreen extends StatefulWidget {
  const SimCardsScreen({super.key});

  @override
  State<SimCardsScreen> createState() => _SimCardsScreenState();
}

class _SimCardsScreenState extends State<SimCardsScreen> {
  final _repository = SimCardsRepository();
  List<SimCardPackage> _packages = const [];
  bool _loading = true;
  String? _error;
  SimCardPackage? _selected;
  int _quantity = 1;
  bool _ordering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = _packages.isEmpty;
      _error = null;
    });
    try {
      final catalog = await _repository.fetchPackages();
      if (!mounted) return;
      setState(() {
        _packages = catalog.packages;
        if (_selected == null && _packages.isNotEmpty) {
          _selected = _packages.first;
          _quantity = _selected!.minimumQuantity;
        }
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'SIM stock could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _order() async {
    final package = _selected;
    if (package == null || _ordering) return;
    if (_quantity < package.minimumQuantity) {
      setState(() => _quantity = package.minimumQuantity);
      return;
    }
    setState(() => _ordering = true);
    try {
      final result = await _repository.createOrder(
        productId: package.id,
        quantity: _quantity,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Stock order created'),
          content: Text(
            '${result.order.orderNumber.isEmpty ? 'Order created' : result.order.orderNumber}\n'
            '${result.order.quantity} × ${result.order.productName}\n'
            'Status: ${result.order.status}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('SIM stock order could not be created.');
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  void _showError(String message) {
    R2WToast.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Text('SIM Card Stock', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 5),
              Text(
                'Order physical SIM stock for your B2B customers.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: B2BGradients.primary,
                  borderRadius: BorderRadius.circular(B2BRadius.xl),
                  boxShadow: B2BShadows.card,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sim_card_rounded, color: Colors.white, size: 42),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Physical SIM inventory',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Provider details are handled by the B2B backend.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const ContentLoadingState(label: 'Loading SIM stock...')
              else if (_error != null && _packages.isEmpty)
                ContentErrorState(
                  message: _error!,
                  onRetry: () => _load(refresh: true),
                )
              else if (_packages.isEmpty)
                const ContentEmptyState(
                  icon: Icons.sim_card_outlined,
                  title: 'No SIM stock available',
                  message:
                      'There are currently no enabled physical SIM products.',
                )
              else ...[
                Text('Available stock', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final package in _packages) ...[
                  _PackageCard(
                    package: package,
                    selected: _selected?.id == package.id,
                    onTap: () => setState(() {
                      _selected = package;
                      _quantity = package.minimumQuantity;
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_selected != null) ...[
                  const SizedBox(height: 6),
                  _OrderPanel(
                    package: _selected!,
                    quantity: _quantity,
                    ordering: _ordering,
                    onQuantityChanged: (value) =>
                        setState(() => _quantity = value),
                    onOrder: _order,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.selected,
    required this.onTap,
  });
  final SimCardPackage package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(B2BRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(B2BRadius.xl),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            boxShadow: theme.brightness == Brightness.light
                ? B2BShadows.card
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.sim_card_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(package.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(package.destination, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      'Minimum ${package.minimumQuantity}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${package.currency} ${package.price.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderPanel extends StatelessWidget {
  const _OrderPanel({
    required this.package,
    required this.quantity,
    required this.ordering,
    required this.onQuantityChanged,
    required this.onOrder,
  });
  final SimCardPackage package;
  final int quantity;
  final bool ordering;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = package.price * quantity;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: B2BShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order stock', style: theme.textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Quantity'),
              const Spacer(),
              IconButton(
                onPressed: quantity > package.minimumQuantity
                    ? () => onQuantityChanged(quantity - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$quantity', style: theme.textTheme.titleMedium),
              IconButton(
                onPressed: () => onQuantityChanged(quantity + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              const Text('Estimated total'),
              const Spacer(),
              Text(
                '${package.currency} ${total.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: ordering ? null : onOrder,
              icon: ordering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.local_shipping_outlined),
              label: Text(ordering ? 'Creating order...' : 'Place stock order'),
            ),
          ),
        ],
      ),
    );
  }
}
