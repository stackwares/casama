import CryptoKit
import Foundation

// MARK: - Small pure rules both watch targets share (D-410)
//
// Kept free of UI and storage so scripts/test-watch-swift.sh can check them on macOS.

// MARK: The key (docs/WATCH-PROTOCOL.md §1)

enum WatchKeyMaker {
  static let prefix = "cwt_"

  /// A new key: `cwt_` + base64url of 32 random bytes, no padding (47 characters).
  static func make() -> String {
    var rng = SystemRandomNumberGenerator()  // Backed by the system's secure random source.
    let bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max, using: &rng) }
    return prefix + base64url(Data(bytes))
  }

  static func base64url(_ data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  /// What leaves the watch instead of the key: lowercase hex of sha256("casama-watch-key:" + key).
  static func fingerprint(_ key: String) -> String {
    SHA256.hash(data: Data(("casama-watch-key:" + key).utf8)).map { String(format: "%02x", $0) }.joined()
  }

  static func isWellFormed(_ key: String) -> Bool {
    guard key.hasPrefix(prefix) else { return false }
    let body = key.dropFirst(prefix.count)
    return body.count == 43 && body.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
  }
}

// MARK: Sign-in codes

enum WatchCodeFormat {
  /// "KQ7M2XAB" → "KQ7M 2XAB": two halves, easier to read off a wrist and type.
  static func display(_ code: String) -> String {
    let clean = code.uppercased().filter { !$0.isWhitespace && $0 != "-" }
    guard clean.count > 4 else { return clean }
    let half = clean.count / 2
    return String(clean.prefix(half)) + " " + String(clean.dropFirst(half))
  }

  /// For VoiceOver: one character at a time.
  static func spoken(_ code: String) -> String {
    code.uppercased().filter { !$0.isWhitespace }.map(String.init).joined(separator: " ")
  }
}

// MARK: Times

enum WatchTime {
  private static let lock = NSLock()
  private static var formatters: [String: DateFormatter] = [:]

  private static func formatter(_ template: String, _ locale: Locale, _ timeZone: TimeZone) -> DateFormatter {
    let key = "\(template)|\(locale.identifier)|\(timeZone.identifier)"
    lock.lock()
    defer { lock.unlock() }
    if let f = formatters[key] { return f }
    let f = DateFormatter()
    f.locale = locale
    f.timeZone = timeZone
    f.setLocalizedDateFormatFromTemplate(template)
    formatters[key] = f
    return f
  }

  /// "9:12" (in the person's own clock style).
  static func clock(_ date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
    formatter("jmm", locale, timeZone).string(from: date)
  }

  /// "Fri 16:00".
  static func dayClock(_ date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
    formatter("EEEjmm", locale, timeZone).string(from: date)
  }

  /// "20 Nov".
  static func day(_ date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
    formatter("dMMM", locale, timeZone).string(from: date)
  }

  private static func calendar(_ timeZone: TimeZone) -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = timeZone
    return c
  }

  /// When something runs: "in 12 min" within the hour, else "9:12" today, "Fri 16:00" this week,
  /// "20 Nov" later. Past times read as their clock.
  static func upcoming(_ date: Date, now: Date = Date(), locale: Locale = .current, timeZone: TimeZone = .current) -> String {
    let seconds = date.timeIntervalSince(now)
    if seconds > 0 && seconds < 3600 {
      let minutes = max(1, Int((seconds / 60).rounded(.up)))
      return WatchL10n.inMinutes("\(minutes)")
    }
    let cal = calendar(timeZone)
    if cal.isDate(date, inSameDayAs: now) || seconds <= 0 { return clock(date, locale: locale, timeZone: timeZone) }
    if seconds < 6 * 86_400 { return dayClock(date, locale: locale, timeZone: timeZone) }
    return day(date, locale: locale, timeZone: timeZone)
  }

  /// A past moment: "9:12" today, "Fri 16:00" this week, else "20 Nov".
  static func past(_ date: Date, now: Date = Date(), locale: Locale = .current, timeZone: TimeZone = .current) -> String {
    let cal = calendar(timeZone)
    if cal.isDate(date, inSameDayAs: now) { return clock(date, locale: locale, timeZone: timeZone) }
    if now.timeIntervalSince(date) < 6 * 86_400 { return dayClock(date, locale: locale, timeZone: timeZone) }
    return day(date, locale: locale, timeZone: timeZone)
  }

  /// "as of 9:12": how old what is shown is.
  static func asOf(_ date: Date, now: Date = Date(), locale: Locale = .current, timeZone: TimeZone = .current) -> String {
    WatchL10n.asOf(past(date, now: now, locale: locale, timeZone: timeZone))
  }

  /// "Replied 9:20".
  static func replied(_ date: Date, now: Date = Date(), locale: Locale = .current, timeZone: TimeZone = .current) -> String {
    WatchL10n.repliedAt(past(date, now: now, locale: locale, timeZone: timeZone))
  }

  /// "Brief at 7:00" today, "Brief at 7:00 tomorrow", else the day and time.
  static func briefLine(_ next: Date, now: Date = Date(), locale: Locale = .current, timeZone: TimeZone = .current) -> String {
    let cal = calendar(timeZone)
    let time = clock(next, locale: locale, timeZone: timeZone)
    if cal.isDate(next, inSameDayAs: now) { return WatchL10n.briefAt(time) }
    if let tomorrow = cal.date(byAdding: .day, value: 1, to: now), cal.isDate(next, inSameDayAs: tomorrow) {
      return WatchL10n.briefTomorrow(time)
    }
    return WatchL10n.briefAt(dayClock(next, locale: locale, timeZone: timeZone))
  }

  /// A running clock's text: "0:42", "2:14", "1:02:03".
  static func elapsed(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    let h = total / 3600, m = (total % 3600) / 60, s = total % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
  }
}

// MARK: Asks kept while offline (§6.1 C)

struct QueuedAsk: Codable, Equatable, Identifiable {
  var id: String
  var botId: String
  var botName: String
  var conversationId: String?
  var text: String?
  /// A recording kept in the app group's container, by file name.
  var audioFile: String?
  var mime: String?
  var askedAt: Date
  /// The same key on every try, so a retry on a bad connection can't send twice.
  var idempotencyKey: String
}

enum AskQueuePolicy {
  /// A kept ask older than this asks before it is sent.
  static let confirmAfter: TimeInterval = 10 * 60
  /// Kept asks older than this are dropped: nobody wants yesterday's question answered.
  static let dropAfter: TimeInterval = 24 * 3600
  static let maxKept = 5

  static func needsConfirm(_ ask: QueuedAsk, now: Date = Date()) -> Bool {
    now.timeIntervalSince(ask.askedAt) > confirmAfter
  }

  static func isStale(_ ask: QueuedAsk, now: Date = Date()) -> Bool {
    now.timeIntervalSince(ask.askedAt) > dropAfter
  }

  /// Which kept asks go now without asking, and which wait for a yes.
  static func split(_ asks: [QueuedAsk], now: Date = Date()) -> (send: [QueuedAsk], confirm: [QueuedAsk]) {
    let live = asks.filter { !isStale($0, now: now) }
    return (live.filter { !needsConfirm($0, now: now) }, live.filter { needsConfirm($0, now: now) })
  }
}

// MARK: Bot marks (client/lib/shared/widgets/bot_avatar.dart)

enum BotPalette {
  /// The mascots we ship (mascot.dart) and their two colours.
  static let mascots: [String: (UInt32, UInt32)] = [
    "winky": (0x7A90FF, 0x7DE9F4),
    "sleepy": (0x7C83F2, 0xA59CF6),
    "starry": (0xFF9F43, 0xFFC94D),
    "lovey": (0xFF6FAE, 0xFF9CC9),
    "cool": (0x14B8A6, 0x4FD1C5),
    "thinker": (0xF59E0B, 0xFBBF24),
    "giggly": (0x22C55E, 0x4ADE80),
    "shy": (0xFB7185, 0xFDA4AF),
    "focused": (0x3B82F6, 0x60A5FA),
    "wow": (0x8B5CF6, 0xA78BFA),
  ]

  /// The initials gradients (bot_avatar.dart, `_palettes`).
  static let initials: [(UInt32, UInt32)] = [
    (0x14B8A6, 0x0F766E),
    (0x6366F1, 0x4338CA),
    (0xF59E0B, 0xD97706),
    (0xEC4899, 0xBE185D),
    (0x3B82F6, 0x1D4ED8),
    (0x8B5CF6, 0x6D28D9),
    (0x10B981, 0x047857),
    (0xF97316, 0xC2410C),
  ]

  /// `mascot:<name>` → the mascot's key when we ship it, else nil (draw initials).
  static func mascot(_ avatar: String?) -> String? {
    guard let avatar, avatar.hasPrefix("mascot:") else { return nil }
    let key = String(avatar.dropFirst("mascot:".count))
    return mascots[key] != nil ? key : nil
  }

  /// botPalette: (h * 31 + code unit) & 0x7fffffff over the lower-cased name's UTF-16.
  static func index(_ name: String) -> Int {
    var h = 0
    for u in name.lowercased().utf16 { h = (h &* 31 &+ Int(u)) & 0x7fffffff }
    return h % initials.count
  }

  /// One or two letters, as botInitials makes them.
  static func letters(_ name: String) -> String {
    let parts = name.split(whereSeparator: { $0.isWhitespace })
    guard let first = parts.first?.first else { return "?" }
    guard parts.count > 1, let second = parts[1].first else { return String(first).uppercased() }
    return (String(first) + String(second)).uppercased()
  }
}

// MARK: Haptic choice for a run's change (§6.7)

enum RunChange: Equatable {
  case needsYou, finished, problem, none

  static func between(_ old: WatchRunPhase?, _ new: WatchRunPhase) -> RunChange {
    guard old != new else { return .none }
    switch new {
    case .needsOk, .takeOver: return .needsYou
    case .finished: return .finished
    case .problem: return .problem
    default: return .none
    }
  }
}
