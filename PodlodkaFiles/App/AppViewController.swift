import Combine
import UIKit

final class AppViewController: UIViewController {
  private var subscriptions = Set<AnyCancellable>()
  private let accountDb: PersistableAccount
  private let authenticationViewControllerProvider: () -> UIViewController
  private let mainViewControllerProvider: () -> UIViewController

  init(
    accountDb: PersistableAccount,
    makeAuthenticationViewController: @escaping () -> UIViewController,
    makeMainViewController: @escaping () -> UIViewController
  ) {
    self.accountDb = accountDb
    self.authenticationViewControllerProvider = makeAuthenticationViewController
    self.mainViewControllerProvider = makeMainViewController
    super.init(nibName: nil, bundle: nil)
    setupBindings()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    updateChildViewController()
  }

  private func setupBindings() {
    accountDb.publisher
      .receive(on: DispatchQueue.main)
      .sink { [unowned self] _ in self.updateChildViewController() }
      .store(in: &subscriptions)
  }

  private func updateChildViewController() {
    if accountDb.value == nil {
      resetChild(authenticationViewControllerProvider())
    } else {
      resetChild(mainViewControllerProvider())
    }
  }

  private func resetChild(_ viewController: UIViewController) {
    children.forEach { child in
      child.willMove(toParent: nil)
      child.view.removeFromSuperview()
      child.removeFromParent()
    }
    addChild(viewController)
    view.addSubview(viewController.view)
    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
      viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    viewController.didMove(toParent: self)
  }
}
