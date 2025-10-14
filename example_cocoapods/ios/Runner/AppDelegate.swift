import UIKit
import Flutter
import Contacts

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let permissionChannel = FlutterMethodChannel(name: "contacts_permission",
                                                binaryMessenger: controller.binaryMessenger)
    permissionChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "requestContactsPermission" {
        self.requestContactsPermission(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func requestContactsPermission(result: @escaping FlutterResult) {
    let status = CNContactStore.authorizationStatus(for: .contacts)

    switch status {
    case .authorized:
      result(true)
    case .denied, .restricted:
      result(false)
    case .notDetermined:
      CNContactStore().requestAccess(for: .contacts) { granted, error in
        DispatchQueue.main.async {
          result(granted)
        }
      }
    @unknown default:
      result(false)
    }
  }
}
