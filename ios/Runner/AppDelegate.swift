import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let lpaChannelName = "com.roam2world.mobile/lpa"
  private let nekokoStoreURL = URL(string: "https://apps.apple.com/app/nekokolpa-2/id6757540723")!

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: lpaChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getCapability":
        // iOS does not expose a general-purpose third-party LPA/eUICC APDU API.
        // NekokoLPA is still available as an external card-reader based LPA.
        let nekokoAvailable = self.canOpenNekoko()
        result([
          "platform": "ios",
          "esimSupported": false,
          "directInstallSupported": false,
          "transport": nekokoAvailable ? "nekoko_deeplink" : "none",
          "nekokoAvailable": nekokoAvailable,
          "reason": nekokoAvailable
            ? "NekokoLPA2 can receive this activation code. A supported card reader is required on iOS."
            : "NekokoLPA2 is not installed. Install it from the App Store to use a supported external eUICC reader.",
        ])
      case "openNekoko":
        self.openNekoko(result: result)
      case "handoffToNekoko":
        let arguments = call.arguments as? [String: Any]
        let activationCode = (arguments?["activationCode"] as? String) ?? ""
        self.handoffToNekoko(activationCode: activationCode, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func canOpenNekoko() -> Bool {
    guard let probeURL = URL(string: "lpa:1$example.invalid$probe") else { return false }
    return UIApplication.shared.canOpenURL(probeURL)
  }

  private func openNekoko(result: @escaping FlutterResult) {
    let targetURL = canOpenNekoko() ? URL(string: "lpa:")! : nekokoStoreURL
    UIApplication.shared.open(targetURL, options: [:]) { opened in
      if opened {
        result(["status": "opened", "transport": self.canOpenNekoko() ? "nekoko_app" : "app_store"])
      } else {
        result(FlutterError(code: "NEKOKO_UNAVAILABLE", message: "NekokoLPA2 could not be opened.", details: nil))
      }
    }
  }

  private func handoffToNekoko(activationCode: String, result: @escaping FlutterResult) {
    let trimmed = activationCode.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      result(FlutterError(code: "INVALID_ACTIVATION_CODE", message: "Activation code is empty.", details: nil))
      return
    }
    guard canOpenNekoko() else {
      result(FlutterError(code: "NEKOKO_UNAVAILABLE", message: "NekokoLPA2 is not installed or cannot handle LPA links.", details: nil))
      return
    }

    let normalized = trimmed.lowercased().hasPrefix("lpa:") ? trimmed : "LPA:\(trimmed)"
    guard let url = URL(string: normalized) else {
      result(FlutterError(code: "INVALID_ACTIVATION_CODE", message: "Activation code is not a valid LPA link.", details: nil))
      return
    }
    UIApplication.shared.open(url, options: [:]) { opened in
      if opened {
        result(["status": "handed_off", "transport": "nekoko_deeplink"])
      } else {
        result(FlutterError(code: "NEKOKO_LAUNCH_FAILED", message: "NekokoLPA2 could not receive the activation code.", details: nil))
      }
    }
  }
}
