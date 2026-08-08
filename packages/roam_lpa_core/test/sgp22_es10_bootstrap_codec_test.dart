import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roam_lpa_core/roam_lpa_core.dart';

void main() {
  const codec = Sgp22Es10BootstrapCodec();

  test('encodes exact GetEuiccInfo1 request', () {
    expect(codec.encodeGetEuiccInfo1(), [0xBF, 0x20, 0x00]);
  });

  test('validates EUICCInfo1 and preserves encoded response', () {
    final response = Uint8List.fromList([0xBF, 0x20, 0x03, 0x82, 0x01, 0x01]);
    expect(codec.decodeGetEuiccInfo1(response), response);
  });

  test('encodes exact GetEuiccChallenge request', () {
    expect(codec.encodeGetEuiccChallenge(), [0xBF, 0x2E, 0x00]);
  });

  test('extracts 16 byte eUICC challenge from tag 80', () {
    final challenge = List<int>.generate(16, (index) => index);
    final response = Uint8List.fromList([
      0xBF,
      0x2E,
      0x12,
      0x80,
      0x10,
      ...challenge,
    ]);
    expect(codec.decodeGetEuiccChallenge(response), challenge);
  });

  test('rejects malformed challenge length', () {
    final response = Uint8List.fromList([0xBF, 0x2E, 0x03, 0x80, 0x01, 0xAA]);
    expect(() => codec.decodeGetEuiccChallenge(response), throwsFormatException);
  });
}
