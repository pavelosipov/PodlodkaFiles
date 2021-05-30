import Combine
import UIKit

class ProfileViewController: UIViewController {
  private let accountDb: PersistableAccount
  private var resetCancellable: AnyCancellable?

  init(accountDb: PersistableAccount) {
    self.accountDb = accountDb
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let view = ProfileView()
    let action = UIAction { [weak self] _ in
      guard let self = self else { return }
      self.resetCancellable = self.accountDb.reset()
        .receive(on: DispatchQueue.main)
        .sink(
          receiveCompletion: { [weak self] completion in
            if case let .failure(error) = completion {
              self?.showMessage("Error", description: error.localizedDescription)
            }
          },
          receiveValue: { _ in }
        )
    }
    view.nameLabel.text = accountDb.value?.name
    view.signOutButton.addAction(action, for: .touchUpInside)
    self.view = view
  }
}
