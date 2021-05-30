import Foundation

protocol ValueStore {
  associatedtype Value
  func save(value: Value) throws
  func load() throws -> Value?
  func erase() throws
}

final class PersistentValueStore<Value: Codable>: ValueStore {
  private let store: DataStore

  init(store: DataStore) {
    self.store = store
  }

  // MARK: - ValueStore

  func save(value: Value) throws {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let data = try encoder.encode(value)
    try store.save(data: data)
  }

  func load() throws -> Value? {
    guard let data = try store.load() else {
      return nil
    }
    let decoder = PropertyListDecoder()
    do {
      return try decoder.decode(Value.self, from: data)
    } catch {
      print(error)
      try? store.erase()
      throw error
    }
  }

  func erase() throws {
    try store.erase()
  }
}

final class EphemeralValueStore<Value>: ValueStore {
  private var value: Value?

  init(value: Value?) {
    self.value = value
  }

  // MARK: - ValueStore

  func save(value: Value) throws {
    self.value = value
  }

  func load() throws -> Value? {
    return value
  }

  func erase() throws {
    value = nil
  }
}

final class AnyValueStore<Value>: ValueStore {
  private let saver: (Value) throws -> Void
  private let loader: () throws -> Value?
  private let eraser: () throws -> Void

  init(
    saver: @escaping (Value) throws -> Void,
    loader: @escaping () throws -> Value?,
    eraser: @escaping () throws -> Void
  ) {
    self.saver = saver
    self.loader = loader
    self.eraser = eraser
  }

  // MARK: - ValueStore

  func save(value: Value) throws { try saver(value) }
  func load() throws -> Value? { try loader() }
  func erase() throws { try eraser() }
}

extension ValueStore {
  func eraseToAnyValueStore() -> AnyValueStore<Value> {
    AnyValueStore(
      saver: { try self.save(value: $0) },
      loader: { try self.load() },
      eraser: { try self.erase() }
    )
  }
}
