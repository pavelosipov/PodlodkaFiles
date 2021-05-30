import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  let assembly = Assembly()
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.backgroundColor = .white
    window?.rootViewController = assembly.appViewController
    window?.makeKeyAndVisible()
    return true
  }
}
