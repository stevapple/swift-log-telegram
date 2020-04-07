import Foundation
import Logging

typealias Level = Logger.Level
typealias Metadata = Logger.Metadata
typealias Message = Logger.Message

struct MarkdownLog: CustomStringConvertible {
    let timestamp: String
    let label: String
    let level: Level
    let message: Message
    let metadata: Metadata
    let file: String
    let function: String
    let line: UInt
    let mentionedUsers: [TelegramUser]

    var description: String {
        let title = "[\(label)] [\(level)]"
        let location = "\(function) @ \(file):\(line)"
        return timestamp.telegramEscaping() + " *\(title.telegramEscaping())*\n"
            + "*\(message.telegramEscaping())*\n"
            + location.telegramEscaping()
            + (metadata.count > 0 ? "*Metadata*\n" : "")
            + metadata.map {"*\($0.telegramEscaping())*: \($1)"} .joined(separator: "\n")
            + (mentionedUsers.count > 0 ? "\n" : "")
            + mentionedUsers.map {"\($0)"} .joined(separator: " ")
    }
}

extension String {
    func telegramEscaping() -> String {
        var text = self
        for char in "_*[]()~`>#+-=|{}.!" {
            text = text.replacingOccurrences(of: "\(char)", with: "\\\(char)")
        }
        return text
    }
}

extension CustomStringConvertible {
    func telegramEscaping() -> String {
        return self.description.telegramEscaping()
    }
}
