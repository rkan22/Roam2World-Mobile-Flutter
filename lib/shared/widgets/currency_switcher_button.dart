import 'package:flutter/material.dart';

import '../../core/currency/currency_controller.dart';

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
        final currentSymbol = current == 'EUR' ? '€' : r'$';
        final nextSymbol = current == 'EUR' ? r'$' : '€';
        return Tooltip(
          message: current == 'EUR' ? 'Switch to USD' : 'Switch to EUR',
          child: InkWell(
            onTap: controller.toggle,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 5,
                    top: 5,
                    child: _CurrencyDot(
                      symbol: currentSymbol,
                      color: Theme.of(context).colorScheme.onSurface,
                      foreground: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 11,
                    child: Icon(
                      Icons.swap_vert_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: _CurrencyDot(
                      symbol: nextSymbol,
                      color: Theme.of(context).colorScheme.primary,
                      foreground: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        current,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CurrencyDot extends StatelessWidget {
  const _CurrencyDot({
    required this.symbol,
    required this.color,
    required this.foreground,
  });

  final String symbol;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Text(
      symbol,
      style: TextStyle(
        color: foreground,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    ),
  );
}
