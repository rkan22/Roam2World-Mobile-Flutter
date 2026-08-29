import 'package:flutter/material.dart';

import '../../core/currency/currency_controller.dart';
import '../../design_system/tokens/b2b_tokens.dart';

class CurrencySwitcherButton extends StatefulWidget {
  const CurrencySwitcherButton({super.key});

  @override
  State<CurrencySwitcherButton> createState() => _CurrencySwitcherButtonState();
}

class _CurrencySwitcherButtonState extends State<CurrencySwitcherButton> {
  final controller = CurrencyController.instance;

  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final current = controller.selectedCurrency;
        return Tooltip(
          message: current == 'EUR' ? 'Switch to USD' : 'Switch to EUR',
          child: _PremiumCurrencyPill(
            currency: current,
            onTap: controller.toggle,
          ),
        );
      },
    );
  }
}

class _PremiumCurrencyPill extends StatefulWidget {
  const _PremiumCurrencyPill({
    required this.currency,
    required this.onTap,
  });

  final String currency;
  final VoidCallback onTap;

  @override
  State<_PremiumCurrencyPill> createState() => _PremiumCurrencyPillState();
}

class _PremiumCurrencyPillState extends State<_PremiumCurrencyPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final symbol = widget.currency == 'EUR' ? '€' : r'$';

    return AnimatedScale(
      scale: _pressed ? .96 : 1,
      duration: B2BMotion.fast,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(B2BRadius.pill),
          child: AnimatedContainer(
            duration: B2BMotion.standard,
            height: 40,
            padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(B2BRadius.pill),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: isDark ? null : B2BShadows.card,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: B2BMotion.standard,
                  width: 31,
                  height: 31,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [scheme.primary, scheme.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: B2BMotion.fast,
                    child: Text(
                      symbol,
                      key: ValueKey(symbol),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: B2BMotion.fast,
                  child: Text(
                    widget.currency,
                    key: ValueKey(widget.currency),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.swap_vert_rounded,
                  size: 15,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
