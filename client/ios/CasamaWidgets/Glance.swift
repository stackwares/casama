import Foundation

// MARK: - The glance (D-405, docs/WIDGETS-PLAN.md §8.1, §17)
//
// One small summary the server builds (`GET /v1/glance`, packages/contracts/src/glance.ts) and
// the app writes where widgets read it, beside the widgets' words. Compiled into the iPhone app,
// its widget extension and the Mac widget extension, so it stays Foundation-only. Native code holds
// no text of its own beyond an English copy of the words for when the app hasn't written them.

/// Where the app and its widgets share data: the App Group on iPhone, the Team-ID-named app group
/// on the Mac (a sandboxed Mac extension can only use one named after the team, §8.8).
enum GlanceStore {
  #if os(macOS)
  static let groupId = "V8V5US964Z.ai.casama.app"
  #else
  static let groupId = "group.ai.casama.app"
  #endif

  static var defaults: UserDefaults? { UserDefaults(suiteName: groupId) }

  /// The shared container, for cached creation covers.
  static var container: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId)
  }

  // The store layout (§17). The app writes the first four; the extension writes back what it
  // fetched itself (Phase 3) under the same `glance` key, so both always read the newest one.
  static let glanceKey = "glance"
  static let wordsKey = "glance_words"
  static let serverKey = "glance_server"
  static let signedInKey = "glance_signed_in"
  /// The last WidgetKit push token the extension registered, so it is sent once (Phase 3).
  static let pushTokenKey = "glance_push_token"
  static let pushTokenSentKey = "glance_push_token_sent"
  /// When the stored glance was last confirmed current by the server (a 200 or a 304), as an
  /// epoch-milliseconds string. The app writes it on its own fetches, the extension on its own.
  static let checkedKey = "glance_checked_at"
  /// "1" when the server has no /v1/glance yet (§6.6: "Update your Casama server").
  static let unsupportedKey = "glance_unsupported"

  /// When the glance was last confirmed. Reads the epoch-ms string, and numbers in either unit.
  static func checkedAt(_ defaults: UserDefaults? = defaults) -> Date? {
    guard let raw = defaults?.object(forKey: checkedKey) else { return nil }
    let value: Double?
    switch raw {
    case let s as String: value = Double(s.trimmingCharacters(in: .whitespaces))
    case let n as NSNumber: value = n.doubleValue
    default: value = nil
    }
    guard let v = value, v > 0 else { return nil }
    // Anything past year 33658 in seconds is really milliseconds.
    return Date(timeIntervalSince1970: v > 1e12 ? v / 1000 : v)
  }

  /// Notes that the server just confirmed the glance (the same format the app writes).
  static func markChecked(_ defaults: UserDefaults? = defaults, at date: Date = Date()) {
    defaults?.set(String(Int64(date.timeIntervalSince1970 * 1000)), forKey: checkedKey)
  }
  /// Routines started from a widget, id → seconds since 1970, so Run now can say Started.
  static let startedKey = "glance_started"

  /// Notes that [routine] was just started from a widget or control (RunRoutineWidgetIntent).
  static func markStarted(_ routine: String) {
    guard let d = defaults, !routine.isEmpty else { return }
    let now = Date().timeIntervalSince1970
    var map = (d.dictionary(forKey: startedKey) as? [String: Double] ?? [:]).filter { now - $0.value < 3600 }
    map[routine] = now
    d.set(map, forKey: startedKey)
  }

  static func decoder() -> JSONDecoder {
    let d = JSONDecoder()
    d.keyDecodingStrategy = .convertFromSnakeCase
    d.dateDecodingStrategy = .custom { decoder in
      let raw = try decoder.singleValueContainer().decode(String.self)
      if let date = GlanceDate.parse(raw) { return date }
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not an ISO 8601 time: \(raw)"))
    }
    return d
  }

  /// The glance as stored, or nil when there is none or it can't be read.
  static func glance(from defaults: UserDefaults? = defaults) -> Glance? {
    guard let raw = defaults?.string(forKey: glanceKey), let data = raw.data(using: .utf8) else { return nil }
    return try? decoder().decode(Glance.self, from: data)
  }
}

enum GlanceDate {
  /// The server writes times with an offset, with or without fractions of a second.
  static func parse(_ raw: String) -> Date? {
    let withFraction = ISO8601DateFormatter()
    withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = withFraction.date(from: raw) { return d }
    let plain = ISO8601DateFormatter()
    plain.formatOptions = [.withInternetDateTime]
    return plain.date(from: raw)
  }
}

/// Decodes an array item by item, skipping any it can't read, so one odd row (a kind a newer
/// server added) never blanks a whole widget.
struct LossyArray<Element: Decodable>: Decodable {
  var items: [Element] = []
  init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    while !c.isAtEnd {
      if let item = try? c.decode(Element.self) {
        items.append(item)
      } else {
        _ = try? c.decode(Skip.self)
      }
    }
  }
  private struct Skip: Decodable {}
}

struct Glance: Decodable, Equatable {
  /// Every bot avatar value the glance names, for fetching the bots' own pictures.
  var avatars: [String] {
    needs.map(\.botAvatar) + bots.map(\.avatar) + next.map(\.botAvatar) + lately.map(\.botAvatar)
      + (brief.map { [$0.botAvatar] } ?? [])
  }

  struct Need: Decodable, Equatable, Identifiable {
    /// approval, takeover or suggestion.
    let kind: String
    let id: String
    let botId: String
    let bot: String
    let botAvatar: String
    let text: String
    /// low, medium or high; approvals only.
    let risk: String?
    let urgent: Bool
    let createdAt: Date
    let link: String
  }

  struct Bot: Decodable, Equatable, Identifiable {
    let id: String
    let name: String
    let avatar: String
    /// idle, working, waiting or disabled.
    let status: String
    let step: String?
    let lastText: String?
    let lastAt: Date?
    let busyAt: Date?
    let link: String
  }

  struct Routine: Decodable, Equatable, Identifiable {
    let id: String
    let botId: String
    let name: String
    let bot: String
    let botAvatar: String
    let nextAt: Date?
    let every: String
    let enabled: Bool
    let link: String
  }

  /// One of the person's routines for the pickers (`routines`, up to 20), whether or not it is due.
  struct RoutineRef: Decodable, Equatable, Identifiable {
    let id: String
    let botId: String
    let name: String
    let bot: String
    let enabled: Bool

    init(id: String, botId: String, name: String, bot: String, enabled: Bool = true) {
      self.id = id
      self.botId = botId
      self.name = name
      self.bot = bot
      self.enabled = enabled
    }

    init(_ r: Routine) { self.init(id: r.id, botId: r.botId, name: r.name, bot: r.bot, enabled: r.enabled) }

    private enum Keys: String, CodingKey { case id, botId, name, bot, enabled }
    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: Keys.self)
      id = try c.decode(String.self, forKey: .id)
      botId = try c.decode(String.self, forKey: .botId)
      name = try c.decode(String.self, forKey: .name)
      bot = (try? c.decodeIfPresent(String.self, forKey: .bot)) ?? ""
      enabled = (try? c.decodeIfPresent(Bool.self, forKey: .enabled)) ?? true
    }
  }

  struct Brief: Decodable, Equatable {
    let botId: String
    let bot: String
    let botAvatar: String
    let text: String?
    let at: Date?
    let nextAt: Date?
    let link: String
  }

  struct Done: Decodable, Equatable {
    let botId: String
    let bot: String
    let botAvatar: String
    let title: String
    let at: Date
    let link: String
  }

  struct Creation: Decodable, Equatable, Identifiable {
    let id: String
    /// page, image, video, audio, document or file.
    let kind: String
    let title: String
    let bot: String?
    let hasCover: Bool
    let version: Int
    let at: Date
    let link: String
  }

  /// A row of the board (named so it doesn't hide Swift's Task inside Glance).
  struct BoardTask: Decodable, Equatable, Identifiable {
    let id: String
    let title: String
    /// todo, in_progress, in_review, blocked or done.
    let status: String
    let bot: String?
    let link: String
  }

  struct Credits: Decodable, Equatable {
    var billing = false
    var unlimited = false
    var plan: String?
    var usedShare: Double?
    var leftUsd: Double?
    var todayUsd: Double = 0
    var monthUsd: Double = 0
    var dailyCapUsd: Double?
    var dailyUsedUsd: Double?
    var resetsAt: Date?

    init() {}
  }

  struct Starter: Decodable, Equatable {
    let emoji: String
    let text: String
  }

  struct TaskCounts: Decodable, Equatable {
    var todo = 0
    var inProgress = 0
    var inReview = 0
    var blocked = 0
    init() {}
  }

  struct Flags: Equatable {
    /// Counts and general words only: the writer has already left out a person's own words.
    var isPrivate = false
    var hideReplyText = false
  }

  var version: String
  var madeAt: Date
  var orgId: String
  var needsCount = 0
  var needs: [Need] = []
  var bots: [Bot] = []
  var next: [Routine] = []
  /// Every routine, for the pickers; nil from a server that doesn't send the list yet.
  var routines: [RoutineRef]?
  var brief: Brief?
  var lately: [Done] = []
  var recent: [Creation] = []
  var taskCounts = TaskCounts()
  var tasks: [BoardTask] = []
  var credits = Credits()
  var starters: [Starter] = []
  var flags = Flags()
  /// When the server last said this is still current (a "not changed" answer); not in the JSON.
  var checkedAt: Date?

  init(version: String, madeAt: Date, orgId: String) {
    self.version = version
    self.madeAt = madeAt
    self.orgId = orgId
  }

  private enum Keys: String, CodingKey {
    case version, madeAt, orgId, needs, bots, next, routines, brief, lately, recent, tasks, credits, starters, flags
  }
  private enum NeedsKeys: String, CodingKey { case count, items }
  private enum TasksKeys: String, CodingKey { case counts, items }
  private enum FlagsKeys: String, CodingKey {
    case isPrivate = "private"
    case hideReplyText
  }

  // Everything past the three ids is read leniently: a part an older server leaves out reads as
  // empty, and a part that can't be read doesn't take the rest down with it.
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: Keys.self)
    version = try c.decode(String.self, forKey: .version)
    madeAt = try c.decode(Date.self, forKey: .madeAt)
    orgId = try c.decode(String.self, forKey: .orgId)
    if let n = try? c.nestedContainer(keyedBy: NeedsKeys.self, forKey: .needs) {
      needsCount = (try? n.decode(Int.self, forKey: .count)) ?? 0
      needs = (try? n.decode(LossyArray<Need>.self, forKey: .items))?.items ?? []
      needsCount = max(needsCount, needs.count)
    }
    bots = (try? c.decode(LossyArray<Bot>.self, forKey: .bots))?.items ?? []
    next = (try? c.decode(LossyArray<Routine>.self, forKey: .next))?.items ?? []
    routines = (try? c.decodeIfPresent(LossyArray<RoutineRef>.self, forKey: .routines))?.items
    brief = try? c.decodeIfPresent(Brief.self, forKey: .brief)
    lately = (try? c.decode(LossyArray<Done>.self, forKey: .lately))?.items ?? []
    recent = (try? c.decode(LossyArray<Creation>.self, forKey: .recent))?.items ?? []
    if let t = try? c.nestedContainer(keyedBy: TasksKeys.self, forKey: .tasks) {
      taskCounts = (try? t.decode(TaskCounts.self, forKey: .counts)) ?? TaskCounts()
      tasks = (try? t.decode(LossyArray<BoardTask>.self, forKey: .items))?.items ?? []
    }
    credits = (try? c.decode(Credits.self, forKey: .credits)) ?? Credits()
    starters = (try? c.decode(LossyArray<Starter>.self, forKey: .starters))?.items ?? []
    if let f = try? c.nestedContainer(keyedBy: FlagsKeys.self, forKey: .flags) {
      flags.isPrivate = (try? f.decode(Bool.self, forKey: .isPrivate)) ?? false
      flags.hideReplyText = (try? f.decode(Bool.self, forKey: .hideReplyText)) ?? false
    }
  }
}

// MARK: - True or dated (§4 principle 5, §6.6)

extension Glance {
  /// Past this, "Working" is no longer claimed: the bot may well have finished.
  static let workingFor: TimeInterval = 10 * 60
  /// Past this, widgets that speak about now say how old they are ("As of 9:41").
  static let freshFor: TimeInterval = 30 * 60

  /// How recent what this says is: when it was made, or last confirmed unchanged.
  var freshAt: Date { max(madeAt, checkedAt ?? madeAt) }

  func isStale(at date: Date) -> Bool { date.timeIntervalSince(freshAt) > Self.workingFor }
  func showsAge(at date: Date) -> Bool { date.timeIntervalSince(freshAt) > Self.freshFor }

  /// Where a bot stands at [date]: working drops to idle once the data is too old to say so.
  func status(of bot: Bot, at date: Date) -> String {
    if bot.status == "working" && isStale(at: date) { return "idle" }
    return bot.status
  }

  /// The bot a widget was set to, else the first one.
  func bot(_ id: String?) -> Bot? {
    if let id, let b = bots.first(where: { $0.id == id }) { return b }
    return bots.first
  }

  /// Routines still ahead of [date], soonest first. A routine whose time has passed leaves the
  /// list until the next glance says when it runs again.
  /// What the routine pickers offer: the full `routines` list when the server sends it (turned-off
  /// ones left out), else what's coming up in `next`.
  var pickableRoutines: [RoutineRef] {
    if let routines { return routines.filter(\.enabled) }
    return next.map(RoutineRef.init)
  }

  func upcoming(at date: Date) -> [Routine] {
    next.filter { $0.enabled && ($0.nextAt.map { $0 > date } ?? false) }
      .sorted { ($0.nextAt ?? .distantFuture) < ($1.nextAt ?? .distantFuture) }
  }

  /// The moments ahead at which what a widget shows changes by itself: each routine's run, the
  /// brief's hour, and the points where the data turns stale and then dated.
  func moments(after now: Date) -> [Date] {
    var out = next.compactMap(\.nextAt)
    if let b = brief?.nextAt { out.append(b) }
    out.append(freshAt.addingTimeInterval(Self.workingFor + 1))
    out.append(freshAt.addingTimeInterval(Self.freshFor + 1))
    return Array(Set(out.filter { $0 > now })).sorted().prefix(12).map { $0 }
  }
}

// MARK: - The widgets' words (§17), from app_en.arb, with an English copy for when they're missing

struct GlanceWords: Equatable {
  var map: [String: String] = [:]

  /// The word for [key], with `{bot}`, `{time}`, `{n}`, `{amount}` and `{title}` filled in.
  func callAsFunction(_ key: String, _ args: [String: String] = [:]) -> String {
    var s = map[key].flatMap { $0.isEmpty ? nil : $0 } ?? Self.english[key] ?? key
    for (k, v) in args { s = s.replacingOccurrences(of: "{\(k)}", with: v) }
    return s
  }

  static func load(from defaults: UserDefaults? = GlanceStore.defaults) -> GlanceWords {
    guard let raw = defaults?.string(forKey: GlanceStore.wordsKey), let data = raw.data(using: .utf8),
          let map = try? JSONDecoder().decode([String: String].self, from: data) else { return GlanceWords() }
    return GlanceWords(map: map)
  }

  static let english: [String: String] = [
    "needs_you": "Needs you",
    "all_clear": "All clear",
    "allow": "Allow",
    "deny": "Deny",
    "review": "Review",
    "low_risk": "Low risk",
    "open": "Open",
    "do_it": "Do it",
    "run_now": "Run now",
    "started": "Started",
    "stop": "Stop",
    "ask": "Ask",
    "ask_bot": "Ask {bot} anything",
    "talk": "Talk",
    "try": "Try",
    "up_next": "Up next",
    "no_routines": "No routines yet",
    "working": "Working",
    "waiting": "Waiting for you",
    "idle": "Idle",
    "off": "Turned off",
    "replied_at": "Replied {time}",
    "brief": "Morning brief",
    "brief_at": "Brief at {time}",
    "no_brief": "No brief yet",
    "today": "Today",
    "credits": "Credits",
    "credits_left": "{amount} left",
    "spent_today": "{amount} today",
    "this_month": "This month",
    "used_pct": "{n}% used",
    "resets_at": "Resets {time}",
    "finished": "{bot} finished {title}",
    "library": "Library",
    "no_creations": "Nothing made yet",
    "tasks": "Tasks",
    "todo": "To do",
    "in_progress": "In progress",
    "in_review": "In review",
    "blocked": "Blocked",
    "sign_in": "Open Casama to sign in",
    "no_bots": "Meet your first bot",
    "as_of": "As of {time}",
    "update_server": "Update your Casama server to use this widget",
    "needs_ok_from": "{bot} needs your OK",
    "suggests": "{bot} suggests",
    "take_over": "{bot} needs you to take over",
    "next_brief": "Next brief {time}",
    "nothing_next": "Nothing coming up",
  ]
}

// MARK: - Everything a widget draws from

/// What the app wrote before D-405 (home_widget's four strings for the first bot). A server too old
/// for the glance still has these, so the Bot widget keeps working on it (§6.6).
struct LegacyBot: Equatable {
  let name: String
  let avatar: String?
  let status: String
}

struct GlanceSnapshot: Equatable {
  var glance: Glance?
  var words = GlanceWords()
  var signedIn = false
  var legacy: LegacyBot?
  /// Sample data for the widget gallery and the first load (drawn greyed, never a spinner).
  var isPlaceholder = false

  /// Routines the person ran from a widget lately (RunRoutineWidgetIntent), by id, so Run now
  /// can say Started until the glance catches up.
  var started: [String: Date] = [:]

  /// The app found no /v1/glance on the server (`glance_unsupported` = "1").
  var unsupported = false

  /// Signed in, but the server doesn't have the route yet (the app said so, or wrote no glance).
  var serverTooOld: Bool { signedIn && (unsupported || glance == nil) }

  static func load(from defaults: UserDefaults? = GlanceStore.defaults) -> GlanceSnapshot {
    var s = GlanceSnapshot()
    s.words = GlanceWords.load(from: defaults)
    s.glance = GlanceStore.glance(from: defaults)
    s.glance?.checkedAt = GlanceStore.checkedAt(defaults)
    s.unsupported = defaults?.string(forKey: GlanceStore.unsupportedKey) == "1"
    let flag = defaults?.string(forKey: GlanceStore.signedInKey)
    if let name = defaults?.string(forKey: "bot_name"), !name.isEmpty {
      s.legacy = LegacyBot(name: name, avatar: defaults?.string(forKey: "bot_avatar"), status: defaults?.string(forKey: "bot_status") ?? "")
    }
    for (id, t) in defaults?.dictionary(forKey: GlanceStore.startedKey) as? [String: Double] ?? [:] {
      s.started[id] = Date(timeIntervalSince1970: t)
    }
    // An app from before D-405 writes no sign-in flag; its strings mean someone is signed in.
    s.signedIn = flag == "1" || (flag == nil && (s.glance != nil || s.legacy != nil))
    if !s.signedIn { s.glance = nil }
    return s
  }

  /// A believable summary for the gallery and placeholders.
  static var sample: GlanceSnapshot {
    let now = Date()
    var g = Glance(version: "sample", madeAt: now, orgId: "00000000-0000-0000-0000-000000000000")
    let milo = "00000000-0000-0000-0000-000000000001", ada = "00000000-0000-0000-0000-000000000002"
    g.needsCount = 2
    g.needs = [
      Glance.Need(kind: "approval", id: "00000000-0000-0000-0000-0000000000a1", botId: milo, bot: "Milo", botAvatar: "mascot:winky", text: "Look up flights to Lisbon", risk: "low", urgent: false, createdAt: now, link: "/approvals/00000000-0000-0000-0000-0000000000a1"),
      Glance.Need(kind: "suggestion", id: "00000000-0000-0000-0000-0000000000a2", botId: ada, bot: "Ada", botAvatar: "mascot:focused", text: "Move the dentist to Friday?", risk: nil, urgent: false, createdAt: now, link: "/bots/\(ada)/chat"),
    ]
    g.bots = [
      Glance.Bot(id: milo, name: "Milo", avatar: "mascot:winky", status: "idle", step: nil, lastText: "Three emails need a reply, and the Acme invoice is two days overdue.", lastAt: now.addingTimeInterval(-1200), busyAt: now.addingTimeInterval(-1200), link: "/bots/\(milo)/chat"),
      Glance.Bot(id: ada, name: "Ada", avatar: "mascot:focused", status: "working", step: "Reading your inbox", lastText: nil, lastAt: nil, busyAt: now, link: "/bots/\(ada)/chat"),
    ]
    g.next = [
      Glance.Routine(id: "00000000-0000-0000-0000-0000000000b1", botId: ada, name: "Inbox sweep", bot: "Ada", botAvatar: "mascot:focused", nextAt: now.addingTimeInterval(18 * 60), every: "Weekdays", enabled: true, link: "/bots/\(ada)/routines"),
      Glance.Routine(id: "00000000-0000-0000-0000-0000000000b2", botId: milo, name: "Morning brief", bot: "Milo", botAvatar: "mascot:winky", nextAt: now.addingTimeInterval(20 * 3600), every: "Every day", enabled: true, link: "/bots/\(milo)/routines"),
      Glance.Routine(id: "00000000-0000-0000-0000-0000000000b3", botId: milo, name: "Weekly report", bot: "Milo", botAvatar: "mascot:winky", nextAt: now.addingTimeInterval(2 * 86400), every: "Fridays at 16:00", enabled: true, link: "/bots/\(milo)/routines"),
    ]
    g.brief = Glance.Brief(botId: milo, bot: "Milo", botAvatar: "mascot:winky", text: "Three emails need a reply, and the Acme invoice is two days overdue. Rain from 3 pm, so leave early for the 4:30 pickup. Your first meeting is at 10:00 with Dana.", at: now.addingTimeInterval(-3 * 3600), nextAt: now.addingTimeInterval(20 * 3600), link: "/bots/\(milo)/chat")
    g.lately = [Glance.Done(botId: ada, bot: "Ada", botAvatar: "mascot:focused", title: "Q4 pricing page", at: now.addingTimeInterval(-1800), link: "/bots/\(ada)/chat")]
    g.recent = [
      Glance.Creation(id: "00000000-0000-0000-0000-0000000000c1", kind: "image", title: "Logo ideas", bot: "Ada", hasCover: false, version: 1, at: now, link: "/library"),
      Glance.Creation(id: "00000000-0000-0000-0000-0000000000c2", kind: "page", title: "Q4 pricing page", bot: "Ada", hasCover: false, version: 1, at: now, link: "/library"),
      Glance.Creation(id: "00000000-0000-0000-0000-0000000000c3", kind: "document", title: "Trip plan", bot: "Milo", hasCover: false, version: 1, at: now, link: "/library"),
    ]
    g.taskCounts.todo = 4
    g.taskCounts.inProgress = 2
    g.taskCounts.inReview = 1
    g.tasks = [Glance.BoardTask(id: "00000000-0000-0000-0000-0000000000d1", title: "Draft the launch post", status: "in_review", bot: "Ada", link: "/tasks")]
    g.credits.billing = true
    g.credits.usedShare = 0.62
    g.credits.leftUsd = 5.70
    g.credits.todayUsd = 0.42
    g.starters = [Glance.Starter(emoji: "🧾", text: "Sum up my inbox"), Glance.Starter(emoji: "🗓", text: "Plan my Friday")]
    return GlanceSnapshot(glance: g, words: GlanceWords.load(), signedIn: true, legacy: nil, isPlaceholder: true)
  }
}
