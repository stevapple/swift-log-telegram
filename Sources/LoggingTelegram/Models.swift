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

public extension TelegramId {
    static func id(_ id: Int) -> Self {
        return Self(.id(id))
    }

    static func name(_ name: String) -> Self {
        return Self(.name(name))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawId)
    }
}

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

public struct TelegramChannel: TelegramGroupChat {
    public let rawId: TelegramRawId
    var mentionedUsers: [TelegramUser] = []

    public init(_ rawId: TelegramRawId) {
        self.rawId = rawId
    }
}

protocol TelegramGroupChat: TelegramId {
    var mentionedUsers: [TelegramUser] { get set }
}

extension TelegramGroupChat {
    func mentioning(_ users: [TelegramUser]) -> Self {
        var newInstance = self
        newInstance.mentionedUsers += users
        return newInstance
    }

    func mentioning(_ user: TelegramUser) -> Self {
        var newInstance = self
        newInstance.mentionedUsers.append(user)
        return newInstance
    }

    func mentioning(_ users: [TelegramRawId]) -> Self {
        var newInstance = self
        newInstance.mentionedUsers += users.map { TelegramUser($0) }
        return newInstance
    }

    func mentioning(_ user: TelegramRawId) -> Self {
        var newInstance = self
        newInstance.mentionedUsers.append(TelegramUser(user))
        return newInstance
    }

    func mentioning(_ users: [Int]) -> Self {
        var newInstance = self
        newInstance.mentionedUsers += users.map { TelegramUser.id($0) }
        return newInstance
    }

    func mentioning(_ user: Int) -> Self {
        var newInstance = self
        newInstance.mentionedUsers.append(TelegramUser.id(user))
        return newInstance
    }

    func mentioning(_ users: [String]) -> Self {
        var newInstance = self
        newInstance.mentionedUsers += users.map { TelegramUser.name($0) }
        return newInstance
    }

    func mentioning(_ user: String) -> Self {
        var newInstance = self
        newInstance.mentionedUsers.append(TelegramUser.name(user))
        return newInstance
    }
}

struct TelegramGroup: TelegramGroupChat {
    public let rawId: TelegramRawId
    var mentionedUsers: [TelegramUser] = []

    init(_ rawId: TelegramRawId) {
        self.rawId = rawId
    }

    func mentioning(_ users: [TelegramUser]) -> TelegramGroup {
        var newInstance = self
        newInstance.mentionedUsers = users
        return newInstance
    }
}

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
