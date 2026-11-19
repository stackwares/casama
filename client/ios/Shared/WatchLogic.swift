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

// MARK: Sign-in requests to the phone (docs/WATCH-PROTOCOL.md §2)

/// The request ids this watch sent the phone for one key. A `signed_in` answer counts only when
/// its id is one of them: an answer to a request made for an older key, or for another watch,
/// must not sign this one in.
struct IssuedSignIns: Codable, Equatable {
  static let kept = 6

  var fingerprint: String
  var ids: [String]

  static let none = IssuedSignIns(fingerprint: "", ids: [])

  /// This list with [id] added for the key with [fingerprint]; ids of another key are dropped.
  func adding(_ id: String, for fingerprint: String) -> IssuedSignIns {
    let mine = self.fingerprint == fingerprint ? ids.filter { $0 != id } : []
    return IssuedSignIns(fingerprint: fingerprint, ids: Array((mine + [id]).suffix(Self.kept)))
  }

  /// Whether an answer with [id] is to a request this watch made for the key with [fingerprint].
  func accepts(_ id: String?, for fingerprint: String) -> Bool {
    guard let id, !id.isEmpty, !fingerprint.isEmpty, self.fingerprint == fingerprint else { return false }
    return ids.contains(id)
  }
}

/// Whether a watch that is still waiting on the phone asks it again by itself when its app comes
/// forward (the first request may never have arrived, or the phone has only now been signed in).
/// Not after the person said no on the phone, not while the screen explains that the phone's
/// server can't be reached from a watch, not while a code is being fetched, and not on every
/// wrist raise: each ask the phone can't take now is queued for it.
enum PhoneReask {
  static let every: TimeInterval = 30

  static func allowed(waiting: Bool, lastAsk: Date, now: Date, lastReason: String?, needsHttps: Bool, fetchingCode: Bool) -> Bool {
    guard waiting, !needsHttps, !fetchingCode, lastReason != "declined" else { return false }
    return now.timeIntervalSince(lastAsk) > every
  }
}

// MARK: What the server said went wrong (docs/WATCH-PROTOCOL.md §1)

/// A problem+json answer's `code` and `detail`.
struct WatchProblem: Equatable {
  var code: String?
  var detail: String?

  static func parse(_ data: Data?) -> WatchProblem? {
    guard let data, let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
    func s(_ key: String) -> String? {
      guard let v = obj[key] as? String, !v.isEmpty else { return nil }
      return v
    }
    let problem = WatchProblem(code: s("code"), detail: s("detail") ?? s("title"))
    return problem.code == nil && problem.detail == nil ? nil : problem
  }
}

/// What a refused answer (Allow, Deny, Do It, Run, Stop) means to the person.
enum WatchRefusal: Equatable {
  /// Someone answered it already, or it is gone.
  case alreadyAnswered
  /// It isn't in this watch's workspace (404 `not_found`): the phone answers it.
  case elsewhere
  /// A limit was reached (402): nothing started.
  case outOfCredits
  /// The server said no, in its own words when it gave any.
  case refused(String?)

  /// 409 codes that mean "this was answered already" or "this is over already": a request
  /// someone decided, a suggestion someone took or dismissed, a run that ended before Stop got
  /// there (`POST /v1/runs/{id}/cancel`).
  private static let closed: Set<String> = ["approval_already_decided", "suggestion_closed", "run_finished"]

  static func of(status: Int, problem: WatchProblem?) -> WatchRefusal {
    switch status {
    case 404:
      return problem?.code == "not_found" ? .elsewhere : .alreadyAnswered
    case 409:
      guard let code = problem?.code else { return .alreadyAnswered }
      if closed.contains(code) || code.hasSuffix("_closed") || code.hasSuffix("_decided") || code.hasSuffix("_finished") {
        return .alreadyAnswered
      }
      return .refused(problem?.detail)
    case 402:
      return .outOfCredits
    default:
      return .refused(problem?.detail)
    }
  }
}

/// Why a request is answered on the phone (`why_phone`, or `watch_allow_refused`'s detail), in
/// the person's words. Nil for a reason the watch doesn't know.
enum WatchWhy {
  static func text(_ reason: String?) -> String? {
    switch reason {
    case "high_risk": return WatchL10n.whyHighRisk
    case "payment": return WatchL10n.whyPayment
    case "setting": return WatchL10n.whySetting
    case "workspace": return WatchL10n.whyWorkspace
    case "not_yours": return WatchL10n.whyNotYours
    default: return nil
    }
  }
}

/// Whether a notification is about another workspace than this watch's. Only when both are
/// known: a push without `org_id` (an older server) is treated as this workspace's.
enum PushScope {
  static func isElsewhere(pushOrg: String?, watchOrg: String?) -> Bool {
    guard let pushOrg, !pushOrg.isEmpty, let watchOrg, !watchOrg.isEmpty else { return false }
    return pushOrg.lowercased() != watchOrg.lowercased()
  }
}

/// Which servers the watch can call. The phone app reaches a self-hosted server on plain http
/// anywhere (its own sockets); the watch goes through the system, which allows http only on the
/// local network (NSAllowsLocalNetworking: an address, a bare name, or a `.local` name).
enum WatchServer {
  static func usable(_ url: URL) -> Bool {
    switch url.scheme?.lowercased() {
    case "https": return true
    case "http": return isLocal(url.host ?? "")
    default: return false
    }
  }

  static func isLocal(_ host: String) -> Bool {
    let h = host.lowercased()
    guard !h.isEmpty else { return false }
    // A bare name ("casama", "localhost") or an IPv6 address.
    if !h.contains(".") { return true }
    if h.hasSuffix(".local") { return true }
    let parts = h.split(separator: ".", omittingEmptySubsequences: false)
    return parts.count == 4 && parts.allSatisfy { UInt8($0) != nil }
  }
}

/// How old a saved glance may be before a complication stops drawing it as now (§6.3).
enum GlanceAge {
  static let staleAfter: TimeInterval = 30 * 60

  static func isStale(savedAt: Date?, now: Date) -> Bool {
    guard let savedAt else { return true }
    return now.timeIntervalSince(savedAt) > staleAfter
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
  /// How many times the server answered a try with something it may get over (a 5xx, an answer
  /// that couldn't be read, a voice service that was down).
  var tries: Int?
}

enum AskQueuePolicy {
  /// A kept ask older than this asks before it is sent.
  static let confirmAfter: TimeInterval = 10 * 60
  /// Kept asks older than this are dropped: nobody wants yesterday's question answered.
  static let dropAfter: TimeInterval = 24 * 3600
  static let maxKept = 5
  /// Tries the server failed before a kept ask is given up on.
  static let maxTries = 4

  enum AfterFailure: Equatable { case keep, drop }

  /// What to do with a kept ask the server didn't take. [status] is the HTTP status, nil when the
  /// answer couldn't be read. A refusal that won't change (nothing heard, no such bot, out of
  /// credits) drops it; a server that failed or was busy keeps it, up to [maxTries] such tries.
  static func afterFailure(status: Int?, tries: Int) -> AfterFailure {
    if let status, (400..<500).contains(status), status != 408, status != 409, status != 429 { return .drop }
    return tries >= maxTries ? .drop : .keep
  }

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
