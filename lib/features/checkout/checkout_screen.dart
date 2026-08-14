import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
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
  final _simNumberController = TextEditingController();
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
    _simNumberController.dispose();
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
        simNumber: _simNumberController.text,
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
    final provider = package.provider.toLowerCase();
    final isPhysicalSim = package.packageType.toLowerCase() == 'simcard';
    final requiresWorldmoveSimNumber = provider == 'worldmove' && isPhysicalSim;
    final requiresTgtIccid = provider == 'tgt' && isPhysicalSim;
    final requiresSimIdentifier = requiresWorldmoveSimNumber || requiresTgtIccid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _submitting ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Checkout'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: _accepted && !_submitting ? _submit : null,
          child: _submitting
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text('Confirm order  •  ${package.formattedPrice}'),
                  ],
                ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text('Review and provision', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 5),
            Text('Confirm the plan and assign it to your customer.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: B2BGradients.primary,
                borderRadius: BorderRadius.circular(B2BRadius.xl),
                boxShadow: B2BShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(18)),
                    child: Text(_flagFor(package.countryCode), style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(package.destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text('${package.dataLabel} • ${package.validityLabel}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(package.displayProvider, style: TextStyle(color: Colors.white.withValues(alpha: .62), fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Text(package.formattedPrice, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Customer assignment',
              subtitle: 'These details will be attached to the B2B order.',
              child: Column(
                children: [
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
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Customer phone', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Enter customer phone';
                      if (text.length < 7) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (requiresSimIdentifier)
                    TextFormField(
                      controller: _simNumberController,
                      enabled: !_submitting,
                      keyboardType: requiresTgtIccid ? TextInputType.text : TextInputType.number,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      maxLength: requiresTgtIccid ? 22 : 20,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: requiresTgtIccid ? 'SIM ICCID / barcode' : '20-digit SIM number',
                        helperText: requiresTgtIccid
                            ? 'Required for TGT physical SIM. Use the 19–22 character ICCID/barcode printed on the card.'
                            : 'Required for Worldmove physical SIM top-up.',
                        prefixIcon: const Icon(Icons.sim_card_outlined),
                      ),
                      validator: (value) {
                        if (requiresTgtIccid) {
                          final normalized = _normalizeTgtIccid(value ?? '');
                          if (normalized.length < 19 || normalized.length > 22) {
                            return 'Enter a valid 19–22 character ICCID/barcode';
                          }
                          return null;
                        }
                        final normalized = (value ?? '').replaceAll(RegExp(r'\D'), '');
                        if (normalized.length != 20) return 'Enter the 20-digit SIM number';
                        return null;
                      },
                    )
                  else
                    TextFormField(
                      controller: _imeiController,
                      enabled: !_submitting,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(labelText: 'IMEI (when required)', prefixIcon: Icon(Icons.phone_iphone_outlined)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Order summary',
              subtitle: 'Wallet billing is applied when the order is confirmed.',
              child: Column(
                children: [
                  _SummaryRow(label: 'Package', value: package.formattedPrice),
                  const _SummaryRow(label: 'Service fee', value: 'USD 0.00'),
                  const Divider(height: 28),
                  _SummaryRow(label: 'Total', value: package.formattedPrice, emphasized: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(B2BRadius.lg)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: AppColors.accent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The order will be provisioned through your Roam2World B2B account and will appear in Orders and eSIMs.',
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: _submitting ? null : (value) => setState(() => _accepted = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('I confirm the customer and package information is correct.', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Provisioning starts after the order is accepted.'),
            ),
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) => (value?.trim().isEmpty ?? true) ? 'Required' : null;
}

String _normalizeTgtIccid(String raw) => raw
    .replaceAll(RegExp(r'[\s-]'), '')
    .toUpperCase()
    .replaceAll(RegExp(r'[^0-9A-Z]'), '');

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasized = false});
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 18 : 14,
            color: emphasized ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

String _flagFor(String code) {
  if (code.length != 2) return '🌐';
  return code.toUpperCase().codeUnits.map((unit) => String.fromCharCode(unit + 127397)).join();
}
