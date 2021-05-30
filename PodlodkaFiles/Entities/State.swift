import Foundation

protocol State {
  var favoriteNodes: [Node] { get }
  func node(with id: NodeId) -> Node?
}

protocol MutableState: State {
  mutating func resetNodes(with rootNode: NodeDto) throws
  mutating func favoriteNode(id: NodeId, at time: Date) throws
  mutating func unfavoriteNode(id: NodeId) throws
}

extension State {
  var rootFolder: FolderDetails? {
    let node = node(with: .rootId)
    guard case let .folder(folder) = node?.details else {
      return nil
    }
    return folder
  }
}
