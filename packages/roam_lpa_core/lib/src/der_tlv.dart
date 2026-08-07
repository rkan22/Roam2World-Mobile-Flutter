import 'dart:typed_data';

class DerTlv {
  const DerTlv({
    required this.tag,
    required this.constructed,
    required this.value,
    required this.encodedLength,
  });

  final int tag;
  final bool constructed;
  final Uint8List value;
  final int encodedLength;
}

/// Minimal definite-length BER/DER reader used to validate GSMA RSP payloads.
/// Indefinite-length encodings are intentionally rejected.
class DerReader {
  const DerReader();

  DerTlv readSingle(Uint8List bytes) {
    if (bytes.isEmpty) throw const FormatException('Empty ASN.1 payload.');
    final parsed = _readAt(bytes, 0);
    if (parsed.encodedLength != bytes.length) {
      throw const FormatException('Trailing bytes after ASN.1 value.');
    }
    return parsed;
  }

  List<DerTlv> readChildren(Uint8List bytes) {
    final values = <DerTlv>[];
    var offset = 0;
    while (offset < bytes.length) {
      final value = _readAt(bytes, offset);
      values.add(value);
      offset += value.encodedLength;
    }
    return values;
  }

  DerTlv _readAt(Uint8List bytes, int offset) {
    if (offset >= bytes.length) throw const FormatException('Missing ASN.1 tag.');
    final firstTag = bytes[offset];
    final constructed = (firstTag & 0x20) != 0;
    var cursor = offset + 1;
    var tag = firstTag;

    if ((firstTag & 0x1f) == 0x1f) {
      tag = firstTag;
      var count = 0;
      while (true) {
        if (cursor >= bytes.length) throw const FormatException('Truncated high-tag ASN.1 value.');
        final part = bytes[cursor++];
        tag = (tag << 8) | part;
        count++;
        if (count > 4) throw const FormatException('ASN.1 tag is too large.');
        if ((part & 0x80) == 0) break;
      }
    }

    if (cursor >= bytes.length) throw const FormatException('Missing ASN.1 length.');
    final lengthByte = bytes[cursor++];
    int length;
    if ((lengthByte & 0x80) == 0) {
      length = lengthByte;
    } else {
      final count = lengthByte & 0x7f;
      if (count == 0) throw const FormatException('Indefinite ASN.1 length is not supported.');
      if (count > 4 || cursor + count > bytes.length) {
        throw const FormatException('Invalid ASN.1 length.');
      }
      length = 0;
      for (var i = 0; i < count; i++) {
        length = (length << 8) | bytes[cursor++];
      }
      if (length < 128) {
        throw const FormatException('Non-minimal DER length encoding.');
      }
    }

    final end = cursor + length;
    if (end > bytes.length) throw const FormatException('Truncated ASN.1 value.');
    return DerTlv(
      tag: tag,
      constructed: constructed,
      value: Uint8List.sublistView(bytes, cursor, end),
      encodedLength: end - offset,
    );
  }
}
