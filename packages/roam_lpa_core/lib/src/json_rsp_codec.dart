import 'dart:convert';
import 'dart:typed_data';

import 'der_tlv.dart';
import 'rsp_codec.dart';

class JsonRspCodec implements RspCodec {
  JsonRspCodec({DerReader reader = const DerReader()}) : _reader = reader;
  final DerReader _reader;

  @override
  String encodeBase64(Uint8List bytes) => base64Encode(bytes);

  @override
  Uint8List decodeBase64(String value) {
    try {
      return Uint8List.fromList(base64Decode(value));
    } on FormatException {
      throw const FormatException('Invalid base64 RSP payload.');
    }
  }

  @override
  InitiateAuthDecoded decodeInitiateAuthenticationResponse(Map<String, dynamic> response) {
    final body = _body(response);
    _requireSuccess(body);
    final transactionId = _bytes(body, ['transactionId']);
    final serverSigned1 = _asn1(body, ['serverSigned1']);
    final serverSignature1 = _bytes(body, ['serverSignature1']);
    final ci = _bytes(body, ['euiccCiPkIdToBeUsed']);
    final cert = _asn1(body, ['serverCertificate', 'serverCertificateInfo']);
    return InitiateAuthDecoded(
      transactionId: transactionId,
      serverSigned1: serverSigned1,
      serverSignature1: serverSignature1,
      euiccCiPkIdToBeUsed: ci,
      serverCertificate: cert,
    );
  }

  @override
  AuthenticateClientDecoded decodeAuthenticateClientResponse(Map<String, dynamic> response) {
    final body = _body(response);
    _requireSuccess(body);
    final ok = _map(body['authenticateClientOk']) ?? body;
    return AuthenticateClientDecoded(
      transactionId: _bytes(body, ['transactionId']),
      smdpSigned2: _asn1(ok, ['smdpSigned2']),
      smdpSignature2: _bytes(ok, ['smdpSignature2']),
      smdpCertificate: _asn1(ok, ['smdpCertificate']),
    );
  }

  @override
  BoundProfileDecoded decodeBoundProfilePackageResponse(Map<String, dynamic> response) {
    final body = _body(response);
    _requireSuccess(body);
    return BoundProfileDecoded(boundProfilePackage: _asn1(body, ['boundProfilePackage']));
  }

  Map<String, dynamic> _body(Map<String, dynamic> response) {
    for (final key in ['result', 'response', 'data']) {
      final nested = _map(response[key]);
      if (nested != null) return nested;
    }
    return response;
  }

  void _requireSuccess(Map<String, dynamic> body) {
    final status = body['functionExecutionStatus'];
    if (status == null) return;
    final text = status is String ? status : (_map(status)?['status']?.toString());
    if (text != null && text != 'Executed-Success') {
      throw FormatException('RSP function failed: $text');
    }
  }

  Uint8List _asn1(Map<String, dynamic> body, List<String> keys) {
    final bytes = _bytes(body, keys);
    _reader.readSingle(bytes);
    return bytes;
  }

  Uint8List _bytes(Map<String, dynamic> body, List<String> keys) {
    for (final key in keys) {
      final value = body[key];
      if (value is String && value.isNotEmpty) return decodeBase64(value);
      final nested = _map(value);
      if (nested != null) {
        for (final nestedKey in ['value', 'data', 'encoded']) {
          final encoded = nested[nestedKey];
          if (encoded is String && encoded.isNotEmpty) return decodeBase64(encoded);
        }
      }
    }
    throw FormatException('Missing RSP field: ${keys.join(' / ')}');
  }

  Map<String, dynamic>? _map(dynamic value) => value is Map<String, dynamic> ? value : value is Map ? Map<String, dynamic>.from(value) : null;
}
