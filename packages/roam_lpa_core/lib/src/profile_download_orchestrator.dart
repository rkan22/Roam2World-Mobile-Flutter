import 'dart:typed_data';

import 'activation_code.dart';
import 'es10_port.dart';
import 'es9_client.dart';
import 'rsp_codec.dart';

/// Coordinates the SGP.22 consumer download sequence without owning any UI,
/// platform channel, APDU transport or generated ASN.1 model.
class ProfileDownloadOrchestrator {
  ProfileDownloadOrchestrator({
    required Es9PlusClient es9,
    required Es10Port es10,
    required RspCodec codec,
  }) : _es9 = es9,
       _es10 = es10,
       _codec = codec;

  final Es9PlusClient _es9;
  final Es10Port _es10;
  final RspCodec _codec;

  Future<void> install(String rawActivationCode) async {
    final activation = LpaActivationCode.parse(rawActivationCode);

    final euiccInfo1 = await _es10.getEuiccInfo1();
    final euiccChallenge = await _es10.getEuiccChallenge();

    final initiateRaw = await _es9.initiateAuthentication(
      smdpAddress: activation.smdpAddress,
      euiccChallenge: _codec.encodeBase64(euiccChallenge),
      euiccInfo1: _codec.encodeBase64(euiccInfo1),
    );
    final initiate = _codec.decodeInitiateAuthenticationResponse(initiateRaw);

    final authenticateServerResponse = await _es10.authenticateServer(
      transactionId: initiate.transactionId,
      serverSigned1: initiate.serverSigned1,
      serverSignature1: initiate.serverSignature1,
      euiccCiPkIdToBeUsed: initiate.euiccCiPkIdToBeUsed,
      serverCertificate: initiate.serverCertificate,
    );

    final authenticateClientRaw = await _es9.authenticateClient(
      smdpAddress: activation.smdpAddress,
      transactionId: _codec.encodeBase64(initiate.transactionId),
      authenticateServerResponse: _codec.encodeBase64(
        authenticateServerResponse,
      ),
    );
    final authenticateClient = _codec.decodeAuthenticateClientResponse(
      authenticateClientRaw,
    );

    _requireSameTransaction(
      initiate.transactionId,
      authenticateClient.transactionId,
    );

    final prepareDownloadResponse = await _es10.prepareDownload(
      smdpSigned2: authenticateClient.smdpSigned2,
      smdpSignature2: authenticateClient.smdpSignature2,
      smdpCertificate: authenticateClient.smdpCertificate,
      confirmationCode: activation.confirmationCode,
    );

    final boundProfileRaw = await _es9.getBoundProfilePackage(
      smdpAddress: activation.smdpAddress,
      transactionId: _codec.encodeBase64(authenticateClient.transactionId),
      prepareDownloadResponse: _codec.encodeBase64(prepareDownloadResponse),
    );
    final boundProfile = _codec.decodeBoundProfilePackageResponse(
      boundProfileRaw,
    );

    await _es10.loadBoundProfilePackage(boundProfile.boundProfilePackage);
  }

  void _requireSameTransaction(Uint8List first, Uint8List second) {
    if (first.length != second.length) {
      throw const FormatException('RSP transaction ID changed unexpectedly.');
    }
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) {
        throw const FormatException('RSP transaction ID changed unexpectedly.');
      }
    }
  }
}
