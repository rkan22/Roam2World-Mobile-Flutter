import 'package:flutter/material.dart';

class AnimatedMetricValue extends StatelessWidget {
  const AnimatedMetricValue({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 950),
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  });

  final String value;
  final TextStyle? style;
  final Duration duration;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  static final RegExp _numberPattern = RegExp(r'-?\d[\d,]*(?:\.\d+)?');

  @override
  Widget build(BuildContext context) {
    final match = _numberPattern.firstMatch(value);
    if (match == null) return _text(value);

    final source = match.group(0)!;
    final target = double.tryParse(source.replaceAll(',', ''));
    if (target == null || !target.isFinite) return _text(value);

    final decimalIndex = source.lastIndexOf('.');
    final decimals = decimalIndex < 0 ? 0 : source.length - decimalIndex - 1;
    final grouped = source.contains(',');
    final prefix = value.substring(0, match.start);
    final suffix = value.substring(match.end);
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) return _text(value);

    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween<double>(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, current, child) {
        final formatted = _format(
          current,
          decimals: decimals,
          grouped: grouped,
        );

        return Text(
          '$prefix$formatted$suffix',
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
          style: style,
        );
      },
    );
  }

  Text _text(String text) => Text(
    text,
    maxLines: maxLines,
    overflow: overflow,
    textAlign: textAlign,
    style: style,
  );

  static String _format(
    double value, {
    required int decimals,
    required bool grouped,
  }) {
    final fixed = value.toStringAsFixed(decimals);
    if (!grouped) return fixed;

    final parts = fixed.split('.');
    final sign = parts.first.startsWith('-') ? '-' : '';
    final digits = parts.first.replaceFirst('-', '');
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }

    final fraction = parts.length > 1 ? '.${parts.last}' : '';
    return '$sign$buffer$fraction';
  }
}
