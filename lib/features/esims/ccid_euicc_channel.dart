import 'dart:io';

import 'package:ccid/ccid.dart';
import 'package:flutter/services.dart';
import 'package:roam_lpa_core/roam_lpa_core.dart';

class CcidEuiccCapability {
  const CcidEuiccCapability({
    required this.available,
    required this.readers,
    required this.reason,
  });

  final bool available;
  final List<String> readers;
  final String reason;

  String get reader => readers.isEmpty ? '' : readers.first;
}

class CcidEuiccChannel implements EuiccChannel {
  CcidEuiccChannel({this.readerName, Ccid? ccid}) : _ccid = ccid ?? Ccid();

  final Ccid _ccid;
  String? readerName;
  CcidCard? _card;
  String? get atr => _card?.atr;
  bool get isOpen => _card != null;

  static Future<CcidEuiccCapability> capability({Ccid? ccid}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const CcidEuiccCapability(
        available: false,
        readers: <String>[],
        reason: 'CCID transport yalnızca Android ve iOS mobil cihazlarda kullanılabilir.',
      );
    }

    try {
      final readers = await (ccid ?? Ccid()).listReaders();
      if (readers.isEmpty) {
        return const CcidEuiccCapability(
          available: false,
          readers: <String>[],
          reason:
              'CCID card reader bulunamadı. Uyumlu reader’ı bağlayıp tekrar kontrol edin.',
        );
      }
      return CcidEuiccCapability(
        available: true,
        readers: List<String>.unmodifiable(readers),
        reason: 'USB CCID reader bulundu: ${readers.first}',
      );
    } on MissingPluginException {
      return const CcidEuiccCapability(
        available: false,
        readers: <String>[],
        reason: 'CCID Flutter eklentisi bu mobil derlemeye eklenmemiş.',
      );
    } on PlatformException catch (error) {
      return CcidEuiccCapability(
        available: false,
        readers: const <String>[],
        reason: error.message ?? 'USB CCID reader kontrol edilemedi.',
      );
    } catch (error) {
      return CcidEuiccCapability(
        available: false,
        readers: const <String>[],
        reason: 'USB CCID reader kontrol edilemedi: $error',
      );
    }
  }

  @override
  Future<void> open() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
        'CCID transport yalnızca Android ve iOS mobil cihazlarda kullanılabilir.',
      );
    }
    if (_card != null) return;

    final readers = await _ccid.listReaders();
    if (readers.isEmpty) {
      throw StateError('USB CCID card reader bulunamadı.');
    }

    final selected = readerName ?? readers.first;
    if (!readers.contains(selected)) {
      throw StateError('Seçilen USB CCID reader artık bağlı değil: $selected');
    }

    // connect() requests Android USB permission when needed and only completes
    // after the card has been powered on and its ATR has been read.
    final card = await _ccid.connect(selected);
    readerName = selected;
    _card = card;
  }

  @override
  Future<List<int>> transmit(List<int> apdu) async {
    final card = _card;
    if (card == null) {
      throw StateError('APDU göndermeden önce CCID kanalını açın.');
    }
    if (apdu.length < 4 || apdu.any((value) => value < 0 || value > 255)) {
      throw const FormatException('APDU byte değerleri 0..255 aralığında olmalı.');
    }

    final responseHex = await card.transceive(_encodeHex(apdu));
    if (responseHex == null || responseHex.isEmpty) {
      throw PlatformException(
        code: 'EMPTY_CCID_RESPONSE',
        message: 'CCID reader APDU yanıtı döndürmedi.',
      );
    }
    return _decodeHex(responseHex);
  }

  @override
  Future<void> close() async {
    final card = _card;
    _card = null;
    if (card != null) await card.disconnect();
  }

  static String _encodeHex(List<int> bytes) => bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();

  static List<int> _decodeHex(String value) {
    final hex = value.replaceAll(RegExp(r'\s+'), '');
    if (hex.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      throw const FormatException('CCID reader geçersiz hexadecimal yanıt döndürdü.');
    }
    return <int>[
      for (var offset = 0; offset < hex.length; offset += 2)
        int.parse(hex.substring(offset, offset + 2), radix: 16),
    ];
  }
}
