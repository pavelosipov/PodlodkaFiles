import Foundation
import UIKit

typealias PersistableAccount = PersistableValue<Account?>
typealias PersistableState = PersistableValue<RamState>

final class Assembly {
  var appViewController: UIViewController {
    AppViewController(
      accountDb: accountDb,
      makeAuthenticationViewController: { [unowned self] in
        self.authenticationViewController
      },
      makeMainViewController: { [unowned self] in
        self.mainViewController
      }
    )
  }

  // MARK: - Private

  private lazy var accountDb: PersistableAccount = {
    let valueStore = PersistentValueStore<Account?>(
      store: KeychainDataStore(
        service: "io.podlodka.account.v1",
        key: "account"
      )
    ).eraseToAnyValueStore()
    return .init(
      value: (try? valueStore.load()) ?? nil,
      valueStore: valueStore
    )
  }()

  private lazy var ramState: PersistableState = {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent("state.plist")
    let valueStore = PersistentValueStore<RamState>(
      store: FileDataStore(pathURL: path)
    ).eraseToAnyValueStore()
    var state: RamState
    if let savedState = try? valueStore.load() {
      state = savedState
    } else {
      state = RamState()
    }
    return PersistableState(value: state, valueStore: valueStore)
  }()

  private lazy var ramStateUpdater: RamStateUpdater = {
    RamStateUpdater(state: ramState)
  }()

  private lazy var dbState: DbState = {
    do {
      let fs = FileManager.default
      let path = fs.temporaryDirectory.appendingPathComponent("statedb")
      if !fs.fileExists(atPath: path.path) {
        try fs.createDirectory(at: path, withIntermediateDirectories: false, attributes: nil)
      }
      let state = try PCRState(path: path.path)
      return DbState(state: state)
    } catch {
      fatalError()
    }
  }()

  private lazy var dbStateUpdater: DbStateUpdater = {
    DbStateUpdater(state: dbState)
  }()

  private var state: State { ramState.value }
  private var stateUpdater: StateUpdater { ramStateUpdater }

  private lazy var authencticator: Authencticator = {
    Authencticator(accountDb: accountDb)
  }()

  private lazy var filesLoader: FilesLoader = {
    FilesLoader(accountDb: accountDb, statesUpdater: stateUpdater)
  }()

  private var authenticationViewController: UIViewController {
    AuthenticationViewController( authencticator: authencticator)
  }

  private var mainViewController: UIViewController {
    let controller = UITabBarController()
    controller.viewControllers = [
      filesViewController,
      favoritesViewController,
      profileViewController
    ]
    return controller
  }

  private var filesViewController: UIViewController {
    let controller = FilesViewController(
      model: .folder(node: state.rootFolder),
      stateUpdater: stateUpdater,
      filesLoader: filesLoader
    )
    controller.title = "Everything"
    controller.tabBarItem = UITabBarItem(
      title: "Everything",
      image: UIImage(systemName: "folder"),
      selectedImage: UIImage(systemName: "folder.fill")
    )
    return UINavigationController(rootViewController: controller)
  }

  private var favoritesViewController: UIViewController {
    let controller = FilesViewController(
      model: .favorites(nodes: state.favoriteNodes),
      stateUpdater: stateUpdater,
      filesLoader: filesLoader
    )
    controller.title = "Favorites"
    controller.tabBarItem = UITabBarItem(
      title: "Favorites",
      image: UIImage(systemName: "heart"),
      selectedImage: UIImage(systemName: "heart.fill")
    )
    return UINavigationController(rootViewController: controller)
  }

  private var profileViewController: UIViewController {
    let controller = ProfileViewController(accountDb: accountDb)
    controller.title = "Profile"
    controller.tabBarItem = UITabBarItem(
      title: "Profile",
      image: UIImage(systemName: "person"),
      selectedImage: UIImage(systemName: "person.fill")
    )
    return controller
  }
}
