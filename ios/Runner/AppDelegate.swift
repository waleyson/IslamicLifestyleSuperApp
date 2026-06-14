import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import DeviceActivity

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.islamiclifestyle.superapp/blocker", binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if (call.method == "isPermissionGranted") {
          if #available(iOS 15.0, *) {
              let status = AuthorizationCenter.shared.authorizationStatus
              result(status == .approved)
          } else {
              result(true)
          }
      } else if (call.method == "requestPermission") {
          if #available(iOS 15.0, *) {
              AuthorizationCenter.shared.requestAuthorization { authResult in
                  switch authResult {
                  case .success:
                      result(true)
                  case .failure(let error):
                      print("Authorization failed: \(error.localizedDescription)")
                      result(false)
                  }
              }
          } else {
              result(true)
          }
      } else if (call.method == "setBlockState") {
          guard let args = call.arguments as? [String: Any],
                let isLocked = args["isLocked"] as? Bool else {
              result(FlutterError(code: "INVALID_ARGUMENTS", message: "isLocked is required", details: nil))
              return
          }
          
          let defaults = UserDefaults.standard
          defaults.set(isLocked, forKey: "is_locked")
          
          if #available(iOS 15.0, *) {
              if isLocked {
                  // In iOS 15+, FamilyControls shields categories selected by the user.
                  // Developers request the shield settings store to block application categories.
                  let store = ManagedSettingsStore()
                  // In a production app, the user picks the categories using FamilyActivityPicker
                  // and we assign the token to: store.shield.applicationCategories
              } else {
                  let store = ManagedSettingsStore()
                  if #available(iOS 15.0, *) {
                      store.clearAllSettings()
                  }
              }
          }
          result(nil)
      } else {
          result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
