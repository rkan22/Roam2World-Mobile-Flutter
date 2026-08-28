import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'package:nlpa2/adapter/ccid/ccid_adapter.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/logic/profile_download_session.dart';
import 'package:nlpa2/logic/profile_manager.dart';
import 'package:nlpa2/models/activation_code.dart';
import 'package:nlpa2/models/euicc_profile.dart';
import 'package:nlpa2/models/asn1/rsp_definitions.g.dart';
import 'package:roam_lpa_core/roam_lpa_core.dart';
import 'package:nlpa2/utils/crypto_utils.dart';

enum CcidInstallStage {
  connecting,
  authenticating,
  downloading,
  installing,
  completed,
}

class CcidInstallUpdate {
  const CcidInstallUpdate({
    required this.stage,
    required this.progress,
    required this.message,
  });

  final CcidInstallStage stage;
  final double progress;
  final String message;
}

class CcidReaderConnection {
  const CcidReaderConnection({
    required this.reader,
    required this.atr,
  });

  final String reader;
  final String atr;
}

/// Thin Roam2World adapter around NekokoLPA2's extracted CCID + SGP.22 core.
/// No Nekoko screen, navigation or companion application is used.
class CcidProfileInstaller {
  CcidProfileInstaller() : _adapter = CcidAdapter();

  static const _allowUntrustedSmdpTls = bool.fromEnvironment(
    'ROAM_ALLOW_UNTRUSTED_SMDP_TLS',
  );

  final CcidAdapter _adapter;
  late ProfileManager _manager;
  Reader? _reader;
  bool _connected = false;

  Future<List<String>> listReaders() async {
    final readers = await _adapter.listReaders(force: true);
    return readers.map((reader) => reader.name).toList(growable: false);
  }

  Future<CcidReaderConnection> connect({String? readerName}) async {
    final readers = await _adapter.listReaders(force: true);
    if (readers.isEmpty) {
      throw StateError('USB CCID card reader bulunamadı.');
    }

    final reader = readerName == null
        ? readers.first
        : readers.firstWhere(
            (candidate) => candidate.name == readerName,
            orElse: () => readers.first,
          );

    await _adapter.connect(reader);
    _reader = reader;
    _connected = true;
    _manager = ProfileManager(_adapter);

    final atr = _adapter.lastAtr;
    if (atr == null || atr.isEmpty) {
      await disconnect();
      throw StateError('Reader bulundu ancak eUICC karttan ATR alınamadı.');
    }
    return CcidReaderConnection(reader: reader.name, atr: atr);
  }

  Future<List<EuiccProfile>> listProfiles() async {
    _ensureConnected();
    return _manager.listProfiles();
  }

  Future<void> setProfileEnabled(String iccid, {required bool enabled}) async {
    _ensureConnected();
    if (enabled) {
      await _manager.enableProfile(iccid);
    } else {
      await _manager.disableProfile(iccid);
    }
  }

  Future<void> renameProfile(String iccid, String nickname) async {
    _ensureConnected();
    final value = nickname.trim();
    if (value.isEmpty) {
      throw const FormatException('Profil adı boş bırakılamaz.');
    }
    if (value.length > 64) {
      throw const FormatException('Profil adı en fazla 64 karakter olabilir.');
    }
    await _manager.renameProfile(iccid, value);
  }

  Future<void> deleteProfile(String iccid) async {
    _ensureConnected();
    await _manager.deleteProfile(iccid);
  }

  void _ensureConnected() {
    if (!_connected || _reader == null) {
      throw StateError('Önce USB CCID reader bağlantısını kurun.');
    }
  }

  Future<void> install(
    String rawActivationCode, {
    required void Function(CcidInstallUpdate update) onUpdate,
  }) async {
    if (!_connected || _reader == null) {
      throw StateError('Önce USB CCID reader bağlantısını kurun.');
    }

    final activation = ActivationCode.parse(rawActivationCode.trim());
    if (activation == null) {
      throw const FormatException('Geçersiz LPA aktivasyon kodu.');
    }

    final smdpHost = Uri.parse(
      'https://${activation.smdpAddress}',
    ).host.toLowerCase();
    final httpClient = HttpClient();
    if (kDebugMode && _allowUntrustedSmdpTls) {
      // Debug-only escape hatch for test SM-DP+ environments using a private
      // certificate chain. Never accepts a certificate for another host and
      // is compiled out of release mode by the kDebugMode guard.
      httpClient.badCertificateCallback = (_, host, __) {
        return host.toLowerCase() == smdpHost;
      };
    }
    final es9 = HttpEs9PlusClient(client: httpClient);

    Channel? channel;
    try {
      onUpdate(const CcidInstallUpdate(
        stage: CcidInstallStage.authenticating,
        progress: .08,
        message: 'eUICC doğrulanıyor…',
      ));

      channel = await _manager.openSession();

      // Capture the card state before installation so activation can target
      // only the profile created by this download.
      final profilesBefore = await _manager.listProfiles(useChannel: channel);
      final existingIccids = profilesBefore
          .map((profile) => profile.iccid)
          .where((iccid) => iccid.isNotEmpty && iccid != 'Unknown')
          .toSet();

      final challenge = await _manager.getEuiccChallenge(useChannel: channel);
      final info1 = await _manager.getEuiccInfo1(useChannel: channel);

      final session = ProfileDownloadSession(
        smdpAddress: activation.smdpAddress,
        matchingId: activation.matchingId,
        confirmationCode: activation.confirmationCode,
      )
        ..processEuiccInfo1(info1)
        ..processEuiccChallenge(challenge);

      final initiateRequest = session.getInitiateAuthenticationRequest();
      final initiate = await es9.initiateAuthentication(
        smdpAddress: activation.smdpAddress,
        euiccChallenge: base64Encode(initiateRequest.euiccChallenge!),
        euiccInfo1: base64Encode(initiateRequest.euiccInfo1!.encode()),
      );

      final transactionText = _requiredString(initiate, 'transactionId');
      final transaction = Uint8List.fromList(utf8.encode(transactionText));
      final serverSigned1 = _decodeBase64(initiate, 'serverSigned1');
      final serverSignature1 = _decodeBase64(initiate, 'serverSignature1');
      final ciKey = _decodeBase64(initiate, 'euiccCiPKIdToBeUsed');
      final serverCertificate = _decodeBase64(initiate, 'serverCertificate');

      session.processInitiateAuthenticationResponse(
        'Executed-Success',
        transaction,
        serverCertificate,
      );

      final authenticateServer = await _manager.authenticateServer(
        serverSigned1: serverSigned1,
        serverSignature1: serverSignature1,
        euiccCiPKIdToBeUsed: ciKey,
        serverCertificate: serverCertificate,
        matchingId: activation.matchingId,
        useChannel: channel,
      );
      session.processAuthenticateServerResponse(authenticateServer);

      final authenticateClientRequest =
          session.getAuthenticateClientRequest();
      final authenticateClient = await es9.authenticateClient(
        smdpAddress: activation.smdpAddress,
        transactionId: transactionText,
        authenticateServerResponse: base64Encode(
          authenticateClientRequest.authenticateServerResponse!.encode(),
        ),
      );

      final signed2 = SmdpSigned2.decode(
        _decodeBase64(authenticateClient, 'smdpSigned2'),
      );
      final signature2 = _decodeBase64(
        authenticateClient,
        'smdpSignature2',
      );
      final certificate2 = Certificate.decode(
        _decodeBase64(authenticateClient, 'smdpCertificate'),
      );

      StoreMetadataRequest? metadata;
      final metadataValue = authenticateClient['profileMetadata'];
      if (metadataValue is String && metadataValue.isNotEmpty) {
        metadata = StoreMetadataRequest.decode(base64Decode(metadataValue));
      }

      session.processAuthenticateClientResponse(
        'Executed-Success',
        AuthenticateClientResponseEs9(
          authenticateClientOk: AuthenticateClientOk(
            transactionId: transaction,
            profileMetadata: metadata,
            smdpSigned2: signed2,
            smdpSignature2: signature2,
            smdpCertificate: certificate2,
          ),
        ),
      );

      onUpdate(const CcidInstallUpdate(
        stage: CcidInstallStage.downloading,
        progress: .36,
        message: 'Profil paketi hazırlanıyor…',
      ));

      Uint8List? hashCc;
      final confirmationCode = activation.confirmationCode;
      if (confirmationCode != null && confirmationCode.isNotEmpty) {
        hashCc = CryptoUtils.computeHashCc(confirmationCode, transaction);
      }

      final prepare = await _manager.prepareDownload(
        smdpSigned2: signed2.encode(),
        smdpSignature2: signature2,
        smdpCertificate: certificate2.encode(),
        hashCc: hashCc,
        useChannel: channel,
      );

      final packageResponse =
          await es9.getBoundProfilePackage(
        smdpAddress: activation.smdpAddress,
        transactionId: transactionText,
        prepareDownloadResponse: base64Encode(prepare.encode()),
      );
      final package = _decodeBase64(
        packageResponse,
        'boundProfilePackage',
      );

      onUpdate(const CcidInstallUpdate(
        stage: CcidInstallStage.installing,
        progress: .55,
        message: 'eSIM profili karta yazılıyor…',
      ));

      await _manager.loadBoundProfilePackage(
        package,
        useChannel: channel,
        onProgress: (sent, total) {
          final ratio = total == 0 ? 0.0 : sent / total;
          onUpdate(CcidInstallUpdate(
            stage: CcidInstallStage.installing,
            progress: .55 + (ratio * .44),
            message: 'Karta yükleniyor: $sent / $total byte',
          ));
        },
      );

      onUpdate(const CcidInstallUpdate(
        stage: CcidInstallStage.installing,
        progress: .99,
        message: 'Yeni eSIM profili etkinleştiriliyor…',
      ));

      final profilesAfter = await _manager.listProfiles(useChannel: channel);
      final installedProfiles = profilesAfter
          .where((profile) =>
              profile.iccid.isNotEmpty &&
              profile.iccid != 'Unknown' &&
              !existingIccids.contains(profile.iccid))
          .toList(growable: false);

      if (installedProfiles.length != 1) {
        throw StateError(
          installedProfiles.isEmpty
              ? 'Profil karta yazıldı ancak yeni ICCID doğrulanamadı. '
                  'Güvenlik için otomatik aktivasyon yapılmadı.'
              : 'Birden fazla yeni profil bulundu. '
                  'Güvenlik için otomatik aktivasyon yapılmadı.',
        );
      }

      final installedProfile = installedProfiles.single;
      if (!installedProfile.enabled) {
        await _manager.enableProfile(
          installedProfile.iccid,
          useChannel: channel,
        );
      }

      onUpdate(const CcidInstallUpdate(
        stage: CcidInstallStage.completed,
        progress: 1,
        message: 'eSIM profili yüklendi ve etkinleştirildi.',
      ));
    } finally {
      if (channel != null) await channel.close();
      httpClient.close(force: true);
    }
  }

  Future<void> disconnect() async {
    if (!_connected) return;
    try {
      await _adapter.disconnect();
    } finally {
      _connected = false;
      _reader = null;
    }
  }

  Uint8List _decodeBase64(Map<String, dynamic> response, String key) {
    final value = response[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('SM-DP+ yanıtında $key bulunamadı.');
    }
    return Uint8List.fromList(
      base64Decode(value.replaceAll(RegExp(r'\s+'), '')),
    );
  }

  String _requiredString(Map<String, dynamic> response, String key) {
    final value = response[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('SM-DP+ yanıtında $key bulunamadı.');
    }
    return value;
  }
}
