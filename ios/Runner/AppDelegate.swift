import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let lpaChannelName = "com.roam2world.mobile/lpa"

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
      guard call.method == "getCapability" else {
        result(FlutterMethodNotImplemented)
        return
      }

      // iOS does not expose a general-purpose third-party LPA/eUICC APDU API.
      // Keep this conservative until an Apple-supported entitlement/API path is available.
      result([
        "platform": "ios",
        "esimSupported": false,
        "directInstallSupported": false,
        "reason": "Direct third-party LPA installation is not enabled for this iOS build. Use the system-supported activation flow.",
      ])
    }
  }
}
