import Foundation

public struct TelegramUser: TelegramId, CustomStringConvertible {
    public let rawId: TelegramRawId

    public var description: String {
        switch rawId {
        case .id(let userId):
            return "[mentioning \(userId)](tg://user?id=\(userId))"
        case .name(let userName):
            return "@\(userName)"
        }
    }

    public init(_ rawId: TelegramRawId) {
        self.rawId = rawId
    }
}
