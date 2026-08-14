class PackageCatalog {
  const PackageCatalog({required this.packages, required this.hasMore});
  final List<MobilePackage> packages;
  final bool hasMore;

  factory PackageCatalog.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map ? Map<String, dynamic>.from(root['data']) : root;
    final raw = data['packages'] ?? data['results'] ?? data['items'] ?? const [];
    final pagination = data['pagination'];
    return PackageCatalog(
      packages: _parseList(raw),
      hasMore: (pagination is Map && pagination['has_more'] == true) || data['has_more'] == true,
    );
  }

  factory PackageCatalog.fromWorldmoveResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final nested = root['data'];
    final raw = root['packages'] ??
        (nested is Map ? nested['packages'] ?? nested['results'] ?? nested['items'] : nested) ??
        root['results'] ?? root['items'] ?? const [];
    return PackageCatalog(packages: _parseList(raw), hasMore: false);
  }

  factory PackageCatalog.fromManualResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final raw = root['data'] ?? root['products'] ?? root['results'] ?? const [];
    if (raw is! List) return const PackageCatalog(packages: [], hasMore: false);
    return PackageCatalog(
      packages: raw.whereType<Map>().map((rawItem) {
        final item = Map<String, dynamic>.from(rawItem);
        final coverage = item['coverage_countries'] ?? item['coverageCountries'] ?? const [];
        return MobilePackage.fromJson({
          ...item,
          'id': item['package_id'] ?? item['id'],
          'provider': 'manual',
          'display_provider': item['operator_name'] ?? item['operator'],
          'name': item['product_name'] ?? item['name'],
          'package_type': item['product_type'] ?? item['package_type'],
          'destination': item['destination'] ?? (coverage is List && coverage.isNotEmpty ? coverage.join(', ') : 'Global'),
          'price': item['base_price'] ?? item['price'],
        });
      }).toList(growable: false),
      hasMore: false,
    );
  }

  factory PackageCatalog.fromProviderResponse(dynamic response, {required String provider, required String displayProvider}) {
    dynamic value = response;
    for (var i = 0; i < 3 && value is Map; i++) {
      value = value['data'] ?? value['results'] ?? value['packages'] ?? value['plans'] ?? value['list'] ?? value['items'] ?? const [];
    }
    return PackageCatalog(
      packages: value is List
          ? value.whereType<Map>().map((raw) => MobilePackage.fromJson({...Map<String, dynamic>.from(raw), 'provider': provider, 'display_provider': displayProvider})).toList(growable: false)
          : const [],
      hasMore: false,
    );
  }
}

List<MobilePackage> _parseList(dynamic raw) => raw is List
    ? raw.whereType<Map>().map((item) => MobilePackage.fromJson(Map<String, dynamic>.from(item))).toList(growable: false)
    : const [];

class MobilePackage {
  const MobilePackage({
    required this.id, required this.name, required this.provider, required this.displayProvider,
    required this.destination, required this.destinationKey, required this.dataLabel, required this.validityLabel,
    required this.price, required this.currency, required this.packageType, required this.countryCode,
    required this.isFeatured, this.description = '', this.supportedCountries = const [],
  });

  final String id, name, provider, displayProvider, destination, destinationKey, dataLabel, validityLabel, currency, packageType, countryCode, description;
  final double price;
  final bool isFeatured;
  final List<PackageCountry> supportedCountries;

  factory MobilePackage.fromJson(Map<String, dynamic> json) {
    final provider = _text(json, ['provider', 'source_provider']);
    final identity = _identity(json);
    final wmCode = _worldmoveCode(json);
    final countries = _countries(json);
    final first = countries.isNotEmpty ? countries.first : const PackageCountry(name: '', code: '');
    final data = _first([json['data_quantity'], json['data_gb'], json['data'], json['dataAmount'], json['dataAllowance'], json['data_allowance'], json['capacity'], _dataFromText(identity)]);
    final validity = _first([json['package_validity'], json['validity_days'], json['validityDays'], json['days'], json['durationDays'], json['validity'], _validityFromText(identity)]);
    final price = double.tryParse('${_first([json['final_price'], json['finalPrice'], json['price'], json['sale_price'], json['salePrice'], json['reseller_price'], json['resellerPrice'], 0])}') ?? 0;
    return MobilePackage(
      id: provider.toLowerCase() == 'worldmove' && wmCode.isNotEmpty ? wmCode : _text(json, ['id', 'package_id', 'planCode', 'productCode', 'product_code', 'code', 'sku']),
      name: _name(json, identity, wmCode, data, validity),
      provider: provider,
      displayProvider: _display(json, identity, wmCode),
      destination: _text(json, ['destination_label', 'coverage_label', 'productRegion', 'destination', 'region']).isNotEmpty ? _text(json, ['destination_label', 'coverage_label', 'productRegion', 'destination', 'region']) : (first.name.isNotEmpty ? first.name : 'Global'),
      destinationKey: _text(json, ['destination_key']).isNotEmpty ? _text(json, ['destination_key']).toLowerCase() : _destination(json, identity),
      dataLabel: data == null ? (json['unlimited'] == true ? 'Unlimited' : 'Data') : '${_clean(data)} ${_text(json, ['data_unit']).isNotEmpty ? _text(json, ['data_unit']) : 'GB'}',
      validityLabel: validity == null ? 'Flexible' : '${_clean(validity)} ${_text(json, ['package_validity_unit']).isNotEmpty ? _text(json, ['package_validity_unit']) : 'Days'}',
      price: price,
      currency: _text(json, ['currency']).isNotEmpty ? _text(json, ['currency']) : 'USD',
      packageType: _type(json, identity, provider),
      countryCode: first.code,
      isFeatured: json['is_featured'] == true || json['isFeatured'] == true,
      description: _description(json),
      supportedCountries: countries,
    );
  }

  String get formattedPrice => '$currency ${price.toStringAsFixed(2)}';
  num? get dataGb => num.tryParse(RegExp(r'\d+(?:\.\d+)?').firstMatch(dataLabel)?.group(0) ?? '');
  int? get validityDays => int.tryParse(RegExp(r'\d+').firstMatch(validityLabel)?.group(0) ?? '');

  MobilePackage withPrice(double value) => MobilePackage(
    id: id, name: name, provider: provider, displayProvider: displayProvider,
    destination: destination, destinationKey: destinationKey, dataLabel: dataLabel, validityLabel: validityLabel,
    price: value, currency: currency, packageType: packageType, countryCode: countryCode, isFeatured: isFeatured,
    description: description, supportedCountries: supportedCountries,
  );

  String get operatorKey {
    final p = provider.toLowerCase(), label = displayProvider.toLowerCase(), code = id.toUpperCase();
    if (p == 'worldmove') {
      if (code.startsWith('WM-EU-B-')) return 'kpn';
      if (code.startsWith('WM-TR-')) return 'turkey';
      if (code.startsWith('WM-E-J1-WLD-')) return 'orange-world';
      if (code.startsWith('WM-E-J1-VDFES-')) return 'vodafone';
      if (code.startsWith('WM-E-J1-O-')) return 'worldmove';
      return 'worldmove';
    }

    if (p == 'tgt') return 'orange-balkans';
    if (p == 'flexnet') return 'flexnet';
    if (p.contains('airhub')) return 'vodafone';
    if (p == 'manual') return 'manual';

    if (label.contains('movistar')) return 'movistar';
    if (label.contains('kpn')) return 'kpn';
    if (label.contains('orange') && label.contains('europe')) return 'worldmove';
    if (label.contains('orange') && label.contains('world')) return 'orange-world';
    if (label.contains('orange') && label.contains('balkan')) return 'orange-balkans';
    if (label.contains('vodafone')) return 'vodafone';
    if (label.contains('big data')) return 'flexnet';
    if (label.contains('balkan')) return 'orange-balkans';
    return p;
  }

  static String _name(Map<String, dynamic> j, String identity, String wmCode, dynamic data, dynamic validity) {
    final p = _text(j, ['provider']).toLowerCase();
    if (p == 'worldmove') {
      final code = wmCode.isNotEmpty ? wmCode : identity.toUpperCase();
      final operator = code.startsWith('WM-EU-B-')
          ? 'KPN Europe'
          : code.startsWith('WM-TR-')
              ? 'Turkey'
              : code.startsWith('WM-E-J1-WLD-')
                  ? 'Orange World'
                  : code.startsWith('WM-E-J1-VDFES-')
                      ? 'Vodafone'
                      : code.startsWith('WM-E-J1-O-')
                          ? 'Orange Europe'
                          : 'Worldmove';
      final parts = <String>[operator];
      if (data != null) parts.add('${_clean(data)}GB');
      if (validity != null) parts.add('${_clean(validity)} Days');
      return parts.join(' ');
    }
    if (p == 'tgt') {
      final parts = <String>['Orange Balkans', identity.toUpperCase().contains('E-185-SC-') ? 'SIM Card' : 'eSIM'];
      if (data != null) parts.add('${_clean(data)}GB');
      if (validity != null) parts.add('${_clean(validity)} Days');
      return parts.join(' ');
    }
    final value = _text(j, ['name', 'package_name', 'productName', 'product_name', 'planName', 'title']);
    return value.isEmpty ? 'eSIM package' : value;
  }

  static String _display(Map<String, dynamic> j, String identity, String wmCode) {
    if (_text(j, ['provider']).toLowerCase() == 'worldmove') {
      final c = wmCode.isNotEmpty ? wmCode : identity.toUpperCase();
      if (c.startsWith('WM-EU-B-')) return 'KPN Europe';
      if (c.startsWith('WM-TR-')) return 'T.T Turkey';
      if (c.startsWith('WM-E-J1-WLD-')) return 'Orange World';
      if (c.startsWith('WM-E-J1-VDFES-')) return 'Vodafone';
      if (c.startsWith('WM-E-J1-O-')) return 'Orange Europe';
      return 'Worldmove';
    }
    final value = _text(j, ['display_provider', 'provider_label', 'operator_name', 'provider']);
    return value.isEmpty ? 'Roam2World' : value;
  }

  static String _destination(Map<String, dynamic> j, String text) {
    final n = '${j['productRegion'] ?? ''} ${j['destination'] ?? ''} $text'.toLowerCase();
    if (n.contains('wm-tr-') || n.contains('turkey') || n.contains('turkiye')) return 'turkey';
    if (n.contains('wm-e-j1-wld-') || n.contains('global') || n.contains('world')) return 'global';
    if (n.contains('wm-eu-b-') || n.contains('wm-e-j1-') || n.contains('europe')) return 'europe';
    return '';
  }

  static String _type(Map<String, dynamic> j, String identity, String provider) {
    final value = _text(j, ['package_type', 'packageType', 'product_type']).toLowerCase();
    final code = identity.toUpperCase();
    if (j['is_esim'] == false || value == 'sim' || value == 'simcard' || value == 'physical_sim' ||
        (provider.toLowerCase() == 'worldmove' && code.startsWith('WM-EU-B-')) ||
        (provider.toLowerCase() == 'tgt' && code.contains('E-185-SC-'))) {
      return 'simcard';
    }
    return 'esim';
  }

  static List<PackageCountry> _countries(Map<String, dynamic> j) {
    final values = <dynamic>[
      j['supported_countries'],
      j['supportedCountries'],
      j['coverage_countries'],
      j['coverageCountries'],
      j['country_list'],
      j['countryList'],
      j['country_codes'],
      j['countryCodes'],
      j['countries'],
      j['coverage'],
      j['country'],
    ];

    final result = <PackageCountry>[];
    final seen = <String>{};
    for (final value in values) {
      for (final item in _flattenCoverage(value)) {
        final country = _countryFromCoverage(item);
        if (country == null) continue;
        final key = country.code.isNotEmpty ? country.code : country.name.toLowerCase();
        if (seen.add(key)) result.add(country);
      }
    }

    final identity = _identity(j).toUpperCase();
    if (identity.startsWith('WM-TR-') && seen.add('TR')) {
      result.add(const PackageCountry(name: 'Turkey', code: 'TR'));
    }

    if (identity.startsWith('WM-E-J1-VDFES-')) {
      for (final country in const [
        PackageCountry(name: 'Europe', code: 'EU'),
        PackageCountry(name: 'United States', code: 'US'),
        PackageCountry(name: 'United Kingdom', code: 'GB'),
        PackageCountry(name: 'Turkey', code: 'TR'),
      ]) {
        if (seen.add(country.code)) result.add(country);
      }
    }

    return result;
  }

  static String _description(Map<String, dynamic> j) {
    for (final key in const ['description', 'package_description', 'plan_description', 'product_description', 'short_description']) {
      final text = j[key]?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class PackageCountry {
  const PackageCountry({required this.name, required this.code});
  final String name, code;
}

Iterable<dynamic> _flattenCoverage(dynamic value) sync* {
  if (value == null) return;
  if (value is List) {
    for (final item in value) {
      yield* _flattenCoverage(item);
    }
    return;
  }
  if (value is Map) {
    yield value;
    return;
  }
  final text = '$value'.trim();
  if (text.isEmpty) return;
  for (final token in text.split(RegExp(r'[,;/|]'))) {
    final trimmed = token.trim();
    if (trimmed.isNotEmpty) yield trimmed;
  }
}

PackageCountry? _countryFromCoverage(dynamic item) {
  if (item is Map) {
    final m = Map<String, dynamic>.from(item);
    final rawCode = '${m['code'] ?? m['country_code'] ?? m['iso2'] ?? m['countryCode'] ?? ''}'.trim().toUpperCase();
    final rawName = '${m['name'] ?? m['country_name'] ?? m['country'] ?? m['countryName'] ?? rawCode}'.trim();
    final code = rawCode.isNotEmpty ? rawCode : _countryCode(rawName);
    if (code.isEmpty && rawName.isEmpty) return null;
    return PackageCountry(name: rawName.isEmpty || rawName.length == 2 ? _countryName(code) : rawName, code: code);
  }

  final text = '$item'.trim();
  if (text.isEmpty) return null;
  final code = text.length == 2 ? text.toUpperCase() : _countryCode(text);
  if (code.isEmpty) return null;
  return PackageCountry(name: _countryName(code), code: code);
}

String _countryCode(String name) {
  final normalized = name.trim().toLowerCase();
  return const {
        'austria': 'AT',
        'belgium': 'BE',
        'bulgaria': 'BG',
        'switzerland': 'CH',
        'cyprus': 'CY',
        'czechia': 'CZ',
        'czech republic': 'CZ',
        'germany': 'DE',
        'denmark': 'DK',
        'estonia': 'EE',
        'spain': 'ES',
        'finland': 'FI',
        'france': 'FR',
        'united kingdom': 'GB',
        'uk': 'GB',
        'greece': 'GR',
        'croatia': 'HR',
        'hungary': 'HU',
        'ireland': 'IE',
        'iceland': 'IS',
        'italy': 'IT',
        'lithuania': 'LT',
        'luxembourg': 'LU',
        'latvia': 'LV',
        'malta': 'MT',
        'netherlands': 'NL',
        'norway': 'NO',
        'poland': 'PL',
        'portugal': 'PT',
        'romania': 'RO',
        'serbia': 'RS',
        'sweden': 'SE',
        'slovenia': 'SI',
        'slovakia': 'SK',
        'turkey': 'TR',
        'turkiye': 'TR',
        'türkiye': 'TR',
        'ukraine': 'UA',
        'united states': 'US',
        'usa': 'US',
        'canada': 'CA',
        'mexico': 'MX',
        'brazil': 'BR',
        'australia': 'AU',
        'new zealand': 'NZ',
        'japan': 'JP',
        'united arab emirates': 'AE',
        'saudi arabia': 'SA',
        'europe': 'EU',
      }[normalized] ??
      '';
}

String _worldmoveCode(Map<String, dynamic> j) => _text(j, ['wmproductId', 'wmproduct_id', 'wmProductId', 'productCode', 'product_code', 'code', 'sku', 'id']).toUpperCase();

String _identity(Map<String, dynamic> j) => [
  j['id'], j['wmproductId'], j['wmproduct_id'], j['wmProductId'], j['package_id'],
  j['planCode'], j['productCode'], j['product_code'], j['code'], j['sku'],
  j['name'], j['package_name'], j['productName'], j['product_name'], j['planName'],
  j['productRegion'], j['operator_name'], j['operator'],
].where((v) => v != null && '$v'.trim().isNotEmpty).join(' ');

String _text(Map<String, dynamic> j, List<String> keys) {
  for (final key in keys) {
    final v = j[key];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
  }
  return '';
}

dynamic _first(List<dynamic> values) {
  for (final v in values) {
    if (v != null && v.toString().trim().isNotEmpty) return v;
  }
  return null;
}

String _clean(dynamic v) {
  final n = num.tryParse('$v');
  if (n == null) return '$v';
  return n == n.roundToDouble() ? '${n.toInt()}' : '$n';
}

num? _dataFromText(String text) {
  final match = RegExp(r'(\d+(?:\.\d+)?)\s*GB', caseSensitive: false).firstMatch(text);
  if (match != null) return num.tryParse(match.group(1)!);
  const fallbacks = {
    'WM-E-J1-VDFES-M': 25,
    'WM-E-J1-VDFES-XL': 45,
    'WM-E-J1-VDFES-XXL': 60,
    'WM-E-J1-WLD-O-14D': 20,
    'WM-E-J1-WLD-O-MINI-30D': 3,
  };
  for (final e in fallbacks.entries) {
    if (text.toUpperCase().contains(e.key)) return e.value;
  }
  return null;
}

int? _validityFromText(String text) {
  final match = RegExp(r'(\d+)\s*(?:D|DAY|DAYS)(?:\b|/)', caseSensitive: false).firstMatch(text);
  if (match != null) return int.tryParse(match.group(1)!);
  if (text.toUpperCase().contains('WM-E-J1-VDFES-')) return 30;
  return null;
}

String _countryName(String code) =>
    const {
      'AT': 'Austria',
      'BE': 'Belgium',
      'BG': 'Bulgaria',
      'CH': 'Switzerland',
      'CY': 'Cyprus',
      'CZ': 'Czechia',
      'DE': 'Germany',
      'DK': 'Denmark',
      'EE': 'Estonia',
      'ES': 'Spain',
      'FI': 'Finland',
      'FR': 'France',
      'GB': 'United Kingdom',
      'GR': 'Greece',
      'HR': 'Croatia',
      'HU': 'Hungary',
      'IE': 'Ireland',
      'IS': 'Iceland',
      'IT': 'Italy',
      'LT': 'Lithuania',
      'LU': 'Luxembourg',
      'LV': 'Latvia',
      'MT': 'Malta',
      'NL': 'Netherlands',
      'NO': 'Norway',
      'PL': 'Poland',
      'PT': 'Portugal',
      'RO': 'Romania',
      'RS': 'Serbia',
      'SE': 'Sweden',
      'SI': 'Slovenia',
      'SK': 'Slovakia',
      'TR': 'Turkey',
      'UA': 'Ukraine',
      'US': 'United States',
      'CA': 'Canada',
      'MX': 'Mexico',
      'BR': 'Brazil',
      'AU': 'Australia',
      'NZ': 'New Zealand',
      'JP': 'Japan',
      'AE': 'United Arab Emirates',
      'SA': 'Saudi Arabia',
      'EU': 'Europe',
    }[code] ?? code;
