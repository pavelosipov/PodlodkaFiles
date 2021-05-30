import Foundation
import Combine

enum AuthApi {
  static func authenticate(name: String, password: String) -> Future<Account, Error> {
    Future { resolve in
      DispatchQueue.global().async {
        resolve(.success(.mockAccount(name: name)))
      }
    }
  }
}

private extension Account {
  static func mockAccount(name: String) -> Account {
    Account(id: 42, name: name, accessToken: "123", refreshToken: "456")
  }
}
