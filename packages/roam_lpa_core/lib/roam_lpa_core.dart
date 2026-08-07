/// Transport-neutral LPA contracts shared by Roam2World transports.
library;

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

/// Low-level eUICC channel contract used by an embedded Nekoko adapter.
///
/// This intentionally contains no UI, scanner, database, BLE or notification
/// dependencies. Nekoko ProfileManager/APDU logic can be moved behind this
/// boundary incrementally without coupling Roam2World to the full nlpa2 app.
abstract interface class EuiccChannel {
  Future<void> open();
  Future<List<int>> transmit(List<int> apdu);
  Future<void> close();
}
