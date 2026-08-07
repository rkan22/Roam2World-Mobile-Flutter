import 'dart:typed_data';

/// Encodes GSMA ES10 operations into the logical APDU payload understood by
/// the eUICC and decodes the returned ASN.1 payload.
///
/// The concrete implementation is intentionally separate from the APDU pipe so
/// generated SGP.22 ASN.1 models can be extracted from Nekoko without coupling
/// transport/session lifecycle to generated classes.
abstract interface class Es10CommandCodec {
  Uint8List encodeGetEuiccInfo1();
  Uint8List decodeGetEuiccInfo1(Uint8List response);

  Uint8List encodeGetEuiccChallenge();
  Uint8List decodeGetEuiccChallenge(Uint8List response);

  Uint8List encodeAuthenticateServer({
    required Uint8List transactionId,
    required Uint8List serverSigned1,
    required Uint8List serverSignature1,
    required Uint8List euiccCiPkIdToBeUsed,
    required Uint8List serverCertificate,
  });
  Uint8List decodeAuthenticateServer(Uint8List response);

  Uint8List encodePrepareDownload({
    required Uint8List smdpSigned2,
    required Uint8List smdpSignature2,
    required Uint8List smdpCertificate,
    String? confirmationCode,
  });
  Uint8List decodePrepareDownload(Uint8List response);

  Iterable<Uint8List> encodeLoadBoundProfilePackage(Uint8List package);
  void validateLoadBoundProfilePackageResponse(Uint8List response, {required bool last});
}
