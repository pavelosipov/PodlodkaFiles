import Combine
import Foundation

final class Authencticator {
  private let accountDb: PersistableAccount

  func authenticate(name: String, password: String) -> AnyPublisher<Never, Error> {
    AuthApi.authenticate(name: name, password: password)
      .tryMap { [weak self] account -> Void in
        try self?.accountDb.update { $0 = account }
      }
      .ignoreOutput()
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }

  init(accountDb: PersistableAccount) {
    self.accountDb = accountDb
  }
}
