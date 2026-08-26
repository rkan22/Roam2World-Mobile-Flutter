import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';

enum DisplayCurrency { usd, eur }

class DisplayCurrencyController {
  DisplayCurrencyController._();

  static const _storageKey = 'display_currency';
  static const _storage = FlutterSecureStorage();
  static final ValueNotifier<DisplayCurrency> selected =
      ValueNotifier<DisplayCurrency>(DisplayCurrency.usd);

  // EUR received for one USD. Accounting and checkout remain USD.
  static double? _usdToEur;

  static Future<void> initialize({ApiClient? apiClient}) async {
    try {
      final stored = await _storage.read(key: _storageKey);
      selected.value = stored == 'EUR'
          ? DisplayCurrency.eur
          : DisplayCurrency.usd;
    } catch (_) {
      selected.value = DisplayCurrency.usd;
    }
    await refreshRate(apiClient: apiClient);
    if (selected.value == DisplayCurrency.eur && !hasEurRate) {
      selected.value = DisplayCurrency.usd;
    }
  }

  static Future<void> refreshRate({ApiClient? apiClient}) async {
    try {
      final rate = await (apiClient ?? ApiClient()).get<double>(
        '/api/v1/currency/exchange-rate/',
        queryParameters: const {'from': 'USD', 'to': 'EUR'},
        parser: (response) {
          final root = Map<String, dynamic>.from(response as Map);
          final data = root['data'] is Map
              ? Map<String, dynamic>.from(root['data'] as Map)
              : root;
          return double.tryParse('${data['exchange_rate']}') ?? 0;
        },
      );
      if (rate > 0) _usdToEur = rate;
    } catch (_) {
      // USD remains available if the display-only rate endpoint is offline.
    }
  }

  static bool get hasEurRate => (_usdToEur ?? 0) > 0;

  static void setCurrency(DisplayCurrency value) {
    if (value == DisplayCurrency.eur && !hasEurRate) return;
    selected.value = value;
    unawaited(_persist(value));
  }

  static Future<void> _persist(DisplayCurrency value) async {
    try {
      await _storage.write(key: _storageKey, value: code(value));
    } catch (_) {}
  }

  static String code(DisplayCurrency value) =>
      value == DisplayCurrency.eur ? 'EUR' : 'USD';

  static String formatUsd(num amount) {
    final useEur = selected.value == DisplayCurrency.eur && hasEurRate;
    final converted = useEur ? amount * _usdToEur! : amount;
    final symbol = useEur ? '€' : r'$';
    return '$symbol${NumberFormat('#,##0.00', 'en_US').format(converted)}';
  }
}
