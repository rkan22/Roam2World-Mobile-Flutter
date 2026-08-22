import 'package:flutter/material.dart';

class NeonSplashOverlay extends StatefulWidget {
  const NeonSplashOverlay({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<NeonSplashOverlay> createState() => _NeonSplashOverlayState();
}

class _NeonSplashOverlayState extends State<NeonSplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _glow;
  late final Animation<double> _screenOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.42, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.58, curve: Curves.easeOutBack),
      ),
    );

    _glow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 48),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.45), weight: 27),
      TweenSequenceItem(tween: Tween(begin: 0.45, end: 0.8), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _screenOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1), weight: 82),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 18),
    ]).animate(_controller);

    _controller.forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final glow = _glow.value;

            return Opacity(
              opacity: _screenOpacity.value,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  gradient: RadialGradient(
                    center: Alignment(0, -0.08),
                    radius: 0.85,
                    colors: [
                      Color(0xFF12365A),
                      Color(0xFF0F213B),
                      Color(0xFF0F172A),
                    ],
                    stops: [0, 0.48, 1],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 290 + (glow * 30),
                      height: 112 + (glow * 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00C8FF,
                            ).withValues(alpha: 0.20 * glow),
                            blurRadius: 70 * glow,
                            spreadRadius: 12 * glow,
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.18 * glow),
                            blurRadius: 100 * glow,
                            spreadRadius: 20 * glow,
                          ),
                        ],
                      ),
                    ),
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset(
                          'assets/branding/roam2world_logo_transparent.png',
                          width: 300,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: MediaQuery.sizeOf(context).height * 0.20,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: const Text(
                          'GLOBAL CONNECTIVITY',
                          style: TextStyle(
                            color: Color(0xFF8BDFFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
