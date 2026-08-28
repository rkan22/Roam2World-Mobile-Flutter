import 'dart:io';

import 'package:flutter/services.dart';

import 'ccid_euicc_channel.dart';

class LpaCapability {
  const LpaCapability({
    required this.platform,
    required this.esimSupported,
    required this.directInstallSupported,
    required this.reason,
    this.transport = 'none',
    this.nekokoAvailable = false,
    this.ccidAvailable = false,
    this.ccidReaders = const <String>[],
  });

  final String platform;
  final bool esimSupported;
  final bool directInstallSupported;
  final String reason;
  final String transport;
  final bool nekokoAvailable;
  final bool ccidAvailable;
  final List<String> ccidReaders;

  factory LpaCapability.fromMap(Map<Object?, Object?> map) => LpaCapability(
    platform: map['platform']?.toString() ?? 'unknown',
    esimSupported: map['esimSupported'] == true,
    directInstallSupported: map['directInstallSupported'] == true,
    reason: map['reason']?.toString() ?? '',
    transport: map['transport']?.toString() ?? 'none',
    nekokoAvailable: map['nekokoAvailable'] == true,
  );

  LpaCapability withCcid(CcidEuiccCapability ccid) {
    if (!ccid.available) return this;
    return LpaCapability(
      platform: platform,
      esimSupported: true,
      directInstallSupported: directInstallSupported,
      reason: ccid.reason,
      transport: 'usb_ccid',
      nekokoAvailable: false,
      ccidAvailable: true,
      ccidReaders: ccid.readers,
    );
  }
}

class CcidConnectionResult {
  const CcidConnectionResult({required this.reader, required this.atr});

  final String reader;
  final String atr;
}

class LpaInstallResult {
  const LpaInstallResult({required this.status, required this.transport});

  final String status;
  final String transport;

  bool get installed => status == 'installed';
  bool get handedOff => status == 'handed_off';

  factory LpaInstallResult.fromMap(Map<Object?, Object?> map) =>
      LpaInstallResult(
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
        reason:
            'LPA installation is only available on supported mobile devices.',
      );
    }

    final native = await _nativeCapability();
    if (!Platform.isAndroid) return native;

    final ccid = await CcidEuiccChannel.capability();
    return native.withCcid(ccid);
  }

  Future<LpaCapability> _nativeCapability() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getCapability',
      );
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

  Future<CcidConnectionResult> connectCcidReader({String? reader}) async {
    final capability = await CcidEuiccChannel.capability();
    if (!capability.available) {
      throw LpaBridgeException('CCID_NOT_FOUND', capability.reason);
    }

    final selected = reader ?? capability.reader;
    final channel = CcidEuiccChannel(readerName: selected);
    try {
      await channel.open();
      final atr = channel.atr;
      if (atr == null || atr.isEmpty) {
        throw const LpaBridgeException(
          'CCID_CARD_NOT_FOUND',
          'Reader bulundu ancak içindeki karttan ATR alınamadı.',
        );
      }
      return CcidConnectionResult(reader: selected, atr: atr);
    } on LpaBridgeException {
      rethrow;
    } on PlatformException catch (error) {
      throw LpaBridgeException(
        error.code,
        error.message ?? 'USB CCID reader bağlantısı kurulamadı.',
        details: error.details,
      );
    } catch (error) {
      throw LpaBridgeException(
        'CCID_CONNECT_FAILED',
        'USB CCID reader bağlantısı kurulamadı: $error',
      );
    } finally {
      await channel.close();
    }
  }

  Future<LpaInstallResult> installActivationCode(
    String activationCode, {
    bool switchAfterDownload = false,
  }) async {
    return _invokeInstallMethod(
      'installActivationCode',
      activationCode,
      extraArguments: <String, Object?>{
        'switchAfterDownload': switchAfterDownload,
      },
    );
  }

  Future<LpaInstallResult> handoffToNekoko(String activationCode) {
    return _invokeInstallMethod('handoffToNekoko', activationCode);
  }

  Future<LpaInstallResult> _invokeInstallMethod(
    String method,
    String activationCode, {
    Map<String, Object?> extraArguments = const <String, Object?>{},
  }) async {
    if (activationCode.trim().isEmpty) {
      throw const LpaBridgeException(
        'INVALID_ACTIVATION_CODE',
        'Activation code is empty.',
      );
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        method,
        <String, Object?>{
          'activationCode': activationCode.trim(),
          ...extraArguments,
        },
      );
      if (result == null) {
        throw const LpaBridgeException(
          'EMPTY_RESULT',
          'The native LPA returned no result.',
        );
      }
      return LpaInstallResult.fromMap(result);
    } on PlatformException catch (error) {
      throw LpaBridgeException(
        error.code,
        error.message ?? 'The eSIM operation could not be completed.',
        details: error.details,
      );
    } on MissingPluginException {
      throw const LpaBridgeException(
        'MISSING_PLUGIN',
        'Native LPA integration is not available in this build.',
      );
    }
  }
}
