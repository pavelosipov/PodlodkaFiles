import Combine
import Foundation

protocol PersistingValue {
  associatedtype Value
}

final class PersistableValue<Value: Decodable>: PersistingValue {
  private let syncQueue = DispatchQueue(
    label: "io.podlodka.PersistableValue",
    qos: .userInitiated,
    attributes: [.concurrent]
  )
  private let valueStore: AnyValueStore<Value>
  private let valueSubject = PassthroughSubject<Value, Never>()

  var publisher: AnyPublisher<Value, Never> {
    valueSubject.eraseToAnyPublisher()
  }

  private var _value: Value
  var value: Value {
    var result: Value?
    syncQueue.sync { result = _value }
    return result!
  }

  func update(updater: @escaping (inout Value) throws -> Void) throws {
    var updatedValue: Value?
    try syncQueue.sync(flags: .barrier) {
      var updatingValue = self._value
      try updater(&updatingValue)
      try self.valueStore.save(value: updatingValue)
      self._value = updatingValue
      updatedValue = updatingValue
    }
    self.valueSubject.send(updatedValue!)
  }

  init(value: Value, valueStore: AnyValueStore<Value>) {
    _value = value
    self.valueStore = valueStore
  }
}

extension PersistableValue where Value: ExpressibleByNilLiteral {
  func reset() -> Future<Void, Error> {
    Future { promise in
      self.syncQueue.async(flags: .barrier) {
        do {
          try self.valueStore.erase()
          self._value = nil
          self.valueSubject.send(nil)
          promise(.success(()))
        } catch {
          promise(.failure(error))
        }
      }
    }
  }
}
