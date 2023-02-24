import UIKit

extension UIViewController {
  func showMessage(_ title: String, description: String? = nil) {
    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
      self.dismiss(animated: true, completion: nil)
    }))
    present(alert, animated: true, completion: nil)
  }
}
