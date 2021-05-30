import Foundation
import Security

protocol DataStore {
  func save(data: Data) throws
  func load() throws -> Data?
  func erase() throws
}

final class FileDataStore: DataStore {
  private let pathURL: URL

  init(pathURL: URL) {
    self.pathURL = pathURL
  }

  // MARK: - DataStore

  func save(data: Data) throws {
    try data.write(to: pathURL, options: .atomic)
  }

  func load() throws -> Data? {
    guard FileManager.default.fileExists(atPath: pathURL.path) else {
      return nil
    }
    return try Data(contentsOf: pathURL)
  }

  func erase() throws {
    try FileManager.default.removeItem(at: pathURL)
  }
}

final class UserDefaultsDataStore: DataStore {
  enum Error: Swift.Error {
    case invalidData
  }

  private let userDefaults: UserDefaults
  private let key: String

  init(userDefaults: UserDefaults, key: String) {
    self.userDefaults = userDefaults
    self.key = key
  }

  // MARK: - DataStore

  func save(data: Data) throws {
    userDefaults.setValue(data, forKey: key)
  }

  func load() throws -> Data? {
    guard let something = userDefaults.value(forKey: key) else {
      return nil
    }
    guard let data = something as? Data else {
      throw Error.invalidData
    }
    return data
  }

  func erase() throws {
    userDefaults.removeObject(forKey: key)
  }
}

final class KeychainDataStore: DataStore {
  enum Error: LocalizedError {
    case failure(status: OSStatus)
    var errorDescription: String? {
      switch self {
      case let .failure(status):
        return SecCopyErrorMessageString(status, nil) as String?
      }
    }
  }

  private let service: String
  private let key: String

  init(service: String, key: String) {
    self.service = service
    self.key = key
  }

  // MARK: - DataStore

  func save(data: Data) throws {
    let query = keyAttributes
    let status = SecItemCopyMatching(query as CFDictionary, nil)
    switch status {
    case errSecSuccess:
      try update(data: data)
    case errSecItemNotFound:
      try insert(data: data)
    default:
      throw Error.failure(status: status)
    }
  }

  func load() throws -> Data? {
    var item: CFTypeRef?
    let query = keyQueryAttributes
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound {
      return nil
    }
    if status == errSecSuccess, let data = item.flatMap({ $0 as? Data }) {
      return data
    }
    throw Error.failure(status: status)
  }

  func erase() throws {
    let query = keyAttributes // keyQueryAttributes
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw Error.failure(status: status)
    }
  }

  // MARK: - Private

  private func update(data: Data) throws {
    let query = keyAttributes
    let attributes = keyUpdateAttributes(for: data)
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status != errSecSuccess {
      throw Error.failure(status: status)
    }
  }

  private func insert(data: Data) throws {
    let attributes = keyInsertAttributes(for: data)
    let status = SecItemAdd(attributes as CFDictionary, nil)
    if status != errSecSuccess {
      throw Error.failure(status: status)
    }
  }

  private var keyAttributes: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
    ]
  }

  private var keyQueryAttributes: [String: Any] {
    var query = keyAttributes
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    return query
  }

  private func keyUpdateAttributes(for data: Data) -> [String: Any] {
    [kSecValueData as String: data]
  }

  private func keyInsertAttributes(for data: Data) -> [String: Any] {
    var query = keyAttributes
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    query[kSecValueData as String] = data
    return query
  }
}
