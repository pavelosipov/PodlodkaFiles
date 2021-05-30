import Foundation
import Tagged

enum AuthTokenTag {}
typealias AuthToken = Tagged<AuthTokenTag, String>

struct Account: Codable {
  var id: Id
  var name: String
  var accessToken: AuthToken
  var refreshToken: AuthToken

  typealias Id = Tagged<Self, Int>
}
