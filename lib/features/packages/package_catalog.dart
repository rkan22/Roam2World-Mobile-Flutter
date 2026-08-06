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
              .map((item) => MobilePackage.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      hasMore: pagination['has_more'] == true || data['has_more'] == true,
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

  factory MobilePackage.fromJson(Map<String, dynamic> json) {
    final countries = json['countries'];
    final firstCountry = countries is List && countries.isNotEmpty && countries.first is Map
        ? Map<String, dynamic>.from(countries.first as Map)
        : const <String, dynamic>{};
    final dataQuantity = json['data_quantity'] ?? json['data_gb'] ?? json['data'];
    final dataUnit = json['data_unit']?.toString() ?? 'GB';
    final validity = json['package_validity'] ?? json['validity_days'] ?? json['validity'];
    final validityUnit = json['package_validity_unit']?.toString() ?? 'Days';
    final rawPrice = json['final_price'] ?? json['price'] ?? json['sale_price'] ?? 0;

    return MobilePackage(
      id: json['id']?.toString() ?? json['package_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'eSIM package',
      provider: json['provider']?.toString() ?? '',
      displayProvider: json['display_provider']?.toString() ??
          json['provider_label']?.toString() ??
          json['provider']?.toString() ??
          'Roam2World',
      destination: json['destination_label']?.toString() ??
          json['coverage_label']?.toString() ??
          firstCountry['name']?.toString() ??
          'Global',
      destinationKey: json['destination_key']?.toString() ?? '',
      dataLabel: dataQuantity == null
          ? (json['unlimited'] == true ? 'Unlimited' : 'Data')
          : '$dataQuantity $dataUnit',
      validityLabel: validity == null ? 'Flexible' : '$validity $validityUnit',
      price: double.tryParse(rawPrice.toString()) ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      packageType: json['package_type']?.toString() ?? 'DATA-ONLY',
      countryCode: firstCountry['code']?.toString() ?? '',
      isFeatured: json['is_featured'] == true,
    );
  }

  String get formattedPrice => '$currency ${price.toStringAsFixed(2)}';
}
