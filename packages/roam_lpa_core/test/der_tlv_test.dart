import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roam_lpa_core/roam_lpa_core.dart';

void main() {
  test('reads a definite-length ASN.1 sequence', () {
    final tlv = const DerReader().readSingle(Uint8List.fromList([0x30, 0x03, 0x02, 0x01, 0x01]));
    expect(tlv.tag, 0x30);
    expect(tlv.constructed, isTrue);
    expect(tlv.value, [0x02, 0x01, 0x01]);
  });

  test('rejects trailing bytes', () {
    expect(
      () => const DerReader().readSingle(Uint8List.fromList([0x02, 0x01, 0x01, 0x00])),
      throwsFormatException,
    );
  });

  test('rejects indefinite length', () {
    expect(
      () => const DerReader().readSingle(Uint8List.fromList([0x30, 0x80, 0x00, 0x00])),
      throwsFormatException,
    );
  });
}
