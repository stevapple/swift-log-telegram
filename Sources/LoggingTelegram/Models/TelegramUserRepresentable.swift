import Foundation

protocol TelegramUserRepresentable {
  static func makeTelegramUser(_: Self) -> TelegramUser
}

extension Int: TelegramUserRepresentable {
  static func makeTelegramUser(_ id: Int) -> TelegramUser {
    return TelegramUser.id(id)
  }
}

extension String: TelegramUserRepresentable {
  static func makeTelegramUser(_ name: String) -> TelegramUser {
    return TelegramUser.name(name)
  }
}

extension TelegramRawId: TelegramUserRepresentable {
  static func makeTelegramUser(_ rawId: TelegramRawId) -> TelegramUser {
    return TelegramUser(rawId)
  }
}

extension TelegramUser: TelegramUserRepresentable {
  static func makeTelegramUser(_ user: TelegramUser) -> TelegramUser {
    return user
  }
}
