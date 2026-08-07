import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roam_lpa_core/roam_lpa_core.dart';

void main() {
  test('frames regular ES10 request as 80 E2 91 00', () {
    const framer = Sgp22StoreDataFramer();
    final command = framer.frameRequest(Uint8List.fromList(<int>[0xBF, 0x20, 0x00]));

    expect(command, <int>[0x80, 0xE2, 0x91, 0x00, 0x03, 0xBF, 0x20, 0x00]);
  });

  test('uses extended Lc for large regular ES10 payload', () {
    const framer = Sgp22StoreDataFramer();
    final payload = Uint8List(300);
    final command = framer.frameRequest(payload);

    expect(command.sublist(0, 7), <int>[0x80, 0xE2, 0x91, 0x00, 0x00, 0x01, 0x2C]);
    expect(command.length, 307);
  });

  test('chunks a BPP segment with 11 for more and 91 for last', () {
    const framer = Sgp22StoreDataFramer(maxBlockData: 3);
    final commands = framer.frameProfileSegment(
      Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7]),
    );

    expect(commands, <List<int>>[
      <int>[0x80, 0xE2, 0x11, 0x00, 0x03, 1, 2, 3],
      <int>[0x80, 0xE2, 0x11, 0x01, 0x03, 4, 5, 6],
      <int>[0x80, 0xE2, 0x91, 0x02, 0x01, 7],
    ]);
  });
}
