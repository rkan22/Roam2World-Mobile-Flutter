import 'dart:io';

import 'package:flutter/services.dart';

class LpaCapability {
  const LpaCapability({
    required this.platform,
    required this.esimSupported,
    required this.directInstallSupported,
    required this.reason,
    this.transport = 'none',
  });

  final String platform;
  final bool esimSupported;
  final bool directInstallSupported;
  final String reason;
  final String transport;

  factory LpaCapability.fromMap(Map<Object?, Object?> map) => LpaCapability(
        platform: map['platform']?.toString() ?? 'unknown',
        esimSupported: map['esimSupported'] == true,
        directInstallSupported: map['directInstallSupported'] == true,
        reason: map['reason']?.toString() ?? '',
        transport: map['transport']?.toString() ?? 'none',
      );
}

class LpaInstallResult {
  const LpaInstallResult({required this.status, required this.transport});

  final String status;
  final String transport;

  bool get installed => status == 'installed';

  factory LpaInstallResult.fromMap(Map<Object?, Object?> map) => LpaInstallResult(
        status: map['status']?.toString() ?? 'unknown',
        transport: map['transport']?.toString() ?? 'unknown',
      );
}

class LpaBridgeException implements Exception {
  const LpaBridgeException(this.code, this.message, {this.details});

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => message;
}

class LpaBridge {
  static const _channel = MethodChannel('com.roam2world.mobile/lpa');

  Future<LpaCapability> capability() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const LpaCapability(
        platform: 'unsupported',
        esimSupported: false,
        directInstallSupported: false,
        reason: 'LPA installation is only available on supported mobile devices.',
      );
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getCapability');
      if (result == null) throw PlatformException(code: 'EMPTY_CAPABILITY');
      return LpaCapability.fromMap(result);
    } on PlatformException catch (error) {
      return LpaCapability(
        platform: Platform.operatingSystem,
        esimSupported: false,
        directInstallSupported: false,
        reason: error.message ?? 'LPA capability could not be detected.',
      );
    } on MissingPluginException {
      return LpaCapability(
        platform: Platform.operatingSystem,
        esimSupported: false,
        directInstallSupported: false,
        reason: 'Native LPA bridge is not available in this build.',
      );
    }
  }

  Future<LpaInstallResult> installActivationCode(
    String activationCode, {
    bool switchAfterDownload = false,
  }) async {
    if (activationCode.trim().isEmpty) {
      throw const LpaBridgeException('INVALID_ACTIVATION_CODE', 'Activation code is empty.');
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'installActivationCode',
        <String, Object?>{
          'activationCode': activationCode.trim(),
          'switchAfterDownload': switchAfterDownload,
        },
      );
      if (result == null) {
        throw const LpaBridgeException('EMPTY_RESULT', 'The native LPA returned no installation result.');
      }
      return LpaInstallResult.fromMap(result);
    } on PlatformException catch (error) {
      throw LpaBridgeException(
        error.code,
        error.message ?? 'The eSIM profile could not be installed.',
        details: error.details,
      );
    } on MissingPluginException {
      throw const LpaBridgeException('MISSING_PLUGIN', 'Native LPA installation is not available in this build.');
    }
  }
}
