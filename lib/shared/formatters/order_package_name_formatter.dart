String simplifyOrderPackageName(String value) {
  final raw = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (raw.isEmpty) return 'Package order';

  final data = RegExp(
    r'\b(\d+(?:\.\d+)?)\s*(GB|MB)\b',
    caseSensitive: false,
  ).firstMatch(raw);
  final days = RegExp(
    r'\b(\d{1,3})\s*(?:days?|d)\b',
    caseSensitive: false,
  ).firstMatch(raw);
  final region = RegExp(
    r'\b(Turkey|Türkiye|Turkiye|Europe|Balkans|Global|Asia|America|Spain|France|Italy|Germany)\b',
    caseSensitive: false,
  ).firstMatch(raw)?.group(1);

  if (data != null || days != null) {
    return <String>[
      if (region != null) _normalizeRegion(region),
      if (data != null) '${data.group(1)}${data.group(2)!.toUpperCase()}',
      if (days != null) '${days.group(1)} Days',
    ].join(' · ');
  }

  final simplified = raw
      .replaceFirst(
        RegExp(r'^\s*\[(?:e)?sim\]\s*', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'\((?:e0?\d+|[^)]*countries[^)]*)\)', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(
          r'\b(?:eSIM|SIM Card|data-only|business(?:\s+pro)?(?:\s+plan)?|travel)\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'[|·_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return simplified.isEmpty ? 'Package order' : simplified;
}

String _normalizeRegion(String value) {
  final normalized = value.toLowerCase();
  if (normalized == 'turkiye' || normalized == 'türkiye') return 'Turkey';
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}
