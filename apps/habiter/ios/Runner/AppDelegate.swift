import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var personalSyncChannel: FlutterMethodChannel?
  private var pendingPersonalSyncCallback: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
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
      personalSyncChannel = FlutterMethodChannel(
        name: "com.habiter.app/personal_sync_handoff",
        binaryMessenger: controller.binaryMessenger
      )
      personalSyncChannel?.setMethodCallHandler { [weak self] call, result in
        if call.method == "consumeInitialCallback" {
          result(self?.consumePersonalSyncCallback())
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if acceptPersonalSyncCallback(url) { return true }
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = userActivity.webpageURL, acceptPersonalSyncCallback(url) {
      return true
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  private func acceptPersonalSyncCallback(_ url: URL) -> Bool {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let verified = components?.scheme == "https" &&
      components?.host == "mobile.habiter.dev" &&
      components?.path == "/auth/callback"
    let fallback = components?.scheme == "dev.habiter.app" &&
      components?.host == "auth" &&
      components?.path == "/callback"
    guard verified || fallback else { return false }
    pendingPersonalSyncCallback = url.absoluteString
    personalSyncChannel?.invokeMethod("callback", arguments: url.absoluteString)
    return true
  }

  private func consumePersonalSyncCallback() -> String? {
    defer { pendingPersonalSyncCallback = nil }
    return pendingPersonalSyncCallback
  }
}
