import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
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
        leading: IconButton(onPressed: _submitting ? null : () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Checkout'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ElevatedButton(
          onPressed: _accepted && !_submitting ? _submit : null,
          child: _submitting
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Text('Confirm Order  •  ${package.formattedPrice}'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _SectionCard(
              title: 'Package',
              child: Row(children: [
                Container(height: 52, width: 52, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)), child: Text(_flagFor(package.countryCode), style: const TextStyle(fontSize: 26))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${package.destination} · ${package.displayProvider}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${package.dataLabel} · ${package.validityLabel}', style: const TextStyle(color: AppColors.textSecondary)),
                ])),
                Text(package.formattedPrice, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ]),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Customer',
              child: Column(children: [
                Row(children: [
                  Expanded(child: TextFormField(controller: _firstNameController, enabled: !_submitting, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'First name'), validator: _required)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _lastNameController, enabled: !_submitting, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Last name'), validator: _required)),
                ]),
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
                TextFormField(
                  controller: _imeiController,
                  enabled: !_submitting,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'IMEI (only when required)', prefixIcon: Icon(Icons.phone_iphone_outlined)),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Order summary',
              child: Column(children: [
                _SummaryRow(label: 'Package', value: package.formattedPrice),
                const _SummaryRow(label: 'Service fee', value: 'USD 0.00'),
                const Divider(height: 28),
                _SummaryRow(label: 'Total', value: package.formattedPrice, emphasized: true),
              ]),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: .08), borderRadius: BorderRadius.circular(16)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.error_outline_rounded, color: AppColors.danger), const SizedBox(width: 10), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)))]),
              ),
            ],
            const SizedBox(height: 14),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: _submitting ? null : (value) => setState(() => _accepted = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('I confirm the customer and package information is correct.'),
            ),
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) => (value?.trim().isEmpty ?? true) ? 'Required' : null;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 14), child]),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasized = false});
  final String label;
  final String value;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Text(label, style: TextStyle(color: emphasized ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500)), const Spacer(), Text(value, style: TextStyle(fontSize: emphasized ? 18 : 14, fontWeight: FontWeight.w900))]),
      );
}

String _flagFor(String code) {
  if (code.length != 2) return '🌐';
  return code.toUpperCase().codeUnits.map((unit) => String.fromCharCode(unit + 127397)).join();
}
