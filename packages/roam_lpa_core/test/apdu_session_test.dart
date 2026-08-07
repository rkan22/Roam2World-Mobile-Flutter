import 'package:flutter_test/flutter_test.dart';
import 'package:roam_lpa_core/roam_lpa_core.dart';

class _FakeChannel implements EuiccChannel {
  bool opened = false;
  bool closed = false;
  List<int> response = <int>[0x90, 0x00];

  @override
  Future<void> open() async => opened = true;

  @override
  Future<List<int>> transmit(List<int> apdu) async {
    if (!opened) throw StateError('not open');
    return response;
  }

  @override
  Future<void> close() async {
    closed = true;
    opened = false;
  }
}

void main() {
  test('splits APDU data and success status word', () async {
    final channel = _FakeChannel()..response = <int>[0x01, 0x02, 0x90, 0x00];
    final session = EuiccApduSession(channel);

    final result = await session.run((s) => s.transmit(Uint8List.fromList(<int>[0x80, 0xCA, 0x00, 0x00])));

    expect(result.data, <int>[0x01, 0x02]);
    expect(result.statusWord, 0x9000);
    expect(channel.closed, isTrue);
  });

  test('throws on unsuccessful APDU status word', () async {
    final channel = _FakeChannel()..response = <int>[0x6A, 0x82];
    final session = EuiccApduSession(channel);

    expect(
      () => session.run((s) => s.transmit(Uint8List.fromList(<int>[0x00, 0xA4, 0x04, 0x00]))),
      throwsA(isA<ApduException>()),
    );
  });
}
