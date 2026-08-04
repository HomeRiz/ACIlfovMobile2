import Flutter
import UIKit
import UserNotifications
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  lazy var flutterEngine = FlutterEngine(name: "ApaIlfovEngine")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    setupCookieChannel(binaryMessenger: flutterEngine.binaryMessenger)
    setupSystemChannel(binaryMessenger: flutterEngine.binaryMessenger)

    // Cerut de flutter_local_notifications: fara acest delegate, reamintirile
    // recuperate de "cainele de paza" nu se afiseaza cand aplicatia e deschisa.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Ecranele de setari ale sistemului. Pe iOS totul (notificari incluse) se
  // deschide din pagina aplicatiei din Setari.
  private func setupSystemChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "acilfov/system",
      binaryMessenger: binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "openNotificationSettings", "openBatterySettings":
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url)
        else {
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setupCookieChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "acilfov/cookies",
      binaryMessenger: binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      let store = WKWebsiteDataStore.default().httpCookieStore

      switch call.method {
      case "getCookies":
        store.getAllCookies { cookies in
          let relevant = cookies.filter { $0.domain.contains("emsys.ro") }
          let header = relevant.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
          result(header)
        }

      case "setCookies":
        guard
          let args = call.arguments as? [String: Any],
          let cookieStr = args["cookies"] as? String
        else {
          result(false)
          return
        }

        let group = DispatchGroup()
        for pair in cookieStr.components(separatedBy: "; ") where !pair.isEmpty {
          let kv = pair.components(separatedBy: "=")
          guard kv.count >= 2 else { continue }
          let name = kv[0]
          let value = kv.dropFirst().joined(separator: "=")
          if let cookie = HTTPCookie(properties: [
            .domain: "acilfov.emsys.ro",
            .path: "/",
            .name: name,
            .value: value,
            .secure: "TRUE",
            HTTPCookiePropertyKey("HttpOnly"): "TRUE",
            .expires: Date(timeIntervalSinceNow: 30 * 24 * 60 * 60),
          ]) {
            group.enter()
            store.setCookie(cookie) { group.leave() }
          }
        }
        group.notify(queue: .main) { result(true) }

      case "clearCookies":
        store.getAllCookies { cookies in
          let group = DispatchGroup()
          for cookie in cookies {
            group.enter()
            store.delete(cookie) { group.leave() }
          }
          group.notify(queue: .main) { result(true) }
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
