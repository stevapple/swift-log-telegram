// swiftlint:disable nesting
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#else
import Glibc
#endif

/// The global log level threshold that determines when to send log output to Telegram.
/// Defaults to `.critical`.
public var telegramLogDefaultLevel: Logger.Level = .critical

/// `TelegramLogHandler` is an implementation of `LogHandler` for sending
/// `Logger` output directly to Telegram,
/// Forked from `SlackLogHandler`.
public class TelegramLogHandler<T>: LogHandler where T: TelegramId {
    private var timestamp: String {
        var buffer = [Int8](repeating: 0, count: 255)
        var timestamp = time(nil)
        let localTime = localtime(&timestamp)
        strftime(&buffer, buffer.count, "%Y-%m-%dT%H:%M:%S%z", localTime)
        return buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
    }

    /// The log label for the log handler.
    private var label: String

    /// The URL of `sendMessage` API.
    private let api: URL

    /// The chats you want to send to
    private let chat: T

    /// If you want to mute the push.
    private let mute: Bool

    /// The chat-specific log level settings.
    /// Defaults to the value of `telegramLogDefaultLevel`.
    public var logLevel: Logger.Level {
        get {
            return rawLogLevel ?? telegramLogDefaultLevel
        }
        set {
            rawLogLevel = newValue
        }
    }

    internal var rawLogLevel: Logger.Level?

    public var metadata = Logger.Metadata()

    /// Creates a `TelegramLogHandler` for sending `Logger` output directly to Telegram.
    /// - Parameters:
    ///   - label: The log label for he log handler.
    ///   - chats: Target chats to send.
    ///   - token: Telegram Bot Token.
    ///   - level: (Optional) The minimal log level for this logger.
    public init(label: String,
                token: String,
                chat: T,
                level: Logger.Level? = nil,
                mute: Bool = false) {
        self.label = label
        self.chat = chat
        self.api = URL(string: "https://api.telegram.org/bot\(token)/sendMessage")!
        self.rawLogLevel = level
        self.mute = mute
    }

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            metadata[metadataKey]
        }
        set {
            metadata[metadataKey] = newValue
        }
    }

    // swiftlint:disable:next function_parameter_count
    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    file: String, function: String, line: UInt) {
        guard level >= logLevel else { return }

        var mentioned: [TelegramUser] = []

        if let chatT = chat as? TelegramGroupChat {
            mentioned += chatT.mentionedUsers
        }

        let metadata = mergedMetadata(metadata)
        let logBody = MarkdownLog(timestamp: timestamp,
                                  label: label,
                                  level: level,
                                  message: message,
                                  metadata: metadata,
                                  file: file,
                                  function: function,
                                  line: line,
                                  mentionedUsers: mentioned)

        send(Message(to: chat, content: "\(logBody)", mute: mute))
    }

    private func mergedMetadata(_ metadata: Logger.Metadata?) -> Logger.Metadata {
        if let metadata = metadata {
            return self.metadata.merging(metadata, uniquingKeysWith: { _, new in new })
        } else {
            return self.metadata
        }
    }

    private func send(_ telegramMessage: Message) {
        let payload: Data
        do {
            payload = try JSONEncoder().encode(telegramMessage)
        } catch {
            print("Parsing error. ")
            return
        }

        var request = URLRequest(url: api)
        request.httpMethod = "POST"
        request.httpBody = payload
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp, error) = URLSession.shared.synchronousDataTask(with: request)

        guard (resp as? HTTPURLResponse) != nil else {
            print("Failed to send Telegram message with receiving error")
            return
        }

        if let error = error {
            print("Failed to send Telegram message with connection error: \(error)")
        }

        guard let returnData = data else {
            return
        }

        let returnStatus: TelegramReturn
        do {
            returnStatus = try JSONDecoder().decode(TelegramReturn.self, from: returnData)
        } catch {
            print("Parsing error. ")
            return
        }

        switch returnStatus {
        case .error(let code, let message):
            print("Failed to send Telegram message with error: \(code)")
            print("Error message: " + message)
            return
        case .ok:
            break
        }
    }

    struct Message: Encodable {
        let chatId: T
        let text: String
        let mode: String = "MarkdownV2"
        let mute: Bool
        enum CodingKeys: String, CodingKey {
            case chatId = "chat_id"
            case text
            case mode = "parse_mode"
            case mute = "disable_notification"
        }

        init(to chat: T, content: String, mute: Bool) {
            self.chatId = chat
            self.text = content
            self.mute = mute
        }
    }
}
