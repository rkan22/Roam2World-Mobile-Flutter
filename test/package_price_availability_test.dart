import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/routing/app_role.dart';
import 'package:roam2world_mobile_flutter/features/packages/package_catalog.dart';
import 'package:roam2world_mobile_flutter/features/packages/package_detail_screen.dart';

MobilePackage _package({required double price}) {
  return MobilePackage(
    id: 'TEST-PACKAGE',
    name: 'Test package',
    provider: 'airhub',
    displayProvider: 'Vodafone',
    destination: 'Türkiye',
    destinationKey: 'turkey',
    dataLabel: '10 GB',
    validityLabel: '30 Days',
    price: price,
    currency: 'USD',
    packageType: 'esim',
    countryCode: 'TR',
    isFeatured: false,
  );
}

void main() {
  test('unpriced package displays Contact Admin', () {
    final package = _package(price: 0);

    expect(package.isPriceAvailable, isFalse);
    expect(package.formattedPrice, 'Contact Admin');
  });

  test('configured zero-markup package remains available', () {
    final package = _package(price: 25);

    expect(package.isPriceAvailable, isTrue);
    expect(package.formattedPrice, 'USD 25.00');
  });

  testWidgets('unpriced package cannot continue to checkout', (tester) async {
    final package = _package(price: 0);

    await tester.pumpWidget(
      MaterialApp(home: PackageDetailScreen(package: package)),
    );

    expect(find.text('Contact Admin'), findsWidgets);
    expect(find.text('Central pricing required'), findsOneWidget);

    final checkoutButton = tester.widget<FilledButton>(
      find.byType(FilledButton).first,
    );
    expect(checkoutButton.onPressed, isNull);
  });

  testWidgets('admin is directed to configure missing pricing', (tester) async {
    final package = _package(price: 0);

    await tester.pumpWidget(
      MaterialApp(
        home: PackageDetailScreen(
          package: package,
          roleOverride: AppRole.admin,
        ),
      ),
    );

    expect(find.text('Contact Admin'), findsNothing);
    expect(find.text('Configure pricing'), findsNWidgets(2));
    expect(find.text('Central pricing required'), findsOneWidget);

    final pricingButton = tester.widget<FilledButton>(
      find.byType(FilledButton).first,
    );
    expect(pricingButton.onPressed, isNotNull);
  });
}
