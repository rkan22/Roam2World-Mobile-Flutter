/// Transport-neutral LPA contracts shared by Roam2World transports.
library;

export 'src/activation_code.dart';
export 'src/apdu_es10_port.dart';
export 'src/apdu_session.dart';
export 'src/der_tlv.dart';
export 'src/es10_command_codec.dart';
export 'src/es10_port.dart';
export 'src/es9_client.dart';
export 'src/euicc_channel.dart';
export 'src/json_rsp_codec.dart';
export 'src/profile_download_orchestrator.dart';
export 'src/rsp_codec.dart';
export 'src/sgp22_bpp_decomposer.dart';
export 'src/sgp22_es10_bootstrap_codec.dart';
export 'src/sgp22_store_data.dart';

enum LpaTransportKind { androidSystem, nekokoExternal, nekokoEmbedded }

enum LpaInstallState { unsupported, ready, handedOff, awaitingConsent, installing, installed, failed }

class LpaCapability {
  const LpaCapability({required this.transport, required this.available, this.reason});
  final LpaTransportKind transport;
  final bool available;
  final String? reason;
}

class LpaInstallRequest {
  const LpaInstallRequest({required this.activationCode, this.confirmationCode});
  final String activationCode;
  final String? confirmationCode;
}

class LpaInstallResult {
  const LpaInstallResult({required this.state, this.message});
  final LpaInstallState state;
  final String? message;

  bool get terminal => state == LpaInstallState.installed || state == LpaInstallState.failed || state == LpaInstallState.unsupported;
}

abstract interface class LpaTransport {
  LpaTransportKind get kind;
  Future<LpaCapability> capability();
  Future<LpaInstallResult> install(LpaInstallRequest request);
}
