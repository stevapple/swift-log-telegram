import Foundation

enum TelegramReturn: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let status = try container.decode(Bool.self, forKey: .ok)
    if status {
      self = .ok
    } else {
      let code = try container.decode(Int.self, forKey: .code)
      let message = try container.decode(String.self, forKey: .message)
      self = .error(code, message)
    }
  }

  case ok
  case error(Int, String)

  enum CodingKeys: String, CodingKey {
    case ok
    case code = "error_code"
    case message = "description"
  }
}
