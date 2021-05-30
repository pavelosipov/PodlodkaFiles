import Combine
import Foundation

final class FilesLoader {
  private let accountDb: PersistableAccount
  private let statesUpdater: StateUpdater

  func loadFiles() -> AnyPublisher<Never, Error> {
    guard let account = accountDb.value else {
      return Fail(error: FilesApi.LoadError.authError).eraseToAnyPublisher()
    }
    return FilesApi
      .loadFiles(accessToken: account.accessToken)
      .flatMap { [weak self] rootNode -> AnyPublisher<Never, Error> in
        guard let self = self else {
          return Empty().eraseToAnyPublisher()
        }
        return self.statesUpdater.resetNodes(with: rootNode)
      }
      .eraseToAnyPublisher()
  }

  init(accountDb: PersistableAccount, statesUpdater: StateUpdater) {
    self.accountDb = accountDb
    self.statesUpdater = statesUpdater
  }
}
