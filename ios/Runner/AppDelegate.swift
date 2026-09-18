import Flutter
import UIKit
import UserNotifications
import WebKit
import workmanager_apple

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

    // OBLIGATORIU pentru workmanager: BGTaskScheduler accepta o cerere pentru
    // un identificator doar daca handler-ul lui a fost inregistrat aici,
    // inainte ca didFinishLaunching sa returneze. Identificatorul trebuie sa
    // fie identic cu `_invoiceTaskId` din background_sync.dart si cu intrarea
    // din BGTaskSchedulerPermittedIdentifiers (Info.plist).
    //
    // Fara acest apel, primul BackgroundSync.start() (deci si prima pornire
    // a aplicatiei) trimite cererea de programare direct la BGTaskScheduler
    // fara handler inregistrat -> iOS opreste aplicatia cu SIGABRT, indiferent
    // ce face codul Dart (exceptia e la nivel de Objective-C, nu poate fi
    // prinsa de try/catch din Dart).
    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "acilfov-verifica-facturi-periodic")

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

  // Host exact al portalului. Un cookie de tip "host cookie" pentru acest
  // domeniu este stocat de WKWebsiteDataStore fie ca "acilfov.emsys.ro", fie
  // cu punct la inceput ("acilfov.emsys.ro") - de aceea comparam ambele forme,
  // nu doar `contains`, ca sa nu includem accidental subdomenii vecine.
  private let portalCookieDomain = "acilfov.emsys.ro"

  private func isPortalCookie(_ cookie: HTTPCookie) -> Bool {
    cookie.domain == portalCookieDomain || cookie.domain == ".\(portalCookieDomain)"
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
          let relevant = cookies.filter { self.isPortalCookie($0) }
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
          for cookie in cookies where self.isPortalCookie(cookie) {
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
