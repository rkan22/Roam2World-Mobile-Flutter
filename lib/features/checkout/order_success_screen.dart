import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../orders/order_result.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.result});

  final MobileOrderResult result;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _successScale;
  late final Animation<Offset> _contentOffset;
  bool _started = false;

  MobileOrderResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.12, .72, curve: Curves.easeOutCubic),
    );
    _successScale = Tween<double>(begin: .35, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, .48, curve: Curves.easeOutBack),
      ),
    );
    _contentOffset =
        Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(.12, .82, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasInstall =
        result.installAvailable ||
        (result.qrCode?.isNotEmpty ?? false) ||
        (result.activationCode?.isNotEmpty ?? false);

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          key: const Key('success-content'),
          opacity: _contentOpacity,
          child: SlideTransition(
            position: _contentOffset,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                B2BSpacing.lg,
                B2BSpacing.xl,
                B2BSpacing.lg,
                B2BSpacing.xxl,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(B2BSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: B2BGradients.primary,
                    borderRadius: BorderRadius.circular(B2BRadius.xl),
                    boxShadow: B2BShadows.hero,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        key: const Key('success-celebration'),
                        width: 150,
                        height: 112,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _CelebrationPainter(_controller),
                                ),
                              ),
                            ),
                            ScaleTransition(
                              key: const Key('success-check-scale'),
                              scale: _successScale,
                              child: Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .14),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: .18,
                                      ),
                                      blurRadius: 28,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: B2BSpacing.lg),
                      const Text(
                        'Order completed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: B2BSpacing.xs),
                      Text(
                        hasInstall
                            ? 'Your eSIM is ready. Installation details are available now.'
                            : 'Your order is confirmed. Installation details will appear after provisioning.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: B2BSpacing.lg),
                B2BSurface(
                  padding: const EdgeInsets.all(B2BSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.successSoft,
                              borderRadius: BorderRadius.circular(B2BRadius.md),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: B2BSpacing.sm),
                          Expanded(
                            child: Text(
                              'Order summary',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          _StatusChip(status: result.status),
                        ],
                      ),
                      const SizedBox(height: B2BSpacing.md),
                      const Divider(height: 1),
                      const SizedBox(height: B2BSpacing.xs),
                      _SuccessRow(
                        label: 'Order ID',
                        value: result.orderNumber.isNotEmpty
                            ? result.orderNumber
                            : result.orderId,
                      ),
                      _SuccessRow(label: 'Package', value: result.packageName),
                      _SuccessRow(
                        label: 'Customer',
                        value: result.customerName.isEmpty
                            ? 'Direct customer'
                            : result.customerName,
                      ),
                      _SuccessRow(
                        label: 'Total',
                        value: result.formattedTotal,
                        last: true,
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: B2BSpacing.lg),
                B2BSurface(
                  showShadow: false,
                  backgroundColor: hasInstall
                      ? AppColors.primaryLight
                      : AppColors.warningSoft,
                  borderColor: hasInstall
                      ? AppColors.primary.withValues(alpha: .18)
                      : AppColors.warning.withValues(alpha: .28),
                  child: Row(
                    children: [
                      Icon(
                        hasInstall
                            ? Icons.install_mobile_rounded
                            : Icons.hourglass_top_rounded,
                        color: hasInstall
                            ? AppColors.primary
                            : AppColors.warning,
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(
                        child: Text(
                          hasInstall
                              ? 'Installation is ready for this order.'
                              : 'Provisioning is still in progress.',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: B2BSpacing.xl),
                if (result.esimId != null || hasInstall)
                  FilledButton.icon(
                    onPressed: () => context.go('/esims'),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('View eSIM & installation'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => context.go('/orders'),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View order'),
                  ),
                const SizedBox(height: B2BSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => context.go('/packages'),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Buy another package'),
                ),
                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Back to dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _colors = [
    Color(0xFF22D0F7),
    Color(0xFFFFFFFF),
    Color(0xFF7DD3FC),
    Color(0xFFFBBF24),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final raw = ((animation.value - .06) / .72).clamp(0.0, 1.0);
    if (raw <= 0) return;

    final progress = Curves.easeOutCubic.transform(raw);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final center = size.center(Offset.zero);

    for (var index = 0; index < 14; index++) {
      final angle = (-math.pi / 2) + (math.pi * 2 * index / 14);
      final distance = 28 + (58 * progress) + ((index % 3) * 4);
      final position =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      final paint = Paint()
        ..color = _colors[index % _colors.length].withValues(
          alpha: opacity * .92,
        );

      if (index.isEven) {
        canvas.drawCircle(position, 2.8, paint);
      } else {
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(angle);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -1.5, 6, 3),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color =
        normalized.contains('complete') || normalized.contains('success')
        ? AppColors.success
        : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(B2BRadius.pill),
      ),
      child: Text(
        status.isEmpty ? 'Confirmed' : status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({
    required this.label,
    required this.value,
    this.last = false,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool last;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: last
          ? null
          : Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
    ),
    child: Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: emphasized ? 17 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}
