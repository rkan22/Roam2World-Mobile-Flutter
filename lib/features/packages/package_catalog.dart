class PackageCatalog {
  const PackageCatalog({required this.packages, required this.hasMore});

  final List<MobilePackage> packages;
  final bool hasMore;

  factory PackageCatalog.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final rawPackages = data['packages'] ?? data['results'] ?? const [];
    final pagination = data['pagination'] is Map
        ? Map<String, dynamic>.from(data['pagination'] as Map)
        : const <String, dynamic>{};

    return PackageCatalog(
      packages: rawPackages is List
          ? rawPackages
                .whereType<Map>()
                .map(
                  (item) =>
                      MobilePackage.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      hasMore: pagination['has_more'] == true || data['has_more'] == true,
    );
  }

  factory PackageCatalog.fromWorldmoveResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final rawPackages = root['packages'] ?? root['data'] ?? const [];
    return PackageCatalog(
      packages: rawPackages is List
          ? rawPackages
                .whereType<Map>()
                .map(
                  (item) =>
                      MobilePackage.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      hasMore: false,
    );
  }

  factory PackageCatalog.fromManualResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final rawPackages = root['data'] ?? const [];
    return PackageCatalog(
      packages: rawPackages is List
          ? rawPackages.whereType<Map>().map((raw) {
              final item = Map<String, dynamic>.from(raw);
              final coverage = item['coverage_countries'];
              final coverageLabel = coverage is List && coverage.isNotEmpty
                  ? coverage.join(', ')
                  : 'Global';
              return MobilePackage.fromJson({
                ...item,
                'id': item['package_id'],
                'provider': 'manual',
                'display_provider': item['operator_name'],
                'name': item['product_name'],
                'package_type': item['product_type'],
                'destination': coverageLabel,
                'price': item['base_price'],
              });
            }).toList()
          : const [],
      hasMore: false,
    );
  }

  factory PackageCatalog.fromProviderResponse(
    dynamic response, {
    required String provider,
    required String displayProvider,
  }) {
    dynamic value = response;
    for (var depth = 0; depth < 2 && value is Map; depth++) {
      value =
          value['data'] ??
          value['results'] ??
          value['packages'] ??
          value['list'] ??
          const [];
    }
    return PackageCatalog(
      packages: value is List
          ? value.whereType<Map>().map((raw) {
              return MobilePackage.fromJson({
                ...Map<String, dynamic>.from(raw),
                'provider': provider,
                'display_provider': displayProvider,
              });
            }).toList()
          : const [],
      hasMore: false,
    );
  }
}

class MobilePackage {
  const MobilePackage({
    required this.id,
    required this.name,
    required this.provider,
    required this.displayProvider,
    required this.destination,
    required this.destinationKey,
    required this.dataLabel,
    required this.validityLabel,
    required this.price,
    required this.currency,
    required this.packageType,
    required this.countryCode,
    required this.isFeatured,
    this.supportedCountries = const [],
  });

  final String id;
  final String name;
  final String provider;
  final String displayProvider;
  final String destination;
  final String destinationKey;
  final String dataLabel;
  final String validityLabel;
  final double price;
  final String currency;
  final String packageType;
  final String countryCode;
  final bool isFeatured;
  final List<PackageCountry> supportedCountries;

  factory MobilePackage.fromJson(Map<String, dynamic> json) {
    final countries = json['countries'];
    final firstCountry =
        countries is List && countries.isNotEmpty && countries.first is Map
        ? Map<String, dynamic>.from(countries.first as Map)
        : const <String, dynamic>{};
    final supportedCountries = _countriesFromJson(json);
    final identityText = [
      json['id'],
      json['wmproductId'],
      json['package_id'],
      json['planCode'],
      json['productCode'],
      json['name'],
      json['package_name'],
      json['productName'],
      json['planName'],
      json['productRegion'],
    ].where((value) => value != null).join(' ');
    final parsedData = _dataFromText(identityText);
    final parsedValidity = _validityFromText(identityText);
    final dataQuantity =
        json['data_quantity'] ??
        json['data_gb'] ??
        json['data'] ??
        json['dataAmount'] ??
        json['dataAllowance'] ??
        json['capacity'] ??
        parsedData;
    final dataUnit = json['data_unit']?.toString() ?? 'GB';
    final validity =
        json['package_validity'] ??
        json['validity_days'] ??
        json['validityDays'] ??
        json['days'] ??
        json['durationDays'] ??
        json['validity'] ??
        parsedValidity;
    final validityUnit = json['package_validity_unit']?.toString() ?? 'Days';
    final rawPrice =
        json['final_price'] ?? json['price'] ?? json['sale_price'] ?? 0;

    return MobilePackage(
      id:
          json['id']?.toString() ??
          json['wmproductId']?.toString() ??
          json['package_id']?.toString() ??
          json['planCode']?.toString() ??
          json['productCode']?.toString() ??
          json['code']?.toString() ??
          '',
      name: _packageName(json, identityText, dataQuantity, validity),
      provider: json['provider']?.toString() ?? '',
      displayProvider: _displayProvider(json, identityText),
      destination:
          json['destination_label']?.toString() ??
          json['coverage_label']?.toString() ??
          json['productRegion']?.toString() ??
          json['destination']?.toString() ??
          firstCountry['name']?.toString() ??
          'Global',
      destinationKey:
          json['destination_key']?.toString() ??
          _destinationKey(json, identityText),
      dataLabel: dataQuantity == null
          ? (json['unlimited'] == true ? 'Unlimited' : 'Data')
          : '$dataQuantity $dataUnit',
      validityLabel: validity == null ? 'Flexible' : '$validity $validityUnit',
      price: double.tryParse(rawPrice.toString()) ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      packageType: _packageType(
        json['package_type'],
        json['is_esim'],
        identityText,
        json['provider'],
      ),
      countryCode: firstCountry['code']?.toString() ?? '',
      isFeatured: json['is_featured'] == true,
      supportedCountries: supportedCountries,
    );
  }

  String get formattedPrice => '$currency ${price.toStringAsFixed(2)}';

  num? get dataGb => num.tryParse(
    RegExp(r'\d+(?:\.\d+)?').firstMatch(dataLabel)?.group(0) ?? '',
  );

  int? get validityDays =>
      int.tryParse(RegExp(r'\d+').firstMatch(validityLabel)?.group(0) ?? '');

  MobilePackage withPrice(double value) => MobilePackage(
    id: id,
    name: name,
    provider: provider,
    displayProvider: displayProvider,
    destination: destination,
    destinationKey: destinationKey,
    dataLabel: dataLabel,
    validityLabel: validityLabel,
    price: value,
    currency: currency,
    packageType: packageType,
    countryCode: countryCode,
    isFeatured: isFeatured,
    supportedCountries: supportedCountries,
  );

  static String _packageName(
    Map<String, dynamic> json,
    String identityText,
    dynamic data,
    dynamic validity,
  ) {
    final provider = json['provider']?.toString().toLowerCase() ?? '';
    if (provider == 'tgt') {
      final code = identityText.toUpperCase();
      final type = code.contains('E-185-SC-') ? 'SIM Card' : 'eSIM';
      final parts = <String>['Orange Balkans', type];
      if (data != null) parts.add('${_cleanNumber(data)}GB');
      if (validity != null) parts.add('${_cleanNumber(validity)} Days');
      return parts.join(' ');
    }
    return json['name']?.toString() ??
        json['package_name']?.toString() ??
        json['productName']?.toString() ??
        json['planName']?.toString() ??
        json['title']?.toString() ??
        'eSIM package';
  }

  static String _cleanNumber(dynamic value) {
    final parsed = num.tryParse('$value');
    return parsed == null
        ? '$value'
        : parsed == parsed.roundToDouble()
        ? '${parsed.toInt()}'
        : '$parsed';
  }

  static List<PackageCountry> _countriesFromJson(Map<String, dynamic> json) {
    final raw =
        json['supported_countries'] ??
        json['supportedCountries'] ??
        json['coverage_countries'] ??
        json['coverageCountries'] ??
        json['country_list'] ??
        json['countryList'] ??
        json['countries'] ??
        const [];
    if (raw is! List) return const [];
    return raw
        .map((item) {
          if (item is Map) {
            final value = Map<String, dynamic>.from(item);
            return PackageCountry(
              name:
                  '${value['name'] ?? value['country_name'] ?? value['country'] ?? value['code'] ?? ''}',
              code:
                  '${value['code'] ?? value['country_code'] ?? value['iso2'] ?? ''}'
                      .toUpperCase(),
            );
          }
          final text = '$item'.trim();
          return PackageCountry(
            name: text,
            code: text.length == 2 ? text.toUpperCase() : '',
          );
        })
        .where((item) => item.name.isNotEmpty)
        .toList(growable: false);
  }

  String get operatorKey {
    final code = id.toUpperCase();
    if (provider.toLowerCase() == 'worldmove') {
      if (code.startsWith('WM-EU-B-')) return 'kpn';
      if (code.startsWith('WM-TR-')) return 'turkey';
      if (code.startsWith('WM-E-J1-WLD-')) return 'orange-world';
      if (code.contains('VDF') || code.contains('VODAFONE')) return 'vodafone';
      if (code.startsWith('WM-E-J1-O-')) return 'worldmove';
    }
    final label = displayProvider.toLowerCase();
    if (label.contains('vodafone') ||
        provider.toLowerCase().contains('airhub')) {
      return 'vodafone';
    }
    if (label.contains('big data') || provider.toLowerCase() == 'flexnet') {
      return 'flexnet';
    }
    if (label.contains('balkan') || provider.toLowerCase() == 'tgt') {
      return 'orange-balkans';
    }
    return provider.toLowerCase();
  }

  static num? _dataFromText(String text) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*GB',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) return num.tryParse(match.group(1)!);
    const fallbacks = {
      'WM-E-J1-VDFES-M': 25,
      'WM-E-J1-VDFES-XL': 45,
      'WM-E-J1-VDFES-XXL': 60,
      'WM-E-J1-WLD-O-14D': 20,
      'WM-E-J1-WLD-O-MINI-30D': 3,
    };
    for (final entry in fallbacks.entries) {
      if (text.toUpperCase().contains(entry.key)) return entry.value;
    }
    return null;
  }

  static int? _validityFromText(String text) {
    final match = RegExp(
      r'(\d+)\s*(?:D|DAY|DAYS)(?:\b|/)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) return int.tryParse(match.group(1)!);
    if (text.toUpperCase().contains('WM-E-J1-VDFES-')) return 30;
    return null;
  }

  static String _destinationKey(Map<String, dynamic> json, String text) {
    final normalized =
        '${json['productRegion'] ?? ''} '
                '${json['destination'] ?? ''} $text'
            .toLowerCase();
    if (normalized.contains('wm-tr-') ||
        normalized.contains('turkey') ||
        normalized.contains('turkiye')) {
      return 'turkey';
    }
    if (normalized.contains('wm-e-j1-wld-') ||
        normalized.contains('global') ||
        normalized.contains('world')) {
      return 'global';
    }
    if (normalized.contains('wm-eu-b-') ||
        normalized.contains('wm-e-j1-') ||
        normalized.contains('europe')) {
      return 'europe';
    }
    return '';
  }

  static String _packageType(
    dynamic value,
    dynamic isEsim,
    String identityText,
    dynamic provider,
  ) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    final code = identityText.toUpperCase();
    if (isEsim == false ||
        normalized == 'sim' ||
        normalized == 'simcard' ||
        normalized == 'physical_sim' ||
        (provider?.toString().toLowerCase() == 'worldmove' &&
            code.startsWith('WM-EU-B-')) ||
        (provider?.toString().toLowerCase() == 'tgt' &&
            code.contains('E-185-SC-'))) {
      return 'simcard';
    }
    return 'esim';
  }

  static String _displayProvider(Map<String, dynamic> json, String text) {
    if ((json['provider']?.toString().toLowerCase() ?? '') == 'worldmove') {
      final code = text.toUpperCase();
      if (code.startsWith('WM-EU-B-')) return 'KPN Europe';
      if (code.startsWith('WM-TR-')) return 'T.T Turkey';
      if (code.startsWith('WM-E-J1-WLD-')) return 'Orange World';
      if (code.contains('VDF') || code.contains('VODAFONE')) return 'Vodafone';
      if (code.startsWith('WM-E-J1-O-')) return 'Orange Europe';
    }
    return json['display_provider']?.toString() ??
        json['provider_label']?.toString() ??
        json['provider']?.toString() ??
        'Roam2World';
  }
}

class PackageCountry {
  const PackageCountry({required this.name, required this.code});

  final String name;
  final String code;
}
