import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    setupCookieChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupCookieChannel() {
    guard let registrar = registrar(forPlugin: "AcilfovCookies") else { return }
    let channel = FlutterMethodChannel(
      name: "acilfov/cookies",
      binaryMessenger: registrar.messenger()
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
