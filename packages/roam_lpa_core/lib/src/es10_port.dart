import 'dart:typed_data';

/// Minimal ES10 surface required by the consumer RSP download flow.
///
/// Implementations are responsible for ASN.1 encoding/decoding and APDU
/// transport. Keeping those details behind this port lets the session
/// orchestration remain platform-neutral and testable.
abstract interface class Es10Port {
  Future<Uint8List> getEuiccInfo1();
  Future<Uint8List> getEuiccChallenge();

  /// Sends the server-authentication payload to the eUICC and returns the
  /// encoded AuthenticateServerResponse payload expected by ES9+.
  Future<Uint8List> authenticateServer({
    required Uint8List transactionId,
    required Uint8List serverSigned1,
    required Uint8List serverSignature1,
    required Uint8List euiccCiPkIdToBeUsed,
    required Uint8List serverCertificate,
  });

  /// Sends profile metadata / SM-DP+ signed material to the eUICC and returns
  /// the encoded PrepareDownloadResponse expected by ES9+.
  Future<Uint8List> prepareDownload({
    required Uint8List smdpSigned2,
    required Uint8List smdpSignature2,
    required Uint8List smdpCertificate,
    String? confirmationCode,
  });

  /// Installs the bound profile package and returns only when the eUICC has
  /// accepted the complete package or throws on protocol/APDU failure.
  Future<void> loadBoundProfilePackage(Uint8List boundProfilePackage);
}
