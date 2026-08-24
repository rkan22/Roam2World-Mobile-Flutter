import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/package_type_chip.dart';
import '../../shared/widgets/package_destination_visual.dart';
import '../orders/orders_repository.dart';
import '../packages/package_catalog.dart';
import '../wallet/wallet_data.dart';
import '../wallet/wallet_repository.dart';
import 'widgets/checkout_progress.dart';

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
  final _simNumberController = TextEditingController();
  final _ordersRepository = OrdersRepository();
  final _walletRepository = WalletRepository();

  late Future<WalletData> _walletFuture;

  int _currentStep = 0;
  bool _accepted = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _walletFuture = _walletRepository.fetchSmartWalletStatus();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _simNumberController.dispose();
    super.dispose();
  }

  void _goBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
        _error = null;
      });
      return;
    }
    context.pop();
  }

  void _continueCheckout() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_currentStep == 0) {
      setState(() {
        _currentStep = 1;
        _error = null;
      });
      return;
    }

    if (_currentStep == 1) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      setState(() {
        _currentStep = 2;
        _error = null;
      });
      return;
    }

    _submit();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!widget.package.isPriceAvailable) {
      setState(() {
        _error = 'This package does not currently have an approved B2B price.';
      });
      return;
    }

    if (_submitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_accepted) {
      setState(() {
        _error = 'Confirm the order information before continuing.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await _ordersRepository.createOrder(
        package: widget.package,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        simNumber: _simNumberController.text,
      );

      if (!mounted) return;
      _walletRepository.invalidateCache();
      context.go('/checkout/success', extra: result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'The B2B order could not be completed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = widget.package;
    final provider = package.provider.toLowerCase();
    final isPhysicalSim = package.packageType.toLowerCase() == 'simcard';
    final requiresTgtIccid = provider == 'tgt' && isPhysicalSim;
    final requiresWorldmoveSim = provider == 'worldmove' && isPhysicalSim;
    final requiresSimIdentifier = requiresTgtIccid || requiresWorldmoveSim;

    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final keyboardOpen = keyboardInset > 0;
    final bottomOffset = keyboardOpen
        ? keyboardInset + 8
        : media.padding.bottom + 12;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _submitting ? null : _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Checkout'),
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  keyboardInset + (keyboardOpen ? 24 : 126),
                ),
                children: [
                  CheckoutProgress(currentStep: _currentStep),
                  const SizedBox(height: 24),
                  Text(switch (_currentStep) {
                    0 => 'Your cart',
                    1 => 'Customer details',
                    _ => 'Review your order',
                  }, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 5),
                  Text(switch (_currentStep) {
                    0 => 'Review the selected B2B package before continuing.',
                    1 => 'Assign this package to your end customer.',
                    _ => 'Confirm the customer, package and wallet charge.',
                  }, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 18),
                  if (_currentStep == 0 || _currentStep == 2)
                    _PackageSummary(package: package),
                  if (_currentStep == 0) ...[
                    const SizedBox(height: 14),
                    _CartSummary(package: package),
                  ],
                  if (_currentStep == 1) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      step: '1',
                      title: 'End customer',
                      subtitle:
                          'These details will be attached to the B2B order.',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  enabled: !_submitting,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [
                                    AutofillHints.givenName,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'First name',
                                  ),
                                  validator: _required,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  enabled: !_submitting,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [
                                    AutofillHints.familyName,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Last name',
                                  ),
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
                            textInputAction: requiresSimIdentifier
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            onFieldSubmitted: (_) {
                              if (!requiresSimIdentifier) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Customer phone',
                              hintText: '+90 5xx xxx xx xx',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) {
                              final normalized = (value ?? '').replaceAll(
                                RegExp(r'[^0-9+]'),
                                '',
                              );
                              final digits = normalized.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              if (digits.isEmpty) {
                                return 'Enter the customer phone number';
                              }
                              if (digits.length < 7) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          if (requiresSimIdentifier) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _simNumberController,
                              enabled: !_submitting,
                              keyboardType: requiresTgtIccid
                                  ? TextInputType.text
                                  : TextInputType.number,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              autocorrect: false,
                              enableSuggestions: false,
                              maxLength: requiresTgtIccid ? 22 : 20,
                              onFieldSubmitted: (_) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              decoration: InputDecoration(
                                labelText: requiresTgtIccid
                                    ? 'SIM ICCID / barcode'
                                    : '20-digit SIM number',
                                helperText: requiresTgtIccid
                                    ? 'Enter or paste the complete ICCID, including its final letter.'
                                    : 'Enter the number printed on the physical SIM.',
                                prefixIcon: const Icon(Icons.sim_card_outlined),
                              ),
                              validator: (value) {
                                if (requiresTgtIccid) {
                                  final normalized = _normalizeTgtIccid(
                                    value ?? '',
                                  );
                                  if (normalized.length < 19 ||
                                      normalized.length > 22) {
                                    return 'Enter a valid 19–22 character ICCID';
                                  }
                                  return null;
                                }

                                final digits = (value ?? '').replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );
                                if (digits.length != 20) {
                                  return 'Enter the 20-digit SIM number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_currentStep == 2) ...[
                    const SizedBox(height: 14),
                    FutureBuilder<WalletData>(
                      future: _walletFuture,
                      builder: (context, snapshot) {
                        return _WalletSummary(
                          package: package,
                          wallet: snapshot.data,
                          loading:
                              snapshot.connectionState ==
                              ConnectionState.waiting,
                          failed: snapshot.hasError,
                          onRetry: () {
                            setState(() {
                              _walletFuture = _walletRepository
                                  .fetchSmartWalletStatus();
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      step: '3',
                      title: 'Final confirmation',
                      subtitle:
                          'Provisioning starts after the backend accepts this order.',
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        value: _accepted,
                        onChanged: _submitting
                            ? null
                            : (value) {
                                setState(() {
                                  _accepted = value ?? false;
                                  if (_accepted) _error = null;
                                });
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Customer and package information is correct',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'The package price will be deducted from the business wallet.',
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _CheckoutError(message: _error!),
                    ],
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomOffset,
            child: _CheckoutAction(
              package: package,
              keyboardOpen: keyboardOpen,
              currentStep: _currentStep,
              accepted: _accepted,
              submitting: _submitting,
              onCloseKeyboard: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              onSubmit: _continueCheckout,
            ),
          ),
        ],
      ),
    );
  }

  static String? _required(String? value) {
    return (value?.trim().isEmpty ?? true) ? 'Required' : null;
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.package});

  final MobilePackage package;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          const _SummaryRow(label: 'Quantity', value: '1', emphasized: true),
          const Divider(height: 26),
          _SummaryRow(label: 'Subtotal', value: package.formattedPrice),
          const _SummaryRow(label: 'Delivery', value: 'Free'),
          const Divider(height: 26),
          _SummaryRow(
            label: 'Total',
            value: package.formattedPrice,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _PackageSummary extends StatelessWidget {
  const _PackageSummary({required this.package});

  final MobilePackage package;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = _checkoutPlanTitle(package);
    final type = package.packageType.toLowerCase() == 'simcard'
        ? 'Physical SIM'
        : 'eSIM';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light
            ? B2BShadows.card
            : null,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(B2BRadius.md),
            ),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 38,
                  child: Center(
                    child: PackageDestinationVisual(
                      code: package.countryCode,
                      destinationKey: package.destinationKey,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                PackageTypeChip(packageType: package.packageType),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _PlanDetailRow(
            icon: Icons.signal_cellular_alt_rounded,
            label: 'Type',
            value: type == 'eSIM' ? 'Data only' : 'Physical SIM',
          ),
          _PlanDetailRow(
            icon: Icons.data_usage_rounded,
            label: 'Data',
            value: package.dataLabel,
          ),
          _PlanDetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Validity',
            value: package.validityLabel,
          ),
          _PlanDetailRow(
            icon: Icons.public_rounded,
            label: 'Coverage',
            value: package.destination,
          ),
          const Divider(height: 24),
          _PlanDetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'B2B price',
            value: package.formattedPrice,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _PlanDetailRow extends StatelessWidget {
  const _PlanDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: emphasized ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: emphasized
                    ? AppColors.textPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
                fontSize: emphasized ? 17 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletSummary extends StatelessWidget {
  const _WalletSummary({
    required this.package,
    required this.wallet,
    required this.loading,
    required this.failed,
    required this.onRetry,
  });

  final MobilePackage package;
  final WalletData? wallet;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _SectionCard(
        step: '2',
        title: 'Business wallet',
        subtitle: 'Checking the available dealer balance.',
        child: LinearProgressIndicator(),
      );
    }

    if (failed || wallet == null) {
      return _SectionCard(
        step: '2',
        title: 'Business wallet',
        subtitle:
            'The live balance could not be loaded. The backend will still validate the order.',
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry balance check'),
        ),
      );
    }

    final currency = wallet!.currency;
    final available = wallet!.availableAmount;
    final afterOrder = available - package.price;
    final sufficient = afterOrder >= 0;

    String money(double value) {
      return '$currency ${value.toStringAsFixed(2)}';
    }

    return _SectionCard(
      step: '2',
      title: 'Business wallet',
      subtitle: 'Review the wallet impact before confirming.',
      child: Column(
        children: [
          _SummaryRow(label: 'Available balance', value: money(available)),
          _SummaryRow(
            label: 'Order total',
            value: '-${package.formattedPrice}',
          ),
          const Divider(height: 28),
          _SummaryRow(
            label: 'Balance after order',
            value: money(afterOrder),
            emphasized: true,
            valueColor: sufficient ? AppColors.success : AppColors.danger,
          ),
          if (!sufficient) ...[
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The wallet balance may be insufficient. Add funds before placing this order.',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutAction extends StatelessWidget {
  const _CheckoutAction({
    required this.package,
    required this.keyboardOpen,
    required this.currentStep,
    required this.accepted,
    required this.submitting,
    required this.onCloseKeyboard,
    required this.onSubmit,
  });

  final MobilePackage package;
  final bool keyboardOpen;
  final int currentStep;
  final bool accepted;
  final bool submitting;
  final VoidCallback onCloseKeyboard;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Theme.of(context).colorScheme.surface,
      shadowColor: Colors.black.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(B2BRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (keyboardOpen) ...[
              IconButton(
                tooltip: 'Close keyboard',
                onPressed: onCloseKeyboard,
                icon: const Icon(Icons.keyboard_hide_rounded),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    package.isPriceAvailable &&
                        !submitting &&
                        (currentStep < 2 || accepted)
                    ? onSubmit
                    : null,
                icon: submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.3),
                      )
                    : Icon(
                        currentStep == 2
                            ? Icons.lock_outline_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                label: Text(
                  submitting
                      ? 'Creating B2B order...'
                      : switch (currentStep) {
                          0 => 'Continue',
                          1 => 'Review order',
                          _ => 'Place order · ${package.formattedPrice}',
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutError extends StatelessWidget {
  const _CheckoutError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(B2BRadius.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String step;
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
        boxShadow: theme.brightness == Brightness.light
            ? B2BShadows.card
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 30,
                width: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasized ? 17 : 14,
              color:
                  valueColor ??
                  (emphasized ? AppColors.primary : AppColors.textPrimary),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _checkoutPlanTitle(MobilePackage package) {
  var name = package.name
      .replaceAll(RegExp(r'\[\s*esim\s*\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'[_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final removable = [package.dataLabel, package.validityLabel];

  for (final value in removable) {
    final compact = value.replaceAll(' ', r'\s*');
    name = name.replaceAll(RegExp(compact, caseSensitive: false), '');
  }

  name = name
      .replaceAll(RegExp(r'[/|·-]+\s*$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (name.isNotEmpty) return name;
  if (package.destination.trim().isNotEmpty) {
    return package.destination.trim();
  }
  return 'Business data plan';
}

String _normalizeTgtIccid(String raw) {
  return raw
      .replaceAll(RegExp(r'[\s-]'), '')
      .toUpperCase()
      .replaceAll(RegExp(r'[^0-9A-Z]'), '');
}
