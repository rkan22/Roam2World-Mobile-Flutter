import 'dart:typed_data';

import 'der_tlv.dart';

/// Exact ASN.1 codec for the two bootstrap ES10 operations required before
/// server authentication.
///
/// The tags mirror NekokoLPA2's generated SGP.22 model:
/// - GetEuiccInfo1Request / EUICCInfo1: BF20
/// - GetEuiccChallengeRequest / Response: BF2E, with challenge at tag 80.
class Sgp22Es10BootstrapCodec {
  const Sgp22Es10BootstrapCodec({DerReader reader = const DerReader()})
      : _reader = reader;

  final DerReader _reader;

  Uint8List encodeGetEuiccInfo1() => Uint8List.fromList(const [0xBF, 0x20, 0x00]);

  Uint8List decodeGetEuiccInfo1(Uint8List response) {
    final root = _reader.readSingle(response);
    if (root.tag != 0xBF20 || !root.constructed) {
      throw const FormatException('Invalid EUICCInfo1 ASN.1 payload.');
    }
    return Uint8List.fromList(response);
  }

  Uint8List encodeGetEuiccChallenge() =>
      Uint8List.fromList(const [0xBF, 0x2E, 0x00]);

  Uint8List decodeGetEuiccChallenge(Uint8List response) {
    final root = _reader.readSingle(response);
    if (root.tag != 0xBF2E || !root.constructed) {
      throw const FormatException('Invalid GetEuiccChallenge response.');
    }

    final children = _reader.readChildren(root.value);
    final challengeNodes = children.where((node) => node.tag == 0x80).toList();
    if (challengeNodes.length != 1 || challengeNodes.single.value.length != 16) {
      throw const FormatException('eUICC challenge must be exactly 16 bytes.');
    }
    return Uint8List.fromList(challengeNodes.single.value);
  }
}
