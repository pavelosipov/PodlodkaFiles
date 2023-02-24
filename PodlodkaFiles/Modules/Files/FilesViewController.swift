import Combine
import UIKit

final class FilesViewController: UITableViewController {
  enum Model {
    case folder(node: FolderDetails?)
    case favorites(nodes: [Node])
  }

  private var subscriptions = Set<AnyCancellable>()
  private var model: Model
  private var nodes: [Node]
  private let stateUpdater: StateUpdater
  private let filesLoader: FilesLoader

  init(model: Model, stateUpdater: StateUpdater, filesLoader: FilesLoader) {
    self.model = model
    self.nodes = model.nodes
    self.stateUpdater = stateUpdater
    self.filesLoader = filesLoader

    super.init(nibName: nil, bundle: nil)

    stateUpdater.updatesPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.updateContent(state: $0) }
      .store(in: &subscriptions)

    let refreshButton = UIBarButtonItem(
      barButtonSystemItem: .refresh,
      target: self,
      action: #selector(loadContent)
    )
    navigationItem.setRightBarButton(refreshButton, animated: false)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.nodeCellIdentifier)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - UITableViewController

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let node = nodes[indexPath.row]
    guard case let .folder(details) = node.details else { return }
    let subfolderViewController = Self(
      model: .folder(node: details),
      stateUpdater: stateUpdater,
      filesLoader: filesLoader
    )
    subfolderViewController.title = node.name
    navigationController?.pushViewController(subfolderViewController, animated: true)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    nodes.count
  }

  override func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: Self.nodeCellIdentifier,
      for: indexPath
    )
    let node = nodes[indexPath.row]
    switch node.details {
    case .file:
      cell.imageView?.image = UIImage(systemName: node.isFavorite ? "doc.fill" : "doc")
    case .folder:
      cell.imageView?.image = UIImage(systemName: node.isFavorite ? "folder.fill" : "folder")
    }
    cell.textLabel?.text = node.name
    cell.selectionStyle = .none
    return cell
  }

  override func tableView(
    _ tableView: UITableView,
    contextMenuConfigurationForRowAt indexPath: IndexPath,
    point: CGPoint
  ) -> UIContextMenuConfiguration? {
    let node = nodes[indexPath.row]
    let favorited = node.isFavorite
    let favorite = UIAction(
      title: favorited ? "Unfavorite" : "Favorite",
      image: UIImage(systemName: favorited ? "heart" : "heart.fill")
    ) { [weak self] _ in
      self?.toggleFavoriteStatus(for: node)
    }
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
      UIMenu(title: "", children: [favorite])
    }
  }

  private func toggleFavoriteStatus(for node: Node) {
    let actionPublisher = node.isFavorite
      ? stateUpdater.unfavoriteNode(id: node.id)
      : stateUpdater.favoriteNode(id: node.id, at: Date())
    actionPublisher
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          if case let .failure(error) = completion {
            self?.showMessage("State Error", description: error.localizedDescription)
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &self.subscriptions)
  }

  // MARK: - Private

  private func updateContent(state: State) {
    if let model = state.actualModel(for: model) {
      self.model = model
      nodes = model.nodes
      tableView.reloadData()
    } else {
      showMessage("Warning", description: "Collection of nodes no longer exists")
    }
  }

  @objc
  private func loadContent() {
    filesLoader.loadFiles()
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          if case let .failure(error) = completion {
            self?.showMessage("Refresh Error", description: error.localizedDescription)
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &subscriptions)
  }

  private static let nodeCellIdentifier = "NodeCell"
}

extension FilesViewController.Model {
  var nodes: [Node] {
    switch self {
    case let .folder(folder): return folder?.children ?? []
    case let .favorites(nodes): return nodes
    }
  }
}

private extension State {
  func actualModel(for model: FilesViewController.Model) -> FilesViewController.Model? {
    switch model {
    case let .folder(folder):
      switch node(with: folder?.id ?? NodeId.rootId)?.details {
      case .none, .file:
        return nil
      case let .folder(folder):
        return .folder(node: folder)
      }
    case .favorites:
      return .favorites(nodes: favoriteNodes)
    }
  }
}
