import 'dart:typed_data';

import '../roam_lpa_core.dart' show EuiccChannel;

class ApduResponse {
  const ApduResponse({required this.data, required this.sw1, required this.sw2});

  final Uint8List data;
  final int sw1;
  final int sw2;

  int get statusWord => (sw1 << 8) | sw2;
  bool get success => statusWord == 0x9000;
}

class ApduException implements Exception {
  const ApduException(this.statusWord, {this.message});

  final int statusWord;
  final String? message;

  @override
  String toString() => message ??
      'APDU failed with status word 0x${statusWord.toRadixString(16).padLeft(4, '0').toUpperCase()}.';
}

/// Owns open/transmit/close lifecycle and validates ISO 7816 status words.
class EuiccApduSession {
  EuiccApduSession(this.channel);

  final EuiccChannel channel;
  bool _opened = false;

  Future<void> open() async {
    if (_opened) return;
    await channel.open();
    _opened = true;
  }

  Future<ApduResponse> transmit(Uint8List command, {bool requireSuccess = true}) async {
    if (!_opened) throw StateError('Open the eUICC APDU session first.');
    final raw = await channel.transmit(command);
    if (raw.length < 2) {
      throw const FormatException('APDU response is shorter than SW1/SW2.');
    }
    final bytes = Uint8List.fromList(raw);
    final response = ApduResponse(
      data: Uint8List.sublistView(bytes, 0, bytes.length - 2),
      sw1: bytes[bytes.length - 2],
      sw2: bytes[bytes.length - 1],
    );
    if (requireSuccess && !response.success) {
      throw ApduException(response.statusWord);
    }
    return response;
  }

  Future<T> run<T>(Future<T> Function(EuiccApduSession session) action) async {
    await open();
    try {
      return await action(this);
    } finally {
      await close();
    }
  }

  Future<void> close() async {
    if (!_opened) return;
    try {
      await channel.close();
    } finally {
      _opened = false;
    }
  }
}
