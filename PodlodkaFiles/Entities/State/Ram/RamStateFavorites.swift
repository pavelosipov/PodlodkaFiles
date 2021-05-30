import Foundation

extension RamState.Tables {
  struct Favorites: Codable {
    struct Entity: Codable {
      // MARK: - Key
      var time: Date

      // MARK: - Value
      var id: NodeId
    }

    private(set) var entities: [Entity] = []

    func contains(id: NodeId) -> Bool {
      entities.contains { $0.id == id }
    }

    mutating func insert(_ entity: Entity) {
      let index = entities.partitioningIndex { entity < $0 }
      entities.insert(entity, at: index)
    }

    mutating func remove(where predicate: (Entity) -> Bool) {
      entities.removeAll(where: predicate)
    }
  }
}

extension RamState.Tables.Favorites.Entity: Comparable {
  static func < (
    lhs: RamState.Tables.Favorites.Entity,
    rhs: RamState.Tables.Favorites.Entity
  ) -> Bool {
    lhs.time < rhs.time
  }
}
