import Combine
import Foundation

final class DbStateUpdater: StateUpdater {
  private var state: DbState
  private let updatesSubject = PassthroughSubject<State, Never>()
  private let queue = DispatchQueue(label: "io.podlodka.DbStateUpdater")

  var updatesPublisher: AnyPublisher<State, Never> {
    updatesSubject.eraseToAnyPublisher()
  }

  func resetNodes(with rootNode: NodeDto) -> AnyPublisher<Never, Error> {
    update { try $0.resetNodes(with: rootNode) }
  }

  func favoriteNode(id: NodeId, at time: Date) -> AnyPublisher<Never, Error> {
    update { try $0.favoriteNode(id: id, at: time) }
  }

  func unfavoriteNode(id: NodeId) -> AnyPublisher<Never, Error> {
    update { try $0.unfavoriteNode(id: id) }
  }

  private func update(
    updater: @escaping (inout DbState) throws -> Void
  ) -> AnyPublisher<Never, Error> {
    Future { promise in
      self.queue.async {
        do {
          try updater(&self.state)
          self.updatesSubject.send(self.state)
        } catch {
          promise(.failure(error))
        }
      }
    }
    .eraseToAnyPublisher()
  }

  init(state: DbState) {
    self.state = state
  }
}
