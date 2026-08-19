import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/packages/package_catalog.dart';
import 'package:roam2world_mobile_flutter/features/packages/packages_repository.dart';
import 'package:roam2world_mobile_flutter/features/pricing/pricing_package_picker.dart';

class _FakePackagesRepository extends PackagesRepository {
  _FakePackagesRepository(this.catalog);

  final PackageCatalog catalog;

  @override
  Future<PackageCatalog> fetchPackages({
    String? search,
    String? destination,
    String? packageType,
    int limit = 250,
    bool forceRefresh = false,
  }) async {
    return catalog;
  }
}

MobilePackage _package({
  required String id,
  required String name,
  required String provider,
  required String destination,
}) {
  return MobilePackage(
    id: id,
    name: name,
    provider: provider,
    displayProvider: provider == 'airhub'
        ? 'Vodafone'
        : provider == 'manual'
        ? 'Manual'
        : 'Orange Balkans',
    destination: destination,
    destinationKey: destination.toLowerCase(),
    dataLabel: '10 GB',
    validityLabel: '30 days',
    price: 25,
    currency: 'USD',
    packageType: 'esim',
    countryCode: 'TR',
    isFeatured: false,
  );
}

void main() {
  late _FakePackagesRepository repository;

  setUp(() {
    repository = _FakePackagesRepository(
      PackageCatalog(
        hasMore: false,
        packages: [
          _package(
            id: 'VODAFONE-TR-10GB',
            name: 'Vodafone Turkey 10GB',
            provider: 'airhub',
            destination: 'Turkey',
          ),
          _package(
            id: 'ORANGE-BALKANS-10GB',
            name: 'Orange Balkans 10GB',
            provider: 'tgt',
            destination: 'Balkans',
          ),
          _package(
            id: 'MANUAL-TR-10GB',
            name: 'Manual Turkey 10GB',
            provider: 'manual',
            destination: 'Turkey',
          ),
        ],
      ),
    );
  });

  testWidgets('shows only packages belonging to selected provider', (
    tester,
  ) async {
    PricingPackageSelection? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                selected = await showPricingPackagePicker(
                  context: context,
                  provider: 'airhub',
                  repository: repository,
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();

    expect(find.text('Vodafone Turkey 10GB'), findsOneWidget);
    expect(find.text('Orange Balkans 10GB'), findsNothing);

    await tester.tap(find.text('Vodafone Turkey 10GB'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.allPackages, isFalse);
    expect(selected!.package!.id, 'VODAFONE-TR-10GB');
  });

  testWidgets('includes manual fulfillment products for any operator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showPricingPackagePicker(
                  context: context,
                  provider: 'airhub',
                  repository: repository,
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();

    expect(find.text('Manual Turkey 10GB'), findsOneWidget);
    expect(find.text('Manual Fulfillment'), findsOneWidget);
  });

  testWidgets('returns all-packages selection', (tester) async {
    PricingPackageSelection? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                selected = await showPricingPackagePicker(
                  context: context,
                  provider: 'airhub',
                  repository: repository,
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All packages'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.allPackages, isTrue);
    expect(selected!.package, isNull);
  });

  testWidgets('searches by package ID and destination', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showPricingPackagePicker(
                  context: context,
                  provider: 'airhub',
                  repository: repository,
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'VODAFONE-TR');
    await tester.pump();

    expect(find.text('Vodafone Turkey 10GB'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Balkans');
    await tester.pump();

    expect(find.text('Vodafone Turkey 10GB'), findsNothing);
  });
}
