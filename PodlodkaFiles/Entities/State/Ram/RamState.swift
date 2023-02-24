import Combine
import Foundation

struct RamState: State, Codable {
  private var nodes = Tables.Nodes()
  private var tree = Tables.Tree()
  private var favorites = Tables.Favorites()

  mutating func resetNodes(with rootNode: NodeDto) {
    nodes.reset(with: rootNode)
    tree.reset(with: rootNode)
    favorites.remove { _ in true }
  }

  func node(with id: NodeId) -> Node? {
    guard let nodeEntity = nodes.entities[id] else { return nil }
    return RamNode(state: self, model: nodeEntity)
  }

  func nodes(with parentId: NodeId) -> [Node] {
    tree.entities(with: parentId).map { child in
      RamNode(state: self, model: self.nodes.entities[child.id]!)
    }
  }

  func isFavoriteNode(id: NodeId) -> Bool {
    favorites.contains(id: id)
  }

  var favoriteNodes: [Node] {
    favorites.entities.compactMap {
      node(with: $0.id)
    }
  }

  mutating func favoriteNode(id: NodeId, at time: Date) throws {
    guard nodes.contains(id: id) else { throw Self.Error.nodeNotFound }
    guard !favorites.contains(id: id) else { return }
    favorites.insert(.init(time: time, id: id))
  }

  mutating func unfavoriteNode(id: NodeId) throws {
    guard favorites.contains(id: id) else { return }
    favorites.remove { $0.id == id }
  }
}

extension RamState {
  enum Error: Swift.Error {
    case stateUnavailable
    case nodeNotFound
  }
}

extension RamState {
  enum Tables {}
}
