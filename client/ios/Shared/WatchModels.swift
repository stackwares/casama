import Foundation

// MARK: - The watch's contract (D-410)
//
// What packages/contracts/src/watch.ts and glance.ts send, decoded for both watch targets and for
// the macOS model tests (scripts/test-watch-swift.sh), so this file stays Foundation-only.
//
// Decoding is forgiving on purpose: a watch can't be updated as fast as a server. Unknown keys are
// ignored, an unknown enum value falls back to a safe one, a list row that can't be read is
// skipped, and parts an older server doesn't send yet (`runs`) are simply empty. Only ids are
// required: a row without one is useless.

enum WatchJSON {
  static func decoder() -> JSONDecoder {
    let d = JSONDecoder()
    d.keyDecodingStrategy = .convertFromSnakeCase
    d.dateDecodingStrategy = .custom { decoder in
      let c = try decoder.singleValueContainer()
      let raw = try c.decode(String.self)
      if let date = WatchDate.parse(raw) { return date }
      throw DecodingError.dataCorruptedError(in: c, debugDescription: "Not an ISO 8601 time: \(raw)")
    }
    return d
  }

  static func encoder() -> JSONEncoder {
    let e = JSONEncoder()
    e.keyEncodingStrategy = .convertToSnakeCase
    e.dateEncodingStrategy = .custom { date, encoder in
      var c = encoder.singleValueContainer()
      try c.encode(WatchDate.string(date))
    }
    return e
  }
}

enum WatchDate {
  private static let withFraction: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
  }()
  private static let plain: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
  }()

  /// The server writes times with an offset, with or without fractions of a second.
  static func parse(_ raw: String) -> Date? {
    withFraction.date(from: raw) ?? plain.date(from: raw)
  }

  static func string(_ date: Date) -> String { withFraction.string(from: date) }
}

/// Decodes an array row by row, skipping rows it can't read, so one odd row never blanks a screen.
struct LossyList<Element: Decodable>: Decodable {
  var items: [Element] = []
  init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    while !c.isAtEnd {
      if let item = try? c.decode(Element.self) {
        items.append(item)
      } else if (try? c.decode(Skip.self)) == nil {
        break  // Can't even step over it: stop rather than loop.
      }
    }
  }
  private struct Skip: Decodable {}
}

extension KeyedDecodingContainer {
  func str(_ key: Key, _ fallback: String = "") -> String {
    ((try? decodeIfPresent(String.self, forKey: key)) ?? nil) ?? fallback
  }
  func optStr(_ key: Key) -> String? {
    guard let s = (try? decodeIfPresent(String.self, forKey: key)) ?? nil, !s.isEmpty else { return nil }
    return s
  }
  func flag(_ key: Key, _ fallback: Bool = false) -> Bool {
    ((try? decodeIfPresent(Bool.self, forKey: key)) ?? nil) ?? fallback
  }
  func int(_ key: Key, _ fallback: Int = 0) -> Int {
    if let i = (try? decodeIfPresent(Int.self, forKey: key)) ?? nil { return i }
    if let d = (try? decodeIfPresent(Double.self, forKey: key)) ?? nil, d.isFinite { return Int(d) }
    return fallback
  }
  func num(_ key: Key) -> Double? {
    guard let d = (try? decodeIfPresent(Double.self, forKey: key)) ?? nil, d.isFinite else { return nil }
    return d
  }
  func date(_ key: Key) -> Date? { (try? decodeIfPresent(Date.self, forKey: key)) ?? nil }
  func list<T: Decodable>(_ key: Key) -> [T] {
    ((try? decodeIfPresent(LossyList<T>.self, forKey: key)) ?? nil)?.items ?? []
  }
  func obj<T: Decodable>(_ key: Key) -> T? { (try? decodeIfPresent(T.self, forKey: key)) ?? nil }
}

// MARK: - Shared words for states

enum WatchRisk: String, Equatable {
  case low, medium, high
  init?(raw: String?) {
    guard let raw, let r = WatchRisk(rawValue: raw) else { return nil }
    self = r
  }
}

enum WatchBotStatus: String, Equatable {
  case idle, working, waiting, disabled
  init(raw: String) { self = WatchBotStatus(rawValue: raw) ?? .idle }
}

// MARK: - /v1/watch/me

struct WatchPrefs: Decodable, Equatable {
  /// medium (default), low or none.
  var allow: String
  var showDetails: Bool
  var quickReplies: [String]

  private enum CodingKeys: String, CodingKey { case allow, showDetails, quickReplies }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    allow = c.str(.allow, "medium")
    showDetails = c.flag(.showDetails, true)
    quickReplies = ((try? c.decodeIfPresent([String].self, forKey: .quickReplies)) ?? nil)?
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty } ?? []
  }
}

struct WatchSelf: Decodable, Equatable {
  struct Features: Decodable, Equatable {
    var dictation: Bool
    var speech: Bool
    var outOfCredits: Bool
    private enum CodingKeys: String, CodingKey { case dictation, speech, outOfCredits }
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      dictation = c.flag(.dictation)
      speech = c.flag(.speech)
      outOfCredits = c.flag(.outOfCredits)
    }
    init(dictation: Bool = false, speech: Bool = false, outOfCredits: Bool = false) {
      self.dictation = dictation
      self.speech = speech
      self.outOfCredits = outOfCredits
    }
  }

  var keyId: String
  var orgId: String
  var orgName: String
  var personName: String
  var prefs: WatchPrefs?
  var hideReplyText: Bool
  var askBotId: String?
  var features: Features

  private enum CodingKeys: String, CodingKey { case keyId, orgId, orgName, person, prefs, hideReplyText, askBotId, features }
  private enum PersonKeys: String, CodingKey { case name }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    keyId = try c.decode(String.self, forKey: .keyId)
    orgId = try c.decode(String.self, forKey: .orgId)
    orgName = c.str(.orgName)
    personName = ((try? c.nestedContainer(keyedBy: PersonKeys.self, forKey: .person))?.str(.name)) ?? ""
    prefs = c.obj(.prefs)
    hideReplyText = c.flag(.hideReplyText)
    askBotId = c.optStr(.askBotId)
    features = c.obj(.features) ?? Features()
  }

  /// The person's quick replies, or the built-in list.
  var quickReplies: [String] {
    let mine = prefs?.quickReplies ?? []
    return mine.isEmpty ? [WatchL10n.quickYes, WatchL10n.quickNo, WatchL10n.quickTellMore, WatchL10n.quickNotNow] : Array(mine.prefix(6))
  }
}

// MARK: - Signing in with a code

struct WatchCode: Decodable, Equatable {
  var code: String
  var expiresAt: Date
  var pollEveryS: Int

  private enum CodingKeys: String, CodingKey { case code, expiresAt, pollEveryS }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    code = try c.decode(String.self, forKey: .code)
    expiresAt = c.date(.expiresAt) ?? Date().addingTimeInterval(600)
    pollEveryS = max(1, c.int(.pollEveryS, 3))
  }
}

// MARK: - Chats, asks, replies

struct WatchAttachment: Decodable, Equatable {
  /// page, image, video, audio, document, file, card or link.
  var kind: String
  var title: String
  private enum CodingKeys: String, CodingKey { case kind, title }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    kind = c.str(.kind, "file")
    title = c.str(.title)
  }
}

struct WatchMessage: Decodable, Equatable, Identifiable {
  var id: String
  /// user or assistant.
  var role: String
  var text: String
  var cut: Bool
  var attachments: [WatchAttachment]
  var at: Date?
  var canSpeak: Bool

  var isMine: Bool { role == "user" }

  private enum CodingKeys: String, CodingKey { case id, role, text, cut, attachments, at, canSpeak }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    role = c.str(.role, "assistant")
    text = c.str(.text)
    cut = c.flag(.cut)
    attachments = c.list(.attachments)
    at = c.date(.at)
    canSpeak = c.flag(.canSpeak)
  }
}

struct WatchBotHeader: Decodable, Equatable {
  var id: String
  var name: String
  var avatar: String
  var status: WatchBotStatus
  private enum CodingKeys: String, CodingKey { case id, name, avatar, status }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    name = c.str(.name)
    avatar = c.str(.avatar)
    status = WatchBotStatus(raw: c.str(.status))
  }
}

struct WatchChat: Decodable, Equatable {
  var bot: WatchBotHeader
  var conversationId: String?
  var messages: [WatchMessage]
  var runId: String?
  var link: String

  private enum CodingKeys: String, CodingKey { case bot, conversationId, messages, runId, link }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    bot = try c.decode(WatchBotHeader.self, forKey: .bot)
    conversationId = c.optStr(.conversationId)
    messages = c.list(.messages)
    runId = c.optStr(.runId)
    link = c.str(.link)
  }
}

struct WatchAsked: Decodable, Equatable {
  var conversationId: String
  var messageId: String
  var runId: String?
  var heard: String
  private enum CodingKeys: String, CodingKey { case conversationId, messageId, runId, heard }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    conversationId = try c.decode(String.self, forKey: .conversationId)
    messageId = c.str(.messageId)
    runId = c.optStr(.runId)
    heard = c.str(.heard)
  }
}

// MARK: - Requests

struct WatchApproval: Decodable, Equatable, Identifiable {
  /// What this watch may do: allow in one tap, after a hold, or only on the phone. Deny always.
  enum CanAllow: String, Equatable { case tap, hold, phone }
  enum Status: String, Equatable { case pending, approved, denied, expired }

  var id: String
  var runId: String
  var botId: String
  var bot: String
  var botAvatar: String
  var status: Status
  var title: String
  var details: [String]
  var risk: WatchRisk
  var payment: Bool
  var canAllow: CanAllow
  /// high_risk, payment, setting, workspace, not_yours.
  var whyPhone: String?
  var createdAt: Date?
  var expiresAt: Date?
  var link: String

  var isPending: Bool { status == .pending }

  private enum CodingKeys: String, CodingKey {
    case id, runId, botId, bot, botAvatar, status, title, details, risk, payment, canAllow, whyPhone, createdAt, expiresAt, link
  }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    runId = c.str(.runId)
    botId = c.str(.botId)
    bot = c.str(.bot)
    botAvatar = c.str(.botAvatar)
    status = Status(rawValue: c.str(.status)) ?? .pending
    title = c.str(.title)
    details = ((try? c.decodeIfPresent([String].self, forKey: .details)) ?? nil)?.filter { !$0.isEmpty } ?? []
    // An unknown risk is treated as high: the watch never guesses its way to allowing.
    risk = WatchRisk(raw: c.str(.risk)) ?? .high
    payment = c.flag(.payment)
    canAllow = CanAllow(rawValue: c.str(.canAllow)) ?? .phone
    whyPhone = c.optStr(.whyPhone)
    createdAt = c.date(.createdAt)
    expiresAt = c.date(.expiresAt)
    link = c.str(.link)
  }

  /// Why only the phone can allow it, in the person's words.
  var whyPhoneText: String? {
    if let why = WatchWhy.text(whyPhone) { return why }
    return canAllow == .phone ? (payment ? WatchL10n.whyPayment : (risk == .high ? WatchL10n.whyHighRisk : nil)) : nil
  }
}

// MARK: - Runs

enum WatchRunPhase: String, Equatable {
  case working, needsOk = "needs_ok", takeOver = "take_over", finished, problem, stopped
  init(raw: String) { self = WatchRunPhase(rawValue: raw) ?? .working }
  var ended: Bool { self == .finished || self == .problem || self == .stopped }
}

struct WatchRun: Decodable, Equatable, Identifiable {
  var id: String
  var botId: String
  var bot: String
  var botAvatar: String
  var conversationId: String?
  var phase: WatchRunPhase
  var step: String
  var steps: Int
  var startedAt: Date?
  var endedAt: Date?
  var approval: WatchApproval?
  var reply: WatchMessage?
  var link: String

  private enum CodingKeys: String, CodingKey {
    case id, botId, bot, botAvatar, conversationId, phase, step, steps, startedAt, endedAt, approval, reply, link
  }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    botId = c.str(.botId)
    bot = c.str(.bot)
    botAvatar = c.str(.botAvatar)
    conversationId = c.optStr(.conversationId)
    phase = WatchRunPhase(raw: c.str(.phase))
    step = c.str(.step)
    steps = max(0, c.int(.steps))
    startedAt = c.date(.startedAt)
    endedAt = c.date(.endedAt)
    approval = c.obj(.approval)
    reply = c.obj(.reply)
    link = c.str(.link)
  }
}

// MARK: - The glance (GET /v1/glance), as far as a watch reads it

struct Glance: Decodable, Equatable {
  struct Need: Decodable, Equatable, Identifiable {
    /// approval, takeover or suggestion (anything newer opens on the phone).
    var kind: String
    var id: String
    var botId: String
    var bot: String
    var botAvatar: String
    var text: String
    var risk: WatchRisk?
    var urgent: Bool
    var createdAt: Date?
    var link: String

    private enum CodingKeys: String, CodingKey { case kind, id, botId, bot, botAvatar, text, risk, urgent, createdAt, link }
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      kind = c.str(.kind, "other")
      id = try c.decode(String.self, forKey: .id)
      botId = c.str(.botId)
      bot = c.str(.bot)
      botAvatar = c.str(.botAvatar)
      text = c.str(.text)
      risk = WatchRisk(raw: c.optStr(.risk))
      urgent = c.flag(.urgent)
      createdAt = c.date(.createdAt)
      link = c.str(.link)
    }
  }

  struct Bot: Decodable, Equatable, Identifiable {
    var id: String
    var name: String
    var avatar: String
    var status: WatchBotStatus
    var step: String?
    var lastText: String?
    var lastAt: Date?
    var busyAt: Date?
    var link: String

    private enum CodingKeys: String, CodingKey { case id, name, avatar, status, step, lastText, lastAt, busyAt, link }
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      id = try c.decode(String.self, forKey: .id)
      name = c.str(.name)
      avatar = c.str(.avatar)
      status = WatchBotStatus(raw: c.str(.status))
      step = c.optStr(.step)
      lastText = c.optStr(.lastText)
      lastAt = c.date(.lastAt)
      busyAt = c.date(.busyAt)
      link = c.str(.link)
    }
  }

  struct Run: Decodable, Equatable, Identifiable {
    var id: String
    var botId: String
    var bot: String
    var botAvatar: String
    /// working, needs_ok or take_over.
    var phase: WatchRunPhase
    var step: String
    var steps: Int
    var startedAt: Date?
    var approvalId: String?
    var risk: WatchRisk?
    var link: String

    private enum CodingKeys: String, CodingKey { case id, botId, bot, botAvatar, phase, step, steps, startedAt, approvalId, risk, link }
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      id = try c.decode(String.self, forKey: .id)
      botId = c.str(.botId)
      bot = c.str(.bot)
      botAvatar = c.str(.botAvatar)
      phase = WatchRunPhase(raw: c.str(.phase))
      step = c.str(.step)
      steps = max(0, c.int(.steps))
      startedAt = c.date(.startedAt)
      approvalId = c.optStr(.approvalId)
      risk = WatchRisk(raw: c.optStr(.risk))
      link = c.str(.link)
    }
  }

  struct Routine: Decodable, Equatable, Identifiable {
    var id: String
    var botId: String
    var name: String
    var bot: String
    var botAvatar: String
    var nextAt: Date?
    var every: String
    var enabled: Bool
    var link: String

    private enum CodingKeys: String, CodingKey { case id, botId, name, bot, botAvatar, nextAt, every, enabled, link }
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      id = try c.decode(String.self, forKey: .id)
      botId = c.str(.botId)
      name = c.str(.name)
      bot = c.str(.bot)
      botAvatar = c.str(.botAvatar)
      nextAt = c.date(.nextAt)
      every = c.str(.every)
      enabled = c.flag(.enabled, true)
      link = c.str(.link)
    }
  }

  struct RoutineChoice: Decodable, Equatable, Identifiable {
    var id: String
    var botId: String
    var name: String
    var bot: String
    var enabled: Bool

    private enum CodingKeys: String, CodingKey { case id, botId, name, bot, enabled }
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      id = try c.decode(String.self, forKey: .id)
      botId = c.str(.botId)
      name = c.str(.name)
      bot = c.str(.bot)
      enabled = c.flag(.enabled, true)
    }
  }

  struct Brief: Decodable, Equatable {
    var botId: String
    var bot: String
    var botAvatar: String
    var text: String?
    var at: Date?
    var nextAt: Date?
    var link: String

    private enum CodingKeys: String, CodingKey { case botId, bot, botAvatar, text, at, nextAt, link }
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      botId = c.str(.botId)
      bot = c.str(.bot)
      botAvatar = c.str(.botAvatar)
      text = c.optStr(.text)
      at = c.date(.at)
      nextAt = c.date(.nextAt)
      link = c.str(.link)
    }
  }

  struct Credits: Decodable, Equatable {
    var billing: Bool
    var unlimited: Bool
    var plan: String?
    var usedShare: Double?
    var leftUsd: Double?
    var todayUsd: Double
    var monthUsd: Double

    private enum CodingKeys: String, CodingKey { case billing, unlimited, plan, usedShare, leftUsd, todayUsd, monthUsd }
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      billing = c.flag(.billing)
      unlimited = c.flag(.unlimited)
      plan = c.optStr(.plan)
      usedShare = c.num(.usedShare).map { min(1, max(0, $0)) }
      leftUsd = c.num(.leftUsd)
      todayUsd = c.num(.todayUsd) ?? 0
      monthUsd = c.num(.monthUsd) ?? 0
    }
  }

  struct Starter: Decodable, Equatable, Hashable {
    var emoji: String
    var text: String
    private enum CodingKeys: String, CodingKey { case emoji, text }
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      emoji = c.str(.emoji)
      text = try c.decode(String.self, forKey: .text)
    }
  }

  struct Flags: Decodable, Equatable {
    var isPrivate: Bool = false
    var hideReplyText: Bool = false
    private enum CodingKeys: String, CodingKey { case isPrivate = "private", hideReplyText }
    init() {}
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      isPrivate = c.flag(.isPrivate)
      hideReplyText = c.flag(.hideReplyText)
    }
  }

  var version: String
  var madeAt: Date?
  var orgId: String
  var needsCount: Int
  var needs: [Need]
  var bots: [Bot]
  var runs: [Run]
  var next: [Routine]
  var routines: [RoutineChoice]
  var brief: Brief?
  var credits: Credits?
  var starters: [Starter]
  var flags: Flags

  private enum CodingKeys: String, CodingKey { case version, madeAt, orgId, needs, bots, runs, next, routines, brief, credits, starters, flags }
  private enum NeedsKeys: String, CodingKey { case count, items }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    version = c.str(.version)
    madeAt = c.date(.madeAt)
    orgId = c.str(.orgId)
    if let n = try? c.nestedContainer(keyedBy: NeedsKeys.self, forKey: .needs) {
      needs = n.list(.items)
      needsCount = max(n.int(.count, needs.count), needs.count)
    } else {
      needs = []
      needsCount = 0
    }
    bots = c.list(.bots)
    runs = c.list(.runs)
    next = c.list(.next)
    routines = c.list(.routines)
    brief = c.obj(.brief)
    credits = c.obj(.credits)
    starters = c.list(.starters)
    flags = c.obj(.flags) ?? Flags()
  }

  /// Runs still going (the glance only lists live ones, but a cached copy may be old).
  var liveRuns: [Run] { runs.filter { !$0.phase.ended } }

  /// The next routine due, soonest first.
  var nextRoutine: Routine? {
    next.filter { $0.enabled && $0.nextAt != nil }.min { ($0.nextAt ?? .distantFuture) < ($1.nextAt ?? .distantFuture) }
  }

  func bot(_ id: String) -> Bot? { bots.first { $0.id == id } }
  func run(forBot id: String) -> Run? { liveRuns.first { $0.botId == id } }
}

// MARK: - What the watch sends

struct WatchAskBody: Encodable {
  struct Audio: Encodable {
    var data: String
    var mime: String
  }
  var botId: String
  var conversationId: String?
  var text: String?
  var audio: Audio?
  var language: String?
  var askedAt: Date?
  var surface: String?
}

struct WatchDeviceBody: Encodable {
  var fingerprint: String
  var platform = "watchos"
  var name: String
  var model: String?
  var appVersion: String?
  var osVersion: String?
}

struct WatchSelfUpdateBody: Encodable {
  var pushToken: String?
  var pushKind: String?
  var sandbox: Bool?
  var appVersion: String?
  var osVersion: String?
  var name: String?
}

struct WatchHandoffBody: Encodable {
  var link: String
  var title: String
}
