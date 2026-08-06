import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeController {
  ThemeController._();

  static const _storageKey = 'app_theme_mode';
  static const _storage = FlutterSecureStorage();

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> initialize() async {
    try {
      final storedValue = await _storage.read(key: _storageKey);
      mode.value = _fromStorage(storedValue);
    } catch (_) {
      mode.value = ThemeMode.system;
    }
  }

  static void setMode(ThemeMode value) {
    if (mode.value == value) return;
    mode.value = value;
    unawaited(_persist(value));
  }

  static Future<void> _persist(ThemeMode value) async {
    try {
      await _storage.write(key: _storageKey, value: value.name);
    } catch (_) {
      // The selected mode remains active for this session even if storage
      // is temporarily unavailable.
    }
  }

  static ThemeMode _fromStorage(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String label(ThemeMode value) {
    return switch (value) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }
}
