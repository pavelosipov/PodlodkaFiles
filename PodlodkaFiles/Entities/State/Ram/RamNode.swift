import Foundation

struct RamNode: Node {
  struct File: FileDetails {
    private let model: RamState.Tables.Nodes.Entity.File

    var atime: Date { model.atime }
    var mtime: Date { model.mtime }
    var size: NodeSize { model.size }

    init(model: RamState.Tables.Nodes.Entity.File) {
      self.model = model
    }
  }

  struct Folder: FolderDetails {
    private let state: RamState
    private let model: RamState.Tables.Nodes.Entity

    var id: NodeId { model.id }
    var children: [Node] { state.nodes(with: id) }

    init(state: RamState, model: RamState.Tables.Nodes.Entity) {
      self.state = state
      self.model = model
    }
  }

  private let state: RamState
  private let model: RamState.Tables.Nodes.Entity

  var id: NodeId { model.id }
  var name: String { model.name }
  var isFavorite: Bool { state.isFavoriteNode(id: id) }

  var details: NodeDetails {
    switch model.details {
    case let .file(value):
      return .file(details: File(model: value))
    case .folder:
      return .folder(details: Folder(state: state, model: model))
    }
  }

  init(state: RamState, model: RamState.Tables.Nodes.Entity) {
    self.state = state
    self.model = model
  }
}
