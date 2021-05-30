import Combine
import Foundation

protocol StateUpdater {
  var updatesPublisher: AnyPublisher<State, Never> { get }

  func resetNodes(with rootNode: NodeDto) -> AnyPublisher<Never, Error>
  func favoriteNode(id: NodeId, at time: Date) -> AnyPublisher<Never, Error>
  func unfavoriteNode(id: NodeId) -> AnyPublisher<Never, Error>
}
