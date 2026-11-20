import Foundation
import ImageIO
import WidgetKit

// MARK: - The Canvas widget's data (docs/BOT-WIDGET-PLAN.md §6, §10.1)
//
// What bots keep on a person's Canvas widget (`GET /v1/canvases`, packages/contracts/src/canvas.ts,
// sample answers in packages/contracts/fixtures/canvases). The server has already cut every text and
// chosen the text colour, so the widget only draws. Stored in the app group beside the glance: under
// the `canvases` key (what the iPhone widget fetched itself, or what the app wrote), or as
// `canvases.json` in the group's folder (what the Mac app writes, MacBridge in
// MainFlutterWindow.swift); the newest of the two wins. Pictures sit in `canvas-pictures/<hash>.jpg`.
// Shared by the iPhone and Mac widget extensions; Foundation, ImageIO and WidgetKit only, so
// scripts/test-canvas-swift.sh compiles it on its own.

struct CanvasList: Decodable, Equatable {
  /// Changes whenever anything in it does; sent back as `If-None-Match`.
  var version: String
  var madeAt: Date
  /// A private widget key (the app lock is on): canvases carry their names and bots only.
  var isPrivate = false
  var items: [BotCanvas] = []
  /// Session only (the app's own fetch); a widget key gets none.
  var grants: [Grant] = []
  var placed: [Placement] = []

  struct Grant: Decodable, Equatable {
    var botId: String
    var bot: String
    var createdAt: Date
  }

  struct Placement: Decodable, Equatable {
    var platform: String
    var label: String?
    var sizes: [String]
    var seenAt: Date
  }
}

/// One canvas (`Canvas` in the contract; named apart from SwiftUI's `Canvas`).
struct BotCanvas: Decodable, Equatable, Identifiable {
  var id: String
  var orgId: String
  /// The bot's name for it ("Daily verse").
  var name: String
  var botId: String
  var bot: String
  /// `mascot:<name>`, or empty for initials.
  var botAvatar: String = ""
  /// waiting | shown | paused. Widgets draw only `shown` (a widget key sees no others; the Mac app's
  /// session list has them all).
  var status: String = "shown"
  var hideWhenLocked = false
  var version: Int = 0
  var setAt: Date
  /// Clears itself at this time.
  var until: Date?
  /// The app route a tap opens.
  var link: String
  var rotation: Rotation?
  /// Up to 14: the one showing now (`at` nil), then the planned ones with their times. Empty for a
  /// private key.
  var entries: [CanvasEntry] = []

  struct Rotation: Decodable, Equatable {
    var count: Int
    var showing: Int
    var left: Int
    var every: String
  }
}

struct CanvasEntry: Decodable, Equatable {
  /// When it shows from; nil for the one showing now.
  var at: Date?
  /// text | countdown | number | list | picture.
  var template: String
  var title: String?
  var text: String?
  var footer: String?
  /// countdown
  var target: Date?
  /// down | up
  var count: String?
  /// number
  var value: Double?
  var of: Double?
  var unit: String?
  /// list
  var items: [Item] = []
  /// picture: its hash in the picture route.
  var picture: String?
  /// For the Lock Screen rectangle (80) and the line above the clock (24).
  var short: String = ""
  var tiny: String = ""
  var look: CanvasLook

  struct Item: Decodable, Equatable {
    var text: String
    var done: Bool
  }
}

struct CanvasLook: Decodable, Equatable {
  var background: CanvasBackground
  /// plain | serif | rounded | mono
  var font: String = "plain"
  /// start | center
  var align: String = "start"
  /// One emoji, or an icon name from the app's set.
  var icon: String?
  /// #rrggbb for rings and bars; nil for the app's accent.
  var accent: String?
  /// light | dark | auto: the text colour the server chose. Never pick another.
  var ink: String = "auto"
}

struct CanvasBackground: Decodable, Equatable {
  /// auto | color | gradient | picture
  var kind: String = "auto"
  var color: String?
  var from: String?
  var to: String?
  var picture: String?
}

// Decoding by hand where a newer server could leave a field out, so one odd canvas or entry is
// skipped (LossyArray) rather than blanking the widget. The memberwise initialisers stay.

extension CanvasList {
  private enum Keys: String, CodingKey { case version, madeAt, isPrivate = "private", items, grants, placed }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: Keys.self)
    version = try c.decode(String.self, forKey: .version)
    madeAt = try c.decode(Date.self, forKey: .madeAt)
    isPrivate = try c.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
    items = try c.decodeIfPresent(LossyArray<BotCanvas>.self, forKey: .items)?.items ?? []
    grants = (try? c.decodeIfPresent(LossyArray<Grant>.self, forKey: .grants))?.items ?? []
    placed = (try? c.decodeIfPresent(LossyArray<Placement>.self, forKey: .placed))?.items ?? []
  }
}

extension BotCanvas {
  private enum Keys: String, CodingKey {
    case id, orgId, name, botId, bot, botAvatar, status, hideWhenLocked, version, setAt, until, link, rotation, entries
  }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: Keys.self)
    id = try c.decode(String.self, forKey: .id)
    orgId = try c.decodeIfPresent(String.self, forKey: .orgId) ?? ""
    name = try c.decode(String.self, forKey: .name)
    botId = try c.decodeIfPresent(String.self, forKey: .botId) ?? ""
    bot = try c.decodeIfPresent(String.self, forKey: .bot) ?? ""
    botAvatar = try c.decodeIfPresent(String.self, forKey: .botAvatar) ?? ""
    status = try c.decodeIfPresent(String.self, forKey: .status) ?? "shown"
    hideWhenLocked = try c.decodeIfPresent(Bool.self, forKey: .hideWhenLocked) ?? false
    version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 0
    setAt = try c.decode(Date.self, forKey: .setAt)
    until = try c.decodeIfPresent(Date.self, forKey: .until)
    link = try c.decodeIfPresent(String.self, forKey: .link) ?? "/bots"
    rotation = try? c.decodeIfPresent(Rotation.self, forKey: .rotation)
    entries = try c.decodeIfPresent(LossyArray<CanvasEntry>.self, forKey: .entries)?.items ?? []
  }
}

extension CanvasEntry {
  private enum Keys: String, CodingKey {
    case at, template, title, text, footer, target, count, value, of, unit, items, picture, short, tiny, look
  }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: Keys.self)
    at = try c.decodeIfPresent(Date.self, forKey: .at)
    template = try c.decode(String.self, forKey: .template)
    title = try c.decodeIfPresent(String.self, forKey: .title)
    text = try c.decodeIfPresent(String.self, forKey: .text)
    footer = try c.decodeIfPresent(String.self, forKey: .footer)
    target = try c.decodeIfPresent(Date.self, forKey: .target)
    count = try c.decodeIfPresent(String.self, forKey: .count)
    value = try c.decodeIfPresent(Double.self, forKey: .value)
    of = try c.decodeIfPresent(Double.self, forKey: .of)
    unit = try c.decodeIfPresent(String.self, forKey: .unit)
    items = try c.decodeIfPresent(LossyArray<Item>.self, forKey: .items)?.items ?? []
    picture = try c.decodeIfPresent(String.self, forKey: .picture)
    short = try c.decodeIfPresent(String.self, forKey: .short) ?? ""
    tiny = try c.decodeIfPresent(String.self, forKey: .tiny) ?? ""
    look = try c.decodeIfPresent(CanvasLook.self, forKey: .look) ?? CanvasLook(background: CanvasBackground())
  }
}

extension CanvasLook {
  private enum Keys: String, CodingKey { case background, font, align, icon, accent, ink }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: Keys.self)
    background = (try? c.decodeIfPresent(CanvasBackground.self, forKey: .background)) ?? CanvasBackground()
    font = try c.decodeIfPresent(String.self, forKey: .font) ?? "plain"
    align = try c.decodeIfPresent(String.self, forKey: .align) ?? "start"
    icon = try c.decodeIfPresent(String.self, forKey: .icon)
    accent = try c.decodeIfPresent(String.self, forKey: .accent)
    ink = try c.decodeIfPresent(String.self, forKey: .ink) ?? "auto"
  }
}

extension CanvasBackground {
  private enum Keys: String, CodingKey { case kind, color, from, to, picture }
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: Keys.self)
    kind = try c.decodeIfPresent(String.self, forKey: .kind) ?? "auto"
    color = try c.decodeIfPresent(String.self, forKey: .color)
    from = try c.decodeIfPresent(String.self, forKey: .from)
    to = try c.decodeIfPresent(String.self, forKey: .to)
    picture = try c.decodeIfPresent(String.self, forKey: .picture)
  }
}

// MARK: - Reading a canvas

extension CanvasEntry {
  /// The picture this entry draws, if any: its own for `picture`, else a picture background.
  var pictureHash: String? {
    if template == "picture", let p = picture, !p.isEmpty { return p }
    if look.background.kind == "picture", let p = look.background.picture, !p.isEmpty { return p }
    return nil
  }

  /// Every picture hash this entry refers to (both, for a picture entry over a picture background).
  var pictureHashes: [String] {
    var out: [String] = []
    if template == "picture", let p = picture, !p.isEmpty { out.append(p) }
    if look.background.kind == "picture", let p = look.background.picture, !p.isEmpty, !out.contains(p) { out.append(p) }
    return out
  }

  /// List rows still to do.
  var itemsLeft: Int { items.filter { !$0.done }.count }

  /// `12`, `12.5`: a number as people write it.
  static func format(_ value: Double) -> String {
    if value.rounded() == value, abs(value) < 1e15 { return String(Int64(value)) }
    return value.formatted(.number.precision(.fractionLength(0...2)))
  }
}

/// An `icon` as the widget draws it: an emoji as text, a known name as a system symbol.
enum CanvasIcon: Equatable {
  case emoji(String)
  case name(String)

  init?(_ raw: String?) {
    guard let s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
    // Icon names are plain lower-case words (`checklist`, `night_sky`); anything else is an emoji.
    let plain = s.unicodeScalars.allSatisfy { ($0.isASCII && (CharacterSet.alphanumerics.contains($0) || "_-.".unicodeScalars.contains($0))) }
    self = plain ? .name(s.lowercased()) : .emoji(s)
  }

  /// The SF Symbol for a name from the app's icon set, when there is a close one. Unknown names
  /// are tried as symbol names as they are, and skipped when the system has none.
  static let symbols: [String: String] = [
    "checklist": "checklist", "list": "list.bullet", "check": "checkmark", "done": "checkmark.circle.fill",
    "star": "star.fill", "heart": "heart.fill", "fire": "flame.fill", "flame": "flame.fill", "streak": "flame.fill",
    "book": "book.fill", "bible": "book.closed.fill", "verse": "book.closed.fill", "quote": "quote.opening",
    "calendar": "calendar", "clock": "clock", "timer": "timer", "alarm": "alarm",
    "plane": "airplane", "flight": "airplane", "travel": "airplane", "car": "car.fill", "train": "tram.fill",
    "sun": "sun.max.fill", "sunrise": "sunrise.fill", "sunset": "sunset.fill", "moon": "moon.fill", "night": "moon.stars.fill",
    "cloud": "cloud.fill", "rain": "cloud.rain.fill", "snow": "snowflake", "weather": "cloud.sun.fill",
    "leaf": "leaf.fill", "plant": "leaf.fill", "bolt": "bolt.fill", "energy": "bolt.fill",
    "trophy": "trophy.fill", "goal": "target", "target": "target", "gift": "gift.fill", "party": "party.popper.fill",
    "music": "music.note", "run": "figure.run", "running": "figure.run", "walk": "figure.walk", "steps": "figure.walk",
    "gym": "dumbbell.fill", "fitness": "dumbbell.fill", "water": "drop.fill", "drop": "drop.fill",
    "coffee": "cup.and.saucer.fill", "food": "fork.knife", "cart": "cart.fill", "shopping": "cart.fill",
    "home": "house.fill", "house": "house.fill", "work": "briefcase.fill", "school": "graduationcap.fill",
    "bell": "bell.fill", "pin": "mappin", "location": "location.fill", "sparkles": "sparkles", "idea": "lightbulb.fill",
    "chart": "chart.bar.fill", "money": "dollarsign.circle.fill", "wallet": "wallet.pass.fill",
    "mail": "envelope.fill", "phone": "phone.fill", "message": "message.fill", "photo": "photo.fill",
    "camera": "camera.fill", "pray": "hands.sparkles.fill", "smile": "face.smiling", "paw": "pawprint.fill",
  ]
}

/// How a countdown reads at one moment (§6.1): whole days as text, under a day the system's own
/// self-ticking timer, and nothing to count once a countdown down has passed.
enum CountdownShow: Equatable {
  /// [days] calendar days to go, or since when [since].
  case days(Int, since: Bool)
  /// Under a day: a timer from [from] to [to] (down), or counting up from [from].
  case timer(from: Date, to: Date, down: Bool)
  /// A countdown down whose time has come.
  case now

  static let day: TimeInterval = 86_400

  static func at(_ date: Date, target: Date, count: String?, calendar: Calendar = .current) -> CountdownShow {
    let up = count == "up"
    if date < target {
      if target.timeIntervalSince(date) < day { return .timer(from: date, to: target, down: true) }
      return .days(max(1, calendar.days(from: date, to: target)), since: false)
    }
    guard up else { return .now }
    if date.timeIntervalSince(target) < day { return .timer(from: target, to: target.addingTimeInterval(day), down: false) }
    return .days(max(1, calendar.days(from: target, to: date)), since: true)
  }
}

extension Calendar {
  /// Calendar days from [a] to [b] (midnight to midnight), in this calendar's time zone.
  func days(from a: Date, to b: Date) -> Int {
    dateComponents([.day], from: startOfDay(for: a), to: startOfDay(for: b)).day ?? 0
  }
}

/// The Canvas widget's own words, with an English copy for when the app hasn't written them (the
/// app writes them with the glance's, under `glance_words`).
extension GlanceWords {
  static let canvasEnglish: [String: String] = [
    "canvas_empty": "Ask a bot to put something here",
    "canvas_try": "Try: put a daily verse on my Lock Screen",
    // The units, as the app writes them (glance_sync.dart, canvasDaysUnit).
    "canvas_day": "day",
    "canvas_days": "days",
    "canvas_in": "in {time}",
    "canvas_since": "{time} since",
    "canvas_now": "Now",
    "canvas_left": "{n} left",
    "canvas_left_unit": "left",
  ]

  func canvas(_ key: String, _ args: [String: String] = [:]) -> String {
    var s = map[key].flatMap { $0.isEmpty ? nil : $0 } ?? Self.canvasEnglish[key] ?? key
    for (k, v) in args { s = s.replacingOccurrences(of: "{\(k)}", with: v) }
    return s
  }

  /// "day" or "days" for [n].
  func canvasDayUnit(_ n: Int) -> String { canvas(n == 1 ? "canvas_day" : "canvas_days") }

  /// "12 days", "1 day".
  func canvasDays(_ n: Int) -> String { "\(n) \(canvasDayUnit(n))" }
}

// MARK: - The store

enum CanvasStore {
  /// The app group key (beside `glance`): the list as JSON.
  static let key = "canvases"
  /// What the Mac app writes into the group's folder.
  static let fileName = "canvases.json"
  static let pictureDirName = "canvas-pictures"
  /// hash → the pixel size a stored picture was shrunk to, so a bigger widget fetches it again.
  static let picturePixelsKey = "canvas_picture_px"

  static func decode(_ data: Data) -> CanvasList? {
    try? GlanceStore.decoder().decode(CanvasList.self, from: data)
  }

  /// The newest list the app or the extension stored, or nil.
  static func load(defaults: UserDefaults? = GlanceStore.defaults, container: URL? = GlanceStore.container) -> CanvasList? {
    let fromDefaults = defaults?.string(forKey: key).flatMap { $0.data(using: .utf8) }.flatMap(decode)
    let fromFile = container.flatMap { try? Data(contentsOf: $0.appendingPathComponent(fileName)) }.flatMap(decode)
    switch (fromDefaults, fromFile) {
    case let (a?, b?): return a.madeAt >= b.madeAt ? a : b
    case let (a?, nil): return a
    case let (nil, b?): return b
    default: return nil
    }
  }

  static func save(_ raw: String, defaults: UserDefaults? = GlanceStore.defaults) {
    defaults?.set(raw, forKey: key)
  }

  /// A hash safe to use as a file name and in a URL path (`painting-night_sky`, hex digests).
  static func safeHash(_ hash: String?) -> String? {
    guard let h = hash, !h.isEmpty, h.count <= 80,
          h.unicodeScalars.allSatisfy({ $0.isASCII && (CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_") }) else { return nil }
    return h
  }

  static func pictureDir(_ container: URL? = GlanceStore.container, create: Bool = false) -> URL? {
    guard let dir = container?.appendingPathComponent(pictureDirName, isDirectory: true) else { return nil }
    if create { try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
    return dir
  }

  static func pictureFile(_ hash: String, container: URL? = GlanceStore.container) -> URL? {
    guard let h = safeHash(hash) else { return nil }
    return pictureDir(container)?.appendingPathComponent("\(h).jpg")
  }

  /// The stored picture for [hash], when there is one.
  static func picture(_ hash: String?) -> URL? {
    guard let hash, let file = pictureFile(hash), FileManager.default.fileExists(atPath: file.path) else { return nil }
    return file
  }

  /// Every (canvas id, hash) the shown canvases draw, in the order they matter: what shows now
  /// first, then what comes later.
  static func wantedPictures(_ list: CanvasList?) -> [(canvas: String, hash: String)] {
    guard let list, !list.isPrivate else { return [] }
    var seen = Set<String>()
    var out: [(String, String)] = []
    let shown = list.items.filter { $0.status == "shown" }
    let maxEntries = shown.map(\.entries.count).max() ?? 0
    for i in 0..<maxEntries {
      for c in shown where i < c.entries.count {
        for h in c.entries[i].pictureHashes {
          guard let h = safeHash(h), !seen.contains(h) else { continue }
          seen.insert(h)
          out.append((c.id, h))
        }
      }
    }
    return out
  }
}

/// Everything the Canvas widget draws from.
struct CanvasSnapshot: Equatable {
  var list: CanvasList?
  var signedIn = false
  var words = GlanceWords()
  /// Sample data for the gallery and the first load.
  var isPlaceholder = false

  static func load(defaults: UserDefaults? = GlanceStore.defaults) -> CanvasSnapshot {
    let glance = GlanceSnapshot.load(from: defaults)
    var s = CanvasSnapshot(words: glance.words)
    s.signedIn = glance.signedIn
    s.list = s.signedIn ? CanvasStore.load(defaults: defaults) : nil
    return s
  }

  /// A believable canvas for the gallery and placeholders.
  static var sample: CanvasSnapshot {
    let now = Date()
    let look = CanvasLook(
      background: CanvasBackground(kind: "gradient", from: "#0b3a53", to: "#1f7a8c"),
      font: "serif", align: "center", icon: "📖", ink: "light")
    let entry = CanvasEntry(
      template: "text", text: "Be still, and know that I am God.", footer: "Ps 46:10",
      short: "Be still, and know that I am God. · Ps 46:10", tiny: "Be still, and know…", look: look)
    let canvas = BotCanvas(
      id: "00000000-0000-0000-0000-0000000000e1", orgId: "00000000-0000-0000-0000-000000000000", name: "Daily verse",
      botId: "00000000-0000-0000-0000-000000000001", bot: "Milo", botAvatar: "mascot:winky", setAt: now,
      link: "/bots", entries: [entry])
    let list = CanvasList(version: "sample", madeAt: now, items: [canvas])
    return CanvasSnapshot(list: list, signedIn: true, words: GlanceWords.load(), isPlaceholder: true)
  }
}

// MARK: - Fetching (the iPhone widget; the Mac app writes for its widget)

enum CanvasFetch {
  static let kind = "CanvasWidget"

  /// The Canvas sizes for the server (`sizes`), from the families of the placed Canvas widgets.
  static func size(of family: WidgetFamily) -> String? {
    switch family {
    case .systemSmall: return "home_small"
    case .systemMedium: return "home_medium"
    case .systemLarge: return "home_large"
    case .systemExtraLarge: return "home_xl"
    #if os(iOS)
    case .accessoryRectangular: return "lock_rect"
    case .accessoryInline: return "lock_inline"
    case .accessoryCircular: return "lock_circle"
    #endif
    default: return nil
    }
  }

  /// The widget's longest side in points for [size], for shrinking pictures.
  static func points(of size: String) -> Int {
    switch size {
    case "home_small": return 170
    case "home_medium": return 364
    case "home_large": return 382
    case "home_xl": return 780
    case "lock_rect": return 172
    case "lock_circle": return 76
    default: return 0
    }
  }

  /// The largest picture any placed size draws, in pixels (at 3x, never more than the server's
  /// 1200).
  static func pixels(for sizes: [String]) -> Int {
    let pts = sizes.map(points(of:)).max() ?? 0
    return min(1200, max(300, (pts == 0 ? 400 : pts) * 3))
  }

  /// The sizes placed now, sorted, in the server's words.
  static func placedSizes() async -> [String] {
    #if os(iOS)
    guard let infos = try? await WidgetCenter.shared.currentConfigurations() else { return [] }
    return Array(Set(infos.filter { $0.kind == kind }.compactMap { size(of: $0.family) })).sorted()
    #else
    // The Mac app reports where its widgets are; this extension doesn't fetch.
    return []
    #endif
  }

  /// What the widget should draw: the stored list, refreshed from the server first when this
  /// device holds a widget key (iPhone and iPad). On the Mac the app writes it (MacBridge).
  static func refresh() async -> CanvasSnapshot {
    var snap = CanvasSnapshot.load()
    #if os(iOS)
    guard snap.signedIn else {
      // Signed out: nothing of the last person's stays behind.
      GlanceStore.defaults?.removeObject(forKey: CanvasStore.key)
      GlanceStore.defaults?.removeObject(forKey: CanvasStore.picturePixelsKey)
      if let dir = CanvasStore.pictureDir() { try? FileManager.default.removeItem(at: dir) }
      return snap
    }
    guard let key = WidgetKey.read(), let base = GlanceFetch.server() else { return snap }
    let sizes = await placedSizes()
    if let fresh = await fetch(base: base, key: key, current: snap.list, sizes: sizes) {
      snap.list = fresh
    }
    await pictures(for: snap.list, base: base, key: key, pixels: pixels(for: sizes))
    // Where only a Canvas widget is placed, it registers the refresh push token itself.
    await GlanceFetch.sendPushToken()
    #endif
    // The bots' own pictures the canvases show (the Mac app writes the list, the widget fetches).
    await GlanceFetch.botPictures(for: GlanceSnapshot.load())
    return snap
  }

  /// GET /v1/canvases. Answers the new list, the current one when unchanged, or nil when it
  /// couldn't ask.
  private static func fetch(base: URL, key: String, current: CanvasList?, sizes: [String]) async -> CanvasList? {
    guard var c = URLComponents(url: base.appendingPathComponent("v1/canvases"), resolvingAgainstBaseURL: false) else { return nil }
    var query: [URLQueryItem] = []
    if let org = GlanceStore.glance()?.orgId ?? current?.items.first?.orgId, !org.isEmpty {
      query.append(URLQueryItem(name: "org_id", value: org))
    }
    query.append(URLQueryItem(name: "sizes", value: sizes.joined(separator: ",")))
    c.queryItems = query
    guard let url = c.url else { return nil }
    var req = URLRequest(url: url)
    req.setValue("Widget \(key)", forHTTPHeaderField: "Authorization")
    if let v = current?.version { req.setValue("\"\(v)\"", forHTTPHeaderField: "If-None-Match") }
    req.setValue("application/json", forHTTPHeaderField: "Accept")
    guard let (data, response) = try? await GlanceFetch.session.data(for: req), let http = response as? HTTPURLResponse else { return nil }
    switch http.statusCode {
    case 304:
      return current
    case 200:
      guard let fresh = CanvasStore.decode(data) else { return nil }
      // The app may have written a newer one while this was in flight: keep the newest.
      if let stored = CanvasStore.load(), stored.madeAt > fresh.madeAt { return stored }
      if let text = String(data: data, encoding: .utf8) { CanvasStore.save(text) }
      return fresh
    default:
      return nil
    }
  }

  /// Fetches the pictures [list] draws that aren't stored at [pixels] yet
  /// (GET /v1/canvases/{id}/pictures/{hash}), shrunk and saved as JPEG, one at a time within the
  /// widget's time; deletes the ones no longer drawn.
  static func pictures(for list: CanvasList?, base: URL, key: String, pixels: Int) async {
    let wanted = CanvasStore.wantedPictures(list)
    guard let dir = CanvasStore.pictureDir(create: true) else { return }
    let defaults = GlanceStore.defaults
    var sizes = defaults?.dictionary(forKey: CanvasStore.picturePixelsKey) as? [String: Int] ?? [:]
    let deadline = Date().addingTimeInterval(GlanceFetch.timeout)
    for (canvas, hash) in wanted {
      guard Date() < deadline, let file = CanvasStore.pictureFile(hash) else { break }
      if FileManager.default.fileExists(atPath: file.path), (sizes[hash] ?? 0) >= pixels { continue }
      var req = URLRequest(url: base.appendingPathComponent("v1/canvases/\(canvas)/pictures/\(hash)"))
      req.setValue("Widget \(key)", forHTTPHeaderField: "Authorization")
      guard let (data, response) = try? await GlanceFetch.session.data(for: req),
            (response as? HTTPURLResponse)?.statusCode == 200,
            !data.isEmpty, data.count <= GlanceFetch.maxCoverBytes,
            let jpeg = shrink(data, pixels: pixels),
            (try? jpeg.write(to: file, options: .atomic)) != nil else { continue }
      sizes[hash] = pixels
    }
    let keep = Set(wanted.map { "\($0.hash).jpg" })
    if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
      for f in files where !keep.contains(f.lastPathComponent) { try? FileManager.default.removeItem(at: f) }
    }
    defaults?.set(sizes.filter { keep.contains("\($0.key).jpg") }, forKey: CanvasStore.picturePixelsKey)
  }

  /// [data] scaled down to [pixels] on its long side and encoded as JPEG.
  static func shrink(_ data: Data, pixels: Int) -> Data? {
    guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: pixels,
    ]
    guard let image = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else { return nil }
    let out = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(out as CFMutableData, "public.jpeg" as CFString, 1, nil) else { return nil }
    CGImageDestinationAddImage(dest, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
    guard CGImageDestinationFinalize(dest) else { return nil }
    return out as Data
  }
}
