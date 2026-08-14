import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let timeZoneChannel = FlutterMethodChannel(
        name: "com.habiter.app/timezone",
        binaryMessenger: controller.binaryMessenger
      )
      timeZoneChannel.setMethodCallHandler { call, result in
        if call.method == "getTimeZoneId" {
          result(TimeZone.current.identifier)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      let settingsChannel = FlutterMethodChannel(
        name: "com.habiter.app/settings",
        binaryMessenger: controller.binaryMessenger
      )
      settingsChannel.setMethodCallHandler { call, result in
        if call.method == "openNotificationSettings",
           let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
