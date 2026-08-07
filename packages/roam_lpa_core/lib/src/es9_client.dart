import 'dart:convert';
import 'dart:io';

/// Minimal ES9+ HTTP boundary extracted from the Nekoko service shape.
/// Protocol ASN.1 payloads remain opaque base64 strings at this layer.
abstract interface class Es9PlusClient {
  Future<Map<String, dynamic>> initiateAuthentication({
    required String smdpAddress,
    required String euiccChallenge,
    required String euiccInfo1,
  });

  Future<Map<String, dynamic>> authenticateClient({
    required String smdpAddress,
    required String transactionId,
    required String authenticateServerResponse,
  });

  Future<Map<String, dynamic>> getBoundProfilePackage({
    required String smdpAddress,
    required String transactionId,
    required String prepareDownloadResponse,
  });
}

/// Dependency-light implementation using dart:io so the core package does not
/// pull the Nekoko application's networking stack into Roam2World.
class HttpEs9PlusClient implements Es9PlusClient {
  HttpEs9PlusClient({HttpClient? client}) : _client = client ?? HttpClient();
  final HttpClient _client;

  @override
  Future<Map<String, dynamic>> initiateAuthentication({required String smdpAddress, required String euiccChallenge, required String euiccInfo1}) =>
      _post(smdpAddress, 'initiateAuthentication', {
        'euiccChallenge': euiccChallenge,
        'euiccInfo1': euiccInfo1,
        'smdpAddress': smdpAddress,
      });

  @override
  Future<Map<String, dynamic>> authenticateClient({required String smdpAddress, required String transactionId, required String authenticateServerResponse}) =>
      _post(smdpAddress, 'authenticateClient', {
        'transactionId': transactionId,
        'authenticateServerResponse': authenticateServerResponse,
      });

  @override
  Future<Map<String, dynamic>> getBoundProfilePackage({required String smdpAddress, required String transactionId, required String prepareDownloadResponse}) =>
      _post(smdpAddress, 'getBoundProfilePackage', {
        'transactionId': transactionId,
        'prepareDownloadResponse': prepareDownloadResponse,
      });

  Future<Map<String, dynamic>> _post(String host, String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.https(host, '/gsma/rsp2/es9plus/$endpoint');
    final request = await _client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.headers.set('X-Admin-Protocol', 'gsma/rsp/v2.2.0');
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('ES9+ $endpoint failed (${response.statusCode}).', uri: uri);
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) throw const FormatException('Invalid ES9+ response.');
    return decoded;
  }
}
