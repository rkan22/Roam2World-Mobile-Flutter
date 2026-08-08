import 'dart:typed_data';

import 'der_tlv.dart';

/// Splits a GSMA BoundProfilePackage into the STORE DATA segments used by
/// lpac/Nekoko. The original TLV tag/length bytes are preserved verbatim.
class Sgp22BppDecomposer {
  const Sgp22BppDecomposer({DerReader reader = const DerReader()})
      : _reader = reader;

  final DerReader _reader;

  List<Uint8List> decompose(Uint8List bpp) {
    final root = _reader.readSingle(bpp);
    if (root.tag != 0xBF36) return [Uint8List.fromList(bpp)];

    final rootHeader = _headerBytes(bpp, root);
    final children = _childrenWithOffsets(root.value);
    final segments = <Uint8List>[];

    var start = 0;
    if (children.isNotEmpty && children.first.tlv.tag == 0xBF23) {
      segments.add(_concat(rootHeader, children.first.encoded));
      start = 1;
    } else {
      segments.add(rootHeader);
    }

    for (var i = start; i < children.length; i++) {
      final seq = children[i];
      final elements = _childrenWithOffsets(seq.tlv.value);
      if (elements.isEmpty) {
        segments.add(seq.encoded);
        continue;
      }

      final seqHeader = _headerBytes(seq.encoded, seq.tlv);
      if (seq.tlv.tag == 0xA0 || seq.tlv.tag == 0xA2) {
        segments.add(_concat(seqHeader, elements.first.encoded));
        for (var j = 1; j < elements.length; j++) {
          segments.add(elements[j].encoded);
        }
      } else if (seq.tlv.tag == 0xA1 || seq.tlv.tag == 0xA3) {
        segments.add(seqHeader);
        for (final element in elements) {
          segments.add(element.encoded);
        }
      } else {
        segments.add(seq.encoded);
      }
    }

    return segments;
  }

  List<_EncodedTlv> _childrenWithOffsets(Uint8List value) {
    final tlvs = _reader.readChildren(value);
    final result = <_EncodedTlv>[];
    var offset = 0;
    for (final tlv in tlvs) {
      final end = offset + tlv.encodedLength;
      result.add(_EncodedTlv(tlv, Uint8List.fromList(value.sublist(offset, end))));
      offset = end;
    }
    return result;
  }

  Uint8List _headerBytes(Uint8List encoded, DerTlv tlv) {
    final headerLength = tlv.encodedLength - tlv.value.length;
    return Uint8List.fromList(encoded.sublist(0, headerLength));
  }

  Uint8List _concat(Uint8List a, Uint8List b) =>
      Uint8List.fromList(<int>[...a, ...b]);
}

class _EncodedTlv {
  const _EncodedTlv(this.tlv, this.encoded);

  final DerTlv tlv;
  final Uint8List encoded;
}
