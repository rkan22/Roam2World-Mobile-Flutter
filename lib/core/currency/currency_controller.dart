import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class CurrencyController extends ChangeNotifier {
  CurrencyController._();

  static final CurrencyController instance = CurrencyController._();

  static const _preferenceKey = 'display_currency';
  final ApiClient _api = ApiClient();

  String _selectedCurrency = 'USD';
  double _usdToEurRate = 0.85;
  bool _initialized = false;
  bool _loading = false;

  String get selectedCurrency => _selectedCurrency;
  bool get loading => _loading;
  double get usdToEurRate => _usdToEurRate;

  Future<void> initialize() async {
    if (_initialized || _loading) return;
    _loading = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_preferenceKey);
      if (saved == 'USD' || saved == 'EUR') {
        _selectedCurrency = saved!;
      }
      notifyListeners();
      await refreshRate();
    } finally {
      _initialized = true;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshRate() async {
    try {
      final response = await _api.get<dynamic>(
        ApiEndpoints.currencyExchangeRate,
        queryParameters: const {'from': 'USD', 'to': 'EUR'},
        parser: (data) => data,
      );
      final rate = _extractRate(response);
      if (rate != null && rate > 0) {
        _usdToEurRate = rate;
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Currency rate refresh failed: $error');
    }
  }

  Future<void> toggle() async {
    _selectedCurrency = _selectedCurrency == 'USD' ? 'EUR' : 'USD';
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, _selectedCurrency);
  }

  double convert(
    num amount, {
    String fromCurrency = 'USD',
    String? toCurrency,
  }) {
    final target = toCurrency ?? _selectedCurrency;
    final source = fromCurrency.trim().toUpperCase();
    if (source == target) return amount.toDouble();
    if (source == 'USD' && target == 'EUR') {
      return amount.toDouble() * _usdToEurRate;
    }
    if (source == 'EUR' && target == 'USD') {
      return amount.toDouble() / _usdToEurRate;
    }
    return amount.toDouble();
  }

  String format(num amount, {String fromCurrency = 'USD'}) {
    final converted = convert(amount, fromCurrency: fromCurrency);
    return NumberFormat.currency(
      locale: _selectedCurrency == 'EUR' ? 'en_IE' : 'en_US',
      name: _selectedCurrency,
      symbol: _selectedCurrency == 'EUR' ? '€' : r'$',
      decimalDigits: 2,
    ).format(converted);
  }

  double? _extractRate(dynamic response) {
    dynamic value = response;
    if (value is Map && value['data'] != null) value = value['data'];
    if (value is! Map) return null;
    final rates = value['rates'];
    final candidates = [
      value['exchange_rate'],
      value['rate'],
      value['exchangeRate'],
      if (rates is Map) rates['EUR'],
    ];
    for (final candidate in candidates) {
      final parsed = double.tryParse('$candidate');
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }
}
