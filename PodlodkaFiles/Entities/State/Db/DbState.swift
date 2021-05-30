import Foundation

struct DbState: MutableState {
  private let state: PCRState

  // MARK: - State

  var favoriteNodes: [Node] {
    let snapshot = state.takeSnaphot()
    return snapshot.favoriteNodes.map { DbNode(state: snapshot, model: $0) }
  }

  func node(with id: NodeId) -> Node? {
    let snapshot = state.takeSnaphot()
    if let node = snapshot.node(withId: id.rawValue) {
      return DbNode(state: snapshot, model: node)
    }
    return nil
  }

  // MARK: - MutableState

  mutating func resetNodes(with rootNode: NodeDto) throws {
    let nodes = rootNode.reduce(
      into: [PCRNode](),
      parentId: .rootParentId
    ) { entities, dto, parentId in
      entities.append(PCRNode(
        nodeId: dto.id.rawValue,
        parentId: parentId.rawValue,
        name: dto.name,
        details: .make(from: dto.details)
      ))
    }
    try state.reset(with: nodes)
  }

  mutating func favoriteNode(id: NodeId, at time: Date) throws {
    try state.favoriteNode(withId: id.rawValue, time: time)
  }

  mutating func unfavoriteNode(id: NodeId) throws {
    try state.unfavoriteNode(withId: id.rawValue)
  }

  init(state: PCRState) {
    self.state = state
  }
}

extension PCRNodeDetails {
  static func make(from dto: NodeDto.Details) -> PCRNodeDetails {
    switch dto {
    case let .file(value):
      return PCRFileDetails(
        atime: value.atime,
        mtime: value.mtime,
        size: value.size
      )
    case .folder:
      return PCRFolderDetails()
    }
  }
}
