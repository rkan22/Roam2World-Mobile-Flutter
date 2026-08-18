import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'manual_fulfillment_repository.dart';

Future<ManualProductDraft?> showManualProductForm(
  BuildContext context, {
  ManualProductItem? product,
}) {
  return showModalBottomSheet<ManualProductDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ManualProductForm(product: product),
  );
}

class _ManualProductForm extends StatefulWidget {
  const _ManualProductForm({this.product});

  final ManualProductItem? product;

  @override
  State<_ManualProductForm> createState() => _ManualProductFormState();
}

class _ManualProductFormState extends State<_ManualProductForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _packageId;
  late final TextEditingController _operatorName;
  late final TextEditingController _productName;
  late final TextEditingController _providerCost;
  late final TextEditingController _currency;
  late final TextEditingController _dataGb;
  late final TextEditingController _validityDays;
  late final TextEditingController _countries;
  late final TextEditingController _notes;
  late final TextEditingController _lowStockThreshold;

  late String _productType;
  late bool _isActive;
  late bool _visibleToResellers;
  late bool _visibleToDealers;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _packageId = TextEditingController(text: product?.packageId ?? '');
    _operatorName = TextEditingController(text: product?.operatorName ?? '');
    _productName = TextEditingController(text: product?.name ?? '');
    _providerCost = TextEditingController(
      text: product == null ? '' : product.providerCost.toStringAsFixed(2),
    );
    _currency = TextEditingController(text: product?.currency ?? 'USD');
    _dataGb = TextEditingController(text: product?.dataGb?.toString() ?? '');
    _validityDays = TextEditingController(
      text: product?.validityDays?.toString() ?? '',
    );
    _countries = TextEditingController(
      text: product?.coverageCountries.join(', ') ?? '',
    );
    _notes = TextEditingController(text: product?.notes ?? '');
    _lowStockThreshold = TextEditingController(
      text: '${product?.lowStockThreshold ?? 3}',
    );
    _productType = product?.type == 'sim' ? 'sim' : 'esim';
    _isActive = product?.active ?? true;
    _visibleToResellers = product?.visibleToResellers ?? true;
    _visibleToDealers = product?.visibleToDealers ?? true;
  }

  @override
  void dispose() {
    _packageId.dispose();
    _operatorName.dispose();
    _productName.dispose();
    _providerCost.dispose();
    _currency.dispose();
    _dataGb.dispose();
    _validityDays.dispose();
    _countries.dispose();
    _notes.dispose();
    _lowStockThreshold.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _positiveNumber(String? value) {
    final number = double.tryParse((value ?? '').trim());
    if (number == null) return 'Enter a valid number';
    if (number < 0) return 'Cannot be negative';
    return null;
  }

  String? _optionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim()) == null
        ? 'Enter a valid number'
        : null;
  }

  String? _optionalWholeNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = int.tryParse(value.trim());
    if (number == null || number < 0) return 'Enter a valid whole number';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(
      context,
      ManualProductDraft(
        packageId: _packageId.text,
        operatorName: _operatorName.text,
        productName: _productName.text,
        productType: _productType,
        providerCost: double.parse(_providerCost.text.trim()),
        currency: _currency.text,
        dataGb: _dataGb.text.trim().isEmpty
            ? null
            : double.parse(_dataGb.text.trim()),
        validityDays: _validityDays.text.trim().isEmpty
            ? null
            : int.parse(_validityDays.text.trim()),
        coverageCountries: _countries.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
        notes: _notes.text,
        isActive: _isActive,
        visibleToResellers: _visibleToResellers,
        visibleToDealers: _visibleToDealers,
        lowStockThreshold: _productType == 'sim'
            ? int.tryParse(_lowStockThreshold.text.trim()) ?? 0
            : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return FractionallySizedBox(
      heightFactor: .94,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          B2BSpacing.lg,
          B2BSpacing.xs,
          B2BSpacing.lg,
          keyboard + B2BSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                _editing ? 'Edit manual product' : 'Add manual product',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: B2BSpacing.xs),
              const Text(
                'Products are fulfilled manually when no provider API is available.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: B2BSpacing.lg),
              TextFormField(
                controller: _packageId,
                enabled: !_editing,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Product ID',
                  hintText: 'MANUAL-ESIM-10GB-30D',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                validator: _required,
              ),
              const SizedBox(height: B2BSpacing.md),
              TextFormField(
                controller: _productName,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: B2BSpacing.md),
              TextFormField(
                controller: _operatorName,
                decoration: const InputDecoration(
                  labelText: 'Operator / brand',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: B2BSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _productType,
                decoration: const InputDecoration(
                  labelText: 'Product type',
                  prefixIcon: Icon(Icons.sim_card_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'esim', child: Text('eSIM')),
                  DropdownMenuItem(value: 'sim', child: Text('Physical SIM')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _productType = value);
                },
              ),
              const SizedBox(height: B2BSpacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _providerCost,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Provider cost',
                      ),
                      validator: _positiveNumber,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _currency,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 3,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        counterText: '',
                      ),
                      validator: (value) {
                        final requiredError = _required(value);
                        if (requiredError != null) return requiredError;
                        return value!.trim().length == 3
                            ? null
                            : 'Use 3 letters';
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dataGb,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Data GB'),
                      validator: _optionalNumber,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _validityDays,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Validity days',
                      ),
                      validator: _optionalWholeNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.md),
              TextFormField(
                controller: _countries,
                decoration: const InputDecoration(
                  labelText: 'Coverage countries',
                  hintText: 'TR, DE, FR',
                  prefixIcon: Icon(Icons.public_rounded),
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              if (_productType == 'sim') ...[
                TextFormField(
                  controller: _lowStockThreshold,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Low stock warning level',
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                  validator: _optionalWholeNumber,
                ),
                const SizedBox(height: B2BSpacing.md),
              ],
              TextFormField(
                controller: _notes,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Internal notes',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active product'),
                subtitle: const Text('Available for new orders'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible to resellers'),
                value: _visibleToResellers,
                onChanged: (value) =>
                    setState(() => _visibleToResellers = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible to dealers'),
                value: _visibleToDealers,
                onChanged: (value) => setState(() => _visibleToDealers = value),
              ),
              const SizedBox(height: B2BSpacing.lg),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(_editing ? 'Save changes' : 'Create product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
