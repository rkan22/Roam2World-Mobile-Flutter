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
      switch call.method {
      case "getCapability":
        result([
          "platform": "ios",
          "esimSupported": false,
          "directInstallSupported": false,
          "transport": "nekoko_embedded",
          "nekokoAvailable": true,
          "reason": "The integrated NekokoLPA2 reader flow is available. A supported card reader is required on iOS.",
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
