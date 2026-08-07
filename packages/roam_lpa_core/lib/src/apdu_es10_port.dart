import 'dart:typed_data';

import 'apdu_session.dart';
import 'es10_command_codec.dart';
import 'es10_port.dart';

class ApduEs10Port implements Es10Port {
  ApduEs10Port({required EuiccApduSession session, required Es10CommandCodec codec})
      : _session = session,
        _codec = codec;

  final EuiccApduSession _session;
  final Es10CommandCodec _codec;

  Future<Uint8List> _single(Uint8List command) async {
    return _session.run((s) async => (await s.transmit(command)).data);
  }

  @override
  Future<Uint8List> getEuiccInfo1() async {
    final response = await _single(_codec.encodeGetEuiccInfo1());
    return _codec.decodeGetEuiccInfo1(response);
  }

  @override
  Future<Uint8List> getEuiccChallenge() async {
    final response = await _single(_codec.encodeGetEuiccChallenge());
    return _codec.decodeGetEuiccChallenge(response);
  }

  @override
  Future<Uint8List> authenticateServer({
    required Uint8List transactionId,
    required Uint8List serverSigned1,
    required Uint8List serverSignature1,
    required Uint8List euiccCiPkIdToBeUsed,
    required Uint8List serverCertificate,
  }) async {
    final command = _codec.encodeAuthenticateServer(
      transactionId: transactionId,
      serverSigned1: serverSigned1,
      serverSignature1: serverSignature1,
      euiccCiPkIdToBeUsed: euiccCiPkIdToBeUsed,
      serverCertificate: serverCertificate,
    );
    final response = await _single(command);
    return _codec.decodeAuthenticateServer(response);
  }

  @override
  Future<Uint8List> prepareDownload({
    required Uint8List smdpSigned2,
    required Uint8List smdpSignature2,
    required Uint8List smdpCertificate,
    String? confirmationCode,
  }) async {
    final command = _codec.encodePrepareDownload(
      smdpSigned2: smdpSigned2,
      smdpSignature2: smdpSignature2,
      smdpCertificate: smdpCertificate,
      confirmationCode: confirmationCode,
    );
    final response = await _single(command);
    return _codec.decodePrepareDownload(response);
  }

  @override
  Future<void> loadBoundProfilePackage(Uint8List boundProfilePackage) async {
    final commands = _codec.encodeLoadBoundProfilePackage(boundProfilePackage).toList(growable: false);
    if (commands.isEmpty) throw const FormatException('Bound profile package produced no ES10 APDU commands.');

    await _session.run((s) async {
      for (var i = 0; i < commands.length; i++) {
        final response = await s.transmit(commands[i]);
        _codec.validateLoadBoundProfilePackageResponse(
          response.data,
          last: i == commands.length - 1,
        );
      }
    });
  }
}
