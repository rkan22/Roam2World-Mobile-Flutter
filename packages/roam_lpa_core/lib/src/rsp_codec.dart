import 'dart:typed_data';

/// Protocol codec boundary for GSMA RSP payloads.
///
/// The first embedded slice keeps ASN.1 generated-model details out of the
/// orchestrator. A Nekoko-derived implementation can satisfy this contract
/// when its generated ASN.1 definitions are extracted into the core package.
abstract interface class RspCodec {
  String encodeBase64(Uint8List bytes);
  Uint8List decodeBase64(String value);

  InitiateAuthDecoded decodeInitiateAuthenticationResponse(
    Map<String, dynamic> response,
  );

  AuthenticateClientDecoded decodeAuthenticateClientResponse(
    Map<String, dynamic> response,
  );

  BoundProfileDecoded decodeBoundProfilePackageResponse(
    Map<String, dynamic> response,
  );
}

class InitiateAuthDecoded {
  const InitiateAuthDecoded({
    required this.transactionId,
    required this.serverSigned1,
    required this.serverSignature1,
    required this.euiccCiPkIdToBeUsed,
    required this.serverCertificate,
  });

  final Uint8List transactionId;
  final Uint8List serverSigned1;
  final Uint8List serverSignature1;
  final Uint8List euiccCiPkIdToBeUsed;
  final Uint8List serverCertificate;
}

class AuthenticateClientDecoded {
  const AuthenticateClientDecoded({
    required this.transactionId,
    required this.smdpSigned2,
    required this.smdpSignature2,
    required this.smdpCertificate,
  });

  final Uint8List transactionId;
  final Uint8List smdpSigned2;
  final Uint8List smdpSignature2;
  final Uint8List smdpCertificate;
}

class BoundProfileDecoded {
  const BoundProfileDecoded({required this.boundProfilePackage});
  final Uint8List boundProfilePackage;
}
