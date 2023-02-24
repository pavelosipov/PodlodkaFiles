import Foundation

struct DbNode: Node {
  private let state: PCRStateSnapshot
  private let model: PCRNode

  struct Folder: FolderDetails {
    private let state: PCRStateSnapshot
    private let model: PCRNode

    var id: NodeId { NodeId(rawValue: model.nodeId) }
    var children: [Node] {
      state.nodes(withParentId: model.nodeId).map { child in
        DbNode(state: state, model: child)
      }
    }

    init(state: PCRStateSnapshot, model: PCRNode) {
      self.state = state
      self.model = model
    }
  }

  var id: NodeId { NodeId(rawValue: model.nodeId) }
  var name: String { model.name }
  var isFavorite: Bool { state.isFavoriteNode(withId: model.nodeId) }
  var details: NodeDetails {
    switch model.details {
    case let details as PCRFileDetails:
      return .file(details: details)
    case is PCRFolderDetails:
      return .folder(details: Folder(state: state, model: model))
    default:
      fatalError("Unknown type: \(model.details.type)")
    }
  }

  init(state: PCRStateSnapshot, model: PCRNode) {
    self.state = state
    self.model = model
  }
}

extension PCRFileDetails: FileDetails {}
