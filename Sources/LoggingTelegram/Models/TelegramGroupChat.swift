import Foundation

protocol TelegramGroupChat: TelegramId {
  var mentionedUsers: [TelegramUser] { get set }
}

extension TelegramGroupChat {
  func mentioning<T: TelegramUserRepresentable>(_ users: [T]) -> Self {
    var newInstance = self
    newInstance.mentionedUsers += users.map { T.makeTelegramUser($0) }
    return newInstance
  }

  func mentioning<T: TelegramUserRepresentable>(_ user: T) -> Self {
    var newInstance = self
    newInstance.mentionedUsers.append(T.makeTelegramUser(user))
    return newInstance
  }
}

public struct TelegramChannel: TelegramGroupChat {
  public let rawId: TelegramRawId
  var mentionedUsers: [TelegramUser] = []

  public init(_ rawId: TelegramRawId) {
    self.rawId = rawId
  }
}

public struct TelegramGroup: TelegramGroupChat {
  public let rawId: TelegramRawId
  var mentionedUsers: [TelegramUser] = []

  public init(_ rawId: TelegramRawId) {
    self.rawId = rawId
  }
}
