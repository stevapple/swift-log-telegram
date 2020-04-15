import Foundation

public enum TelegramRawId: Encodable {
  case id(Int)
  case name(String)

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .id(let userId):
      try container.encode(userId)
    case .name(let userName):
      try container.encode("@" + userName)
    }
  }
}

public protocol TelegramId: Encodable {
  var rawId: TelegramRawId { get }
  init(_: TelegramRawId)
}

extension TelegramId {
  public static func id(_ id: Int) -> Self {
    return Self(.id(id))
  }

  public static func name(_ name: String) -> Self {
    return Self(.name(name))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.rawId)
  }
}
