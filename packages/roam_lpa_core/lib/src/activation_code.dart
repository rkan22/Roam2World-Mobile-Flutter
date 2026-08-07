/// Parsed GSMA consumer eSIM activation code.
///
/// Supports the common `LPA:1$<SM-DP+>$<matching-id>[$<confirmation>]`
/// representation and the same payload without the `LPA:` prefix.
class LpaActivationCode {
  const LpaActivationCode({
    required this.smdpAddress,
    required this.matchingId,
    this.confirmationCode,
  });

  final String smdpAddress;
  final String matchingId;
  final String? confirmationCode;

  static LpaActivationCode parse(String raw) {
    var value = raw.trim();
    if (value.regionMatches(0, 'LPA:', 0, 4)) value = value.substring(4);

    final marker = value.indexOf('1\$');
    if (marker > 0) value = value.substring(marker);

    final parts = value.split('\$');
    if (parts.length < 3 || parts.first != '1') {
      throw const FormatException('Unsupported LPA activation code format.');
    }

    final smdp = parts[1].trim();
    final matching = parts[2].trim();
    if (smdp.isEmpty || matching.isEmpty) {
      throw const FormatException('SM-DP+ address and matching ID are required.');
    }

    final confirmation = parts.length > 3 && parts[3].trim().isNotEmpty
        ? parts[3].trim()
        : null;
    return LpaActivationCode(
      smdpAddress: smdp,
      matchingId: matching,
      confirmationCode: confirmation,
    );
  }

  String get canonical => 'LPA:1\$$smdpAddress\$$matchingId${confirmationCode == null ? '' : '\$$confirmationCode'}';
}

extension on String {
  bool regionMatches(int start, String other, int otherStart, int length) {
    if (start < 0 || otherStart < 0 || start + length > this.length || otherStart + length > other.length) return false;
    return substring(start, start + length).toLowerCase() == other.substring(otherStart, otherStart + length).toLowerCase();
  }
}
