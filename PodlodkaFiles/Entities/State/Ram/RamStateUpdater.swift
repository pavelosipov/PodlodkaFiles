import Combine
import Foundation

final class RamStateUpdater: StateUpdater {
  private let state: PersistableState
  private let queue = DispatchQueue(label: "io.podlodka.StateUpdater")

  var updatesPublisher: AnyPublisher<State, Never> {
    // swiftlint:disable array_init
    state
      .publisher
      .map { state -> State in
        state
      }
      .eraseToAnyPublisher()
    // swiftlint:enable array_init
  }

  func resetNodes(with rootNode: NodeDto) -> AnyPublisher<Never, Error> {
    update { $0.resetNodes(with: rootNode) }
  }

  func favoriteNode(id: NodeId, at time: Date) -> AnyPublisher<Never, Error> {
    update { try $0.favoriteNode(id: id, at: time) }
  }

  func unfavoriteNode(id: NodeId) -> AnyPublisher<Never, Error> {
    update { try $0.unfavoriteNode(id: id) }
  }

  private func update(
    updater: @escaping (inout RamState) throws -> Void
  ) -> AnyPublisher<Never, Error> {
    Future { promise in
      self.queue.async {
        do {
          try self.state.update { try updater(&$0) }
        } catch {
          promise(.failure(error))
        }
      }
    }
    .eraseToAnyPublisher()
  }

  init(state: PersistableState) {
    self.state = state
  }
}
