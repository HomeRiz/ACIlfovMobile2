import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // Overlay afisat cand aplicatia intra in fundal/app switcher, ca sa nu
  // apara date sensibile (facturi, sold, index) in snapshot-ul de sistem.
  private var privacyOverlay: UIView?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard
      let windowScene = scene as? UIWindowScene,
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
    else {
      return
    }

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = FlutterViewController(
      engine: appDelegate.flutterEngine,
      nibName: nil,
      bundle: nil
    )
    self.window = window
    window.makeKeyAndVisible()

    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    showPrivacyOverlay()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    hidePrivacyOverlay()
  }

  private func showPrivacyOverlay() {
    guard let window = window, privacyOverlay == nil else { return }

    let overlay = UIView(frame: window.bounds)
    overlay.backgroundColor = .white
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    let logo = UIImageView(image: UIImage(named: "LaunchImage"))
    logo.contentMode = .scaleAspectFit
    logo.translatesAutoresizingMaskIntoConstraints = false
    overlay.addSubview(logo)
    NSLayoutConstraint.activate([
      logo.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
      logo.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
      logo.widthAnchor.constraint(equalToConstant: 96),
      logo.heightAnchor.constraint(equalToConstant: 96),
    ])

    window.addSubview(overlay)
    privacyOverlay = overlay
  }

  private func hidePrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }
}
