import Foundation
import Logging

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

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
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd HH:MM:SS"
      return formatter.string(from: Date())
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
  ///   - label: The log label for the log handler.
  ///   - chat: The target chat to send to.
  ///   - token: Telegram Bot Token.
  ///   - level: (Optional) The minimal log level for this logger.
  ///   - mute: (Optional) Sending this message to the user silently.
  public init(
    label: String,
    token: String,
    chat: T,
    level: Logger.Level? = nil,
    mute: Bool = false
  ) {
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

  public func log(
    level: Logger.Level,
    message: Logger.Message,
    metadata: Logger.Metadata?,
    file: String, function: String, line: UInt
  ) {
    guard level >= logLevel else { return }

    var mentioned: [TelegramUser] = []

    if let chatT = chat as? TelegramGroupChat {
      mentioned += chatT.mentionedUsers
    }

    let metadata = mergedMetadata(metadata)
    let logBody = MarkdownLog(
      timestamp: timestamp,
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

      // Asynchronous telegram API request execution
      var request = URLRequest(url: api)
      request.httpMethod = "POST"
      request.httpBody = payload
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.addValue("application/json", forHTTPHeaderField: "Accept")

      let task = URLSession.shared.dataTask(with: request) { data, response, error in
          if let error {
              print("Failed to send Telegram message: \(error)")
              return
          }

          if let data {
              guard let status = try? JSONDecoder().decode(TelegramReturn.self, from: data) else {
                  print("Failed to send Telegram message: Response has incorrect format")
                  return
              }

              switch status {
              case .error(let code, let message):
                  print("Failed to send Telegram message with error: \(code)")
                  print("Error message: " + message)
              case .ok:
                  break
              }
          }
      }
      task.resume()
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
