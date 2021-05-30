import UIKit
import Combine

final class AuthenticationViewController: UIViewController {
  private var subscriptions = Set<AnyCancellable>()
  private let authencticator: Authencticator

  init(authencticator: Authencticator) {
    self.authencticator = authencticator
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let view = AuthenticationView()
    let action = UIAction { [weak self, weak view] _ in
      guard
        let self = self,
        let name = view?.nameField.text,
        let password = view?.passwordField.text
      else {
        return
      }
      self.authenticate(name: name, password: password)
    }
    view.signInButton.addAction(action, for: .touchUpInside)
    self.view = view
  }

  private func authenticate(name: String, password: String) {
    authencticator
      .authenticate(name: name, password: password)
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          if case let .failure(error) = completion {
            self?.showMessage("Error", description: error.localizedDescription)
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &subscriptions)
  }
}
