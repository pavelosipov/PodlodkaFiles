import Foundation

extension RamState.Tables {
  struct Nodes: Codable {
    struct Entity: Codable {
      struct File: Codable {
        var atime: Date
        var mtime: Date
        var size: NodeSize
      }

      struct Folder: Codable {}

      enum Details: Codable {
        case file(details: File)
        case folder(details: Folder)
      }

      var parentId: NodeId
      var id: NodeId
      var details: Details
      var name: String
    }

    private(set) var entities: [NodeId: Entity] = [:]

    func contains(id: NodeId) -> Bool {
      entities.contains { entityId, _ in entityId == id }
    }

    mutating func reset(with rootNode: NodeDto) {
      entities = rootNode.reduce(
        into: [NodeId: Entity](),
        parentId: .rootParentId
      ) { nodes, dto, parentId in
        let entity = Entity(from: dto, parentId: parentId)
        nodes[entity.id] = entity
      }
    }
  }
}

extension RamState.Tables.Nodes.Entity {
  init(from dto: NodeDto, parentId: NodeId) {
    self.parentId = parentId
    id = dto.id
    name = dto.name
    details = Details(from: dto.details)
  }
}

extension RamState.Tables.Nodes.Entity.Details {
  init(from dto: NodeDto.Details) {
    switch dto {
    case let .file(details):
      self = .file(details: .init(from: details))
    case .folder:
      self = .folder(details: .init())
    }
  }
}

extension RamState.Tables.Nodes.Entity.File {
  init(from dto: NodeDto.File) {
    atime = dto.atime
    mtime = dto.mtime
    size = dto.size
  }
}

// MARK - Codable

extension RamState.Tables.Nodes.Entity.Details {
  init(from decoder: Decoder) throws {
    if let details = try? RamState.Tables.Nodes.Entity.File(from: decoder) {
      self = .file(details: details)
    } else if let details = try? RamState.Tables.Nodes.Entity.Folder(from: decoder) {
      self = .folder(details: details)
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription:"Cannot decode \(Self.self)"
        )
      )
    }
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case let .file(meta):
      try meta.encode(to: encoder)
    case let .folder(meta):
      try meta.encode(to: encoder)
    }
  }
}
