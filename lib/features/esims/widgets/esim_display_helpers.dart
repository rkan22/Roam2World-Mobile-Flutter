String esimDisplayPackageName(String rawName) {
  var name = rawName
      .replaceAll(RegExp(r'\[\s*esim\s*\]', caseSensitive: false), '')
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (name.isEmpty) return 'eSIM package';

  const providerPrefixes = <String>[
    'Orange Big Data',
    'Orange Balkans',
    'Orange Europe',
    'Orange World',
    'T.T Turkey',
    'KPN Europe',
    'Roam2World',
    'Worldmove',
    'Vodafone',
    'Flexnet',
    'Airhub',
    'Movistar',
    'TGT',
  ];

  for (final prefix in providerPrefixes) {
    name = name.replaceFirst(
      RegExp(
        '^${RegExp.escape(prefix)}(?:\\s*[-–—|:]\\s*|\\s+)',
        caseSensitive: false,
      ),
      '',
    );
  }

  name = name.replaceFirst(
    RegExp(
      r'^[A-Z0-9]{2,}(?:-[A-Z0-9]{2,}){2,}\s*[-–—|:]*\s*',
      caseSensitive: false,
    ),
    '',
  );

  name = name
      .replaceAll(RegExp(r'\s*/\s*'), ' · ')
      .replaceAll(RegExp(r'\s+[·]\s+'), ' · ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  name = name.replaceAllMapped(
    RegExp(r'(\d+(?:\.\d+)?)\s*(GB|MB|TB)\b', caseSensitive: false),
    (match) => '${match.group(1)} ${match.group(2)!.toUpperCase()}',
  );

  name = name.replaceAllMapped(
    RegExp(r'(\d+)\s*(days?|d)\b', caseSensitive: false),
    (match) => '${match.group(1)} Days',
  );

  return name.isEmpty ? 'eSIM package' : name;
}

String esimDisplayStatus(String rawStatus) {
  final normalized = rawStatus
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  return switch (normalized) {
    'ready' || 'ready to install' || 'qr ready' => 'Ready to install',
    'active' || 'activated' => 'Active',
    'installed' => 'Installed',
    'expired' => 'Expired',
    'pending' || 'processing' || 'provisioning' => 'Provisioning',
    'notactive' || 'not active' => 'Not active',
    'unknown' || '' => 'Pending',
    _ =>
      normalized
          .split(' ')
          .map(
            (word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1)}',
          )
          .join(' '),
  };
}
