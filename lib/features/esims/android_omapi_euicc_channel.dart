import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:roam_lpa_core/roam_lpa_core.dart';

class EmbeddedApduCapability {
  const EmbeddedApduCapability({
    required this.available,
    required this.transport,
    required this.reader,
    required this.aid,
    required this.reason,
  });

  final bool available;
  final String transport;
  final String reader;
  final String aid;
  final String reason;

  factory EmbeddedApduCapability.fromMap(Map<Object?, Object?> map) {
    return EmbeddedApduCapability(
      available: map['available'] == true,
      transport: map['transport']?.toString() ?? 'none',
      reader: map['reader']?.toString() ?? '',
      aid: map['aid']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
    );
  }
}

class AndroidOmapiEuiccChannel implements EuiccChannel {
  static const _channel = MethodChannel('com.roam2world.mobile/lpa');

  bool _open = false;

  static Future<EmbeddedApduCapability> capability() async {
    if (!Platform.isAndroid) {
      return const EmbeddedApduCapability(
        available: false,
        transport: 'none',
        reader: '',
        aid: '',
        reason: 'Android OMAPI is only available on Android.',
      );
    }
    try {
      final response = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getEmbeddedApduCapability',
      );
      if (response == null) {
        throw PlatformException(code: 'EMPTY_OMAPI_CAPABILITY');
      }
      return EmbeddedApduCapability.fromMap(response);
    } on PlatformException catch (error) {
      return EmbeddedApduCapability(
        available: false,
        transport: 'android_omapi',
        reader: '',
        aid: '',
        reason: error.message ?? 'OMAPI capability could not be detected.',
      );
    } on MissingPluginException {
      return const EmbeddedApduCapability(
        available: false,
        transport: 'none',
        reader: '',
        aid: '',
        reason: 'The Android OMAPI bridge is not available in this build.',
      );
    }
  }

  @override
  Future<void> open() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Android OMAPI is only available on Android.');
    }
    await _channel.invokeMethod<Map<Object?, Object?>>('openEuiccChannel');
    _open = true;
  }

  @override
  Future<List<int>> transmit(List<int> apdu) async {
    if (!_open) {
      throw StateError('Open the eUICC channel before transmitting APDUs.');
    }
    if (apdu.length < 4 || apdu.any((value) => value < 0 || value > 255)) {
      throw const FormatException('APDU bytes must be in the range 0..255.');
    }
    final response = await _channel.invokeMethod<Uint8List>(
      'transmitEuiccApdu',
      <String, Object?>{'apdu': Uint8List.fromList(apdu)},
    );
    if (response == null) {
      throw PlatformException(
        code: 'EMPTY_APDU_RESPONSE',
        message: 'The eUICC returned no APDU response.',
      );
    }
    return response;
  }

  @override
  Future<void> close() async {
    if (!_open) return;
    try {
      await _channel.invokeMethod<void>('closeEuiccChannel');
    } finally {
      _open = false;
    }
  }
}
