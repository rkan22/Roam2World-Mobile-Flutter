import 'dart:io';

import 'package:flutter/services.dart';

class LpaCapability {
  const LpaCapability({
    required this.platform,
    required this.esimSupported,
    required this.directInstallSupported,
    required this.reason,
  });

  final String platform;
  final bool esimSupported;
  final bool directInstallSupported;
  final String reason;

  factory LpaCapability.fromMap(Map<Object?, Object?> map) => LpaCapability(
        platform: map['platform']?.toString() ?? 'unknown',
        esimSupported: map['esimSupported'] == true,
        directInstallSupported: map['directInstallSupported'] == true,
        reason: map['reason']?.toString() ?? '',
      );
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
      if (result == null) throw const PlatformException(code: 'EMPTY_CAPABILITY');
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
}
