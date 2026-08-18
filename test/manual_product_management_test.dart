import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/api/api_endpoints.dart';
import 'package:roam2world_mobile_flutter/features/admin/manual_fulfillment_repository.dart';

void main() {
  test('eSIM draft produces QR assignment backend payload', () {
    const draft = ManualProductDraft(
      packageId: 'MANUAL-ESIM-10GB',
      operatorName: 'Roam2World',
      productName: 'Europe 10GB',
      productType: 'esim',
      providerCost: 12.5,
      currency: 'eur',
      dataGb: 10,
      validityDays: 30,
      coverageCountries: ['DE', 'FR'],
      notes: 'Manual QR',
      isActive: true,
      visibleToResellers: true,
      visibleToDealers: false,
      lowStockThreshold: 8,
    );

    final payload = draft.toJson();

    expect(payload['fulfillment_mode'], 'qr_assignment');
    expect(payload['currency'], 'EUR');
    expect(payload['low_stock_threshold'], 0);
    expect(payload['coverage_countries'], ['DE', 'FR']);
  });

  test('physical SIM draft produces stock fulfillment payload', () {
    const draft = ManualProductDraft(
      packageId: 'MANUAL-SIM-100GB',
      operatorName: 'Roam2World',
      productName: 'Physical SIM 100GB',
      productType: 'sim',
      providerCost: 20,
      currency: 'USD',
      dataGb: 100,
      validityDays: 30,
      coverageCountries: ['TR'],
      notes: '',
      isActive: true,
      visibleToResellers: true,
      visibleToDealers: true,
      lowStockThreshold: 5,
    );

    final payload = draft.toJson();

    expect(payload['fulfillment_mode'], 'iccid_stock');
    expect(payload['low_stock_threshold'], 5);
  });

  test('manual product response keeps editable backend fields', () {
    final product = ManualProductItem.fromJson({
      'package_id': 'MANUAL-1',
      'operator_name': 'Operator',
      'product_name': 'Manual Product',
      'product_type': 'esim',
      'fulfillment_mode': 'qr_assignment',
      'provider_cost': '9.50',
      'currency': 'USD',
      'is_active': true,
      'visible_to_resellers': true,
      'visible_to_dealers': false,
      'data_gb': '5.00',
      'validity_days': 30,
      'coverage_countries': ['TR', 'DE'],
      'notes': 'Test',
      'low_stock_threshold': null,
    });

    expect(product.providerCost, 9.5);
    expect(product.dataGb, 5);
    expect(product.validityDays, 30);
    expect(product.coverageCountries, ['TR', 'DE']);
    expect(product.visibleToDealers, isFalse);
  });

  test('manual product detail safely encodes package id', () {
    expect(
      ApiEndpoints.manualAdminProductDetail('MANUAL/A B'),
      '/api/v1/admin/manual-fulfillment/products/MANUAL%2FA%20B/',
    );
  });
}
