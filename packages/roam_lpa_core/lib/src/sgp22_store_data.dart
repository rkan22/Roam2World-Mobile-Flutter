import 'dart:typed_data';

/// Builds ISO 7816 STORE DATA commands used by the SGP.22 ES10 flow.
///
/// NekokoLPA2 sends regular ES10 ASN.1 requests as `80 E2 91 00` and uses
/// `P1=11` for intermediate bound-profile blocks and `P1=91` for the final
/// block of a segment. P2 is the block sequence number.
class Sgp22StoreDataFramer {
  const Sgp22StoreDataFramer({this.maxBlockData = 255})
      : assert(maxBlockData > 0 && maxBlockData <= 255);

  final int maxBlockData;

  /// Frames a regular ES10 ASN.1 request as one STORE DATA APDU.
  /// Uses extended Lc when the payload exceeds one-byte Lc.
  Uint8List frameRequest(Uint8List payload) =>
      _command(p1: 0x91, p2: 0x00, data: payload, allowExtended: true);

  /// Frames one already-decomposed BPP segment into short STORE DATA blocks.
  ///
  /// The caller is responsible for decomposing the BPP into its SGP.22 ASN.1
  /// segments (BF36/87/88/etc.); this method never rewrites ASN.1 bytes.
  List<Uint8List> frameProfileSegment(Uint8List segment) {
    if (segment.isEmpty) {
      throw const FormatException('Bound-profile segment must not be empty.');
    }

    final commands = <Uint8List>[];
    var offset = 0;
    var sequence = 0;
    while (offset < segment.length) {
      final end = (offset + maxBlockData < segment.length)
          ? offset + maxBlockData
          : segment.length;
      final chunk = Uint8List.sublistView(segment, offset, end);
      final last = end == segment.length;
      commands.add(
        _command(
          p1: last ? 0x91 : 0x11,
          p2: sequence & 0xff,
          data: chunk,
          allowExtended: false,
        ),
      );
      offset = end;
      sequence++;
    }
    return commands;
  }

  static Uint8List _command({
    required int p1,
    required int p2,
    required Uint8List data,
    required bool allowExtended,
  }) {
    if (data.isEmpty) {
      return Uint8List.fromList(<int>[0x80, 0xE2, p1, p2, 0x00]);
    }
    if (data.length <= 0xff) {
      return Uint8List.fromList(<int>[
        0x80,
        0xE2,
        p1,
        p2,
        data.length,
        ...data,
      ]);
    }
    if (!allowExtended || data.length > 0xffff) {
      throw FormatException('STORE DATA payload length ${data.length} is unsupported.');
    }
    return Uint8List.fromList(<int>[
      0x80,
      0xE2,
      p1,
      p2,
      0x00,
      (data.length >> 8) & 0xff,
      data.length & 0xff,
      ...data,
    ]);
  }
}
