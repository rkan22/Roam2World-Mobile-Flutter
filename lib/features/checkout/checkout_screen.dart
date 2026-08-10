import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../orders/orders_repository.dart';
import '../packages/package_catalog.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.package});

  final MobilePackage package;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imeiController = TextEditingController();
  final _repository = OrdersRepository();

  bool _accepted = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _imeiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false) || !_accepted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await _repository.createOrder(
        package: widget.package,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        imei: _imeiController.text,
      );
      if (!mounted) return;
      context.go('/checkout/success', extra: result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'The order could not be completed. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = widget.package;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _submitting ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('New order'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          B2BSpacing.lg,
          B2BSpacing.xs,
          B2BSpacing.lg,
          B2BSpacing.md,
        ),
        child: FilledButton.icon(
          onPressed: _accepted && !_submitting ? _submit : null,
          icon: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : const Icon(Icons.lock_outline_rounded),
          label: Text(
            _submitting
                ? 'Creating order...'
                : 'Pay & create order  •  ${package.formattedPrice}',
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            B2BSpacing.xs,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            const _OrderProgress(),
            const SizedBox(height: B2BSpacing.lg),
            Text(
              'Review your B2B order',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            Text(
              'Confirm the package and customer details before submitting the order.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: B2BSpacing.lg),
            B2BSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(icon: Icons.inventory_2_outlined, title: 'Package'),
                  const SizedBox(height: B2BSpacing.md),
                  Row(
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(B2BRadius.md),
                        ),
                        child: Text(
                          _flagFor(package.countryCode),
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: B2BSpacing.xxs),
                            Text(
                              '${package.displayProvider} · ${package.productKind}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: B2BSpacing.xxs),
                            Text(
                              '${package.dataLabel} · ${package.validityLabel}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Text(
                        package.formattedPrice,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.md),
            B2BSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(icon: Icons.person_outline_rounded, title: 'Customer'),
                  const SizedBox(height: B2BSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'First name'),
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Last name'),
                          validator: _required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Customer phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Enter customer phone';
                      if (text.length < 7) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                  TextFormField(
                    controller: _imeiController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'IMEI (only when required)',
                      prefixIcon: Icon(Icons.phone_iphone_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.md),
            B2BSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(icon: Icons.receipt_long_outlined, title: 'Review'),
                  const SizedBox(height: B2BSpacing.md),
                  _SummaryRow(label: 'Package', value: package.formattedPrice),
                  const _SummaryRow(label: 'Service fee', value: 'USD 0.00'),
                  const Divider(height: 28),
                  _SummaryRow(label: 'Total', value: package.formattedPrice, emphasized: true),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: B2BSpacing.md),
              Container(
                padding: const EdgeInsets.all(B2BSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                  border: Border.all(color: AppColors.danger.withValues(alpha: .25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                    const SizedBox(width: B2BSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: B2BSpacing.sm),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _accepted = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I confirm the customer and package information is correct.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Required' : null;
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.inventory_2_outlined, 'Package'),
      (Icons.person_outline_rounded, 'Customer'),
      (Icons.check_circle_outline_rounded, 'Review'),
    ];
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: index == 2 ? AppColors.primary : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    items[index].$1,
                    size: 18,
                    color: index == 2 ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  items[index].$2,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          if (index < items.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: AppColors.primarySoft,
              ),
            ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: B2BSpacing.xs),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: B2BSpacing.xxs),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasized ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _flagFor(String code) {
  if (code.length != 2) return '🌐';
  return code
      .toUpperCase()
      .codeUnits
      .map((unit) => String.fromCharCode(unit + 127397))
      .join();
}
