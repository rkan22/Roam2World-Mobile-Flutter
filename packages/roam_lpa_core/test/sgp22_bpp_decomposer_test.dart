import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roam_lpa_core/roam_lpa_core.dart';

void main() {
  const decomposer = Sgp22BppDecomposer();

  test('passes through payloads that are not BoundProfilePackage', () {
    final input = Uint8List.fromList([0x30, 0x00]);
    expect(decomposer.decompose(input), [input]);
  });

  test('keeps BF36 header with BF23 and splits A0 elements like Nekoko', () {
    final bpp = Uint8List.fromList([
      0xBF, 0x36, 0x0D,
      0xBF, 0x23, 0x02, 0x81, 0x00,
      0xA0, 0x07,
      0x87, 0x01, 0xAA,
      0x87, 0x02, 0xBB, 0xCC,
    ]);

    expect(decomposer.decompose(bpp), [
      Uint8List.fromList([0xBF, 0x36, 0x0D, 0xBF, 0x23, 0x02, 0x81, 0x00]),
      Uint8List.fromList([0xA0, 0x07, 0x87, 0x01, 0xAA]),
      Uint8List.fromList([0x87, 0x02, 0xBB, 0xCC]),
    ]);
  });

  test('splits A1 into sequence header followed by each child', () {
    final bpp = Uint8List.fromList([
      0xBF, 0x36, 0x0A,
      0xBF, 0x23, 0x00,
      0xA1, 0x05,
      0x88, 0x01, 0x01,
      0x88, 0x00,
    ]);

    expect(decomposer.decompose(bpp), [
      Uint8List.fromList([0xBF, 0x36, 0x0A, 0xBF, 0x23, 0x00]),
      Uint8List.fromList([0xA1, 0x05]),
      Uint8List.fromList([0x88, 0x01, 0x01]),
      Uint8List.fromList([0x88, 0x00]),
    ]);
  });
}
