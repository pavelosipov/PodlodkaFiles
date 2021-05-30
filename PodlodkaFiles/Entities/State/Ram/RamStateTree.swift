import Algorithms
import Foundation

extension RamState.Tables {
  struct Tree: Codable {
    struct Entity: Codable {
      enum NodeType: Int, Codable {
        case file
        case folder
      }

      // MARK: - Key
      var parentId: NodeId
      var type: NodeType
      var name: String

      // MARK: - Value
      var id: NodeId
    }

    private(set) var entities: [Entity] = []

    func entities(with parentId: NodeId) -> ArraySlice<Entity> {
      let pivot = Entity(parentId: parentId, type: .folder, name: "", id: 0)
      let index = entities.partitioningIndex { pivot < $0 }
      guard index < entities.endIndex else { return .init() }
      return entities[index...].prefix { $0.parentId == parentId }
    }

    mutating func reset(with rootNode: NodeDto) {
      var entities = rootNode.reduce(
        into: [Entity](),
        parentId: .rootParentId
      ) { entities, dto, parentId in
        entities.append(Entity(from: dto, parentId: parentId))
      }
      entities.sort(by: <)
      self.entities = entities
    }
  }
}

extension RamState.Tables.Tree.Entity: Comparable {
  static func < (lhs: RamState.Tables.Tree.Entity, rhs: RamState.Tables.Tree.Entity) -> Bool {
    if lhs.parentId != rhs.parentId {
      return lhs.parentId < rhs.parentId
    }
    switch (lhs.type, rhs.type) {
    case (.folder, .file): return true
    case (.file, .folder): return false
    default: break
    }
    return lhs.name < rhs.name
  }
}

extension RamState.Tables.Tree.Entity {
  init(from dto: NodeDto, parentId: NodeId) {
    self.parentId = parentId
    id = dto.id
    name = dto.name
    type = NodeType(from: dto.details)
  }
}

extension RamState.Tables.Tree.Entity.NodeType {
  init(from dto: NodeDto.Details) {
    switch dto {
    case .file: self = .file
    case .folder: self = .folder
    }
  }
}

extension NodeId {
  static let rootParentId = NodeId(0)
  static let rootId = NodeId(1)
}
