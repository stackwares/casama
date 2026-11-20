import CoreGraphics
import Foundation
import ImageIO
import WidgetKit

// MARK: - The Canvas widget's pure Swift, checked on macOS (scripts/test-canvas-swift.sh)
//
// Decodes every shared sample answer (packages/contracts/fixtures/canvases, the same files the
// server's, the app's and Android's tests read), and checks the timeline's picks and moments,
// countdowns, icons, sizes, the store and picture shrinking. No XCTest: a plain executable, so it
// runs without a build of the app or a simulator.

@main
struct CanvasTests {
  static var failures = 0
  static var checks = 0

  static func check(_ ok: Bool, _ what: String, file: String = #fileID, line: Int = #line) {
    checks += 1
    if !ok {
      failures += 1
      print("FAIL \(file):\(line) \(what)")
    }
  }

  static func eq<T: Equatable>(_ a: T, _ b: T, _ what: String, file: String = #fileID, line: Int = #line) {
    check(a == b, "\(what): got \(a), want \(b)", file: file, line: line)
  }

  static func date(_ s: String) -> Date { GlanceDate.parse(s)! }

  static var utc: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
  }

  static func main() {
    let dir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "packages/contracts/fixtures/canvases")
    fixtures(dir)
    if let list = load(dir.appendingPathComponent("canvases.json")) {
      sample(list)
      plan(list)
      store(dir)
    }
    if let list = load(dir.appendingPathComponent("private.json")) { privateList(list) }
    countdowns()
    icons()
    sizes()
    words()
    shrinking()
    print("\(checks) checks, \(failures) failed")
    exit(failures == 0 ? 0 : 1)
  }

  // MARK: Fixtures

  static func load(_ url: URL) -> CanvasList? {
    do {
      return try GlanceStore.decoder().decode(CanvasList.self, from: Data(contentsOf: url))
    } catch {
      check(false, "\(url.lastPathComponent): \(error)")
      return nil
    }
  }

  static let templates: Set<String> = ["text", "countdown", "number", "list", "picture"]

  /// Every fixture decodes in full (nothing skipped) and holds to the contract's limits.
  static func fixtures(_ dir: URL) {
    guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path).filter({ $0.hasSuffix(".json") }).sorted(),
          !names.isEmpty else {
      check(false, "no fixtures in \(dir.path)")
      return
    }
    for name in names {
      let url = dir.appendingPathComponent(name)
      guard let list = load(url),
            let raw = try? JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] else { continue }
      let rawItems = raw["items"] as? [[String: Any]] ?? []
      eq(list.items.count, rawItems.count, "\(name): canvases decoded")
      check(list.items.count <= 12, "\(name): at most 12 canvases")
      for (c, rawC) in zip(list.items, rawItems) {
        eq(c.entries.count, (rawC["entries"] as? [Any])?.count ?? -1, "\(name) \(c.name): entries decoded")
        check(c.entries.count <= 14, "\(name) \(c.name): at most 14 entries")
        check(!c.link.isEmpty && !c.name.isEmpty && !c.bot.isEmpty, "\(name) \(c.name): link, name and bot")
        if list.isPrivate { eq(c.entries.count, 0, "\(name) \(c.name): a private list has no entries") }
        if let first = c.entries.first { check(first.at == nil, "\(name) \(c.name): the first entry shows now") }
        for (i, e) in c.entries.enumerated() {
          check(templates.contains(e.template), "\(name) \(c.name)[\(i)]: template \(e.template)")
          check(e.short.count <= 80 && !e.short.isEmpty, "\(name) \(c.name)[\(i)]: short")
          check(e.tiny.count <= 24 && !e.tiny.isEmpty, "\(name) \(c.name)[\(i)]: tiny")
          check(["light", "dark", "auto"].contains(e.look.ink), "\(name) \(c.name)[\(i)]: ink")
          check(["auto", "color", "gradient", "picture"].contains(e.look.background.kind), "\(name) \(c.name)[\(i)]: background")
          if i > 0 { check(e.at != nil, "\(name) \(c.name)[\(i)]: a later entry has a time") }
          if i > 1, let a = c.entries[i - 1].at, let b = e.at { check(b > a, "\(name) \(c.name)[\(i)]: entries in order") }
          for h in e.pictureHashes { check(CanvasStore.safeHash(h) != nil, "\(name): picture hash \(h) is safe") }
        }
      }
    }
  }

  static func sample(_ list: CanvasList) {
    check(!list.isPrivate, "canvases.json isn't private")
    eq(list.madeAt, date("2027-03-10T09:00:00.000Z"), "made_at")
    eq(Set(list.items.compactMap { $0.entries.first?.template }), templates, "every template")
    let verse = list.items[0]
    eq(verse.name, "Daily verse", "first canvas")
    eq(verse.entries.count, 14, "a rotation's 14 entries")
    eq(verse.rotation?.count, 3, "rotation count")
    eq(verse.entries[0].look.background.picture, "painting-night_sky", "a painting background")
    eq(verse.entries[0].pictureHash, "painting-night_sky", "the verse's picture")
    eq(verse.entries[0].look.font, "serif", "font")
    eq(verse.entries[0].look.align, "center", "align")
    let streak = list.items[2]
    check(streak.hideWhenLocked, "Streak hides when locked")
    eq(streak.entries[0].value, 12, "value")
    eq(streak.entries[0].of, 30, "of")
    eq(streak.entries[0].look.accent, "#e65100", "accent")
    eq(list.items[3].entries[0].items.count, 4, "list rows")
    eq(list.items[3].entries[0].itemsLeft, 3, "list rows left")
    eq(list.items[4].entries[0].pictureHash, "0123456789abcdef0123456789abcdef", "a picture entry")
    let wanted = CanvasStore.wantedPictures(list)
    eq(wanted.map(\.hash), ["painting-night_sky", "0123456789abcdef0123456789abcdef"], "pictures wanted, once each")
    eq(wanted.last?.canvas, list.items[4].id, "a picture's canvas")
    eq(list.grants.count, 1, "grants")
    eq(list.placed.first?.sizes ?? [], ["home_small", "lock_rect"], "placed sizes")
  }

  static func privateList(_ list: CanvasList) {
    check(list.isPrivate, "private.json is private")
    check(CanvasStore.wantedPictures(list).isEmpty, "a private list wants no pictures")
    let now = list.madeAt
    let entry = CanvasTimelineEntry(date: now, snap: CanvasSnapshot(list: list, signedIn: true), canvasId: nil)
    eq(entry.canvas?.name, "Daily verse", "a private list still names its canvas")
    check(entry.current == nil, "a private list draws no entry")
    eq(CanvasPlan.dates(list, id: nil, now: now, calendar: utc), [now], "private: now only (Trip's until is past the horizon)")
  }

  // MARK: The timeline

  static func plan(_ list: CanvasList) {
    let now = list.madeAt
    let verse = list.items[0], trip = list.items[1], today = list.items[3]
    eq(CanvasPlan.pick(list, id: nil, at: now)?.id, verse.id, "Automatic: the most recent")
    eq(CanvasPlan.pick(list, id: trip.id, at: now)?.id, trip.id, "a picked canvas")
    eq(CanvasPlan.pick(list, id: "gone", at: now)?.id, verse.id, "a picked canvas that's gone: Automatic")
    eq(CanvasPlan.pick(list, id: trip.id, at: date("2027-04-03T00:00:00Z"))?.id, verse.id, "past its until: Automatic")
    var paused = list
    paused.items[0].status = "paused"
    eq(CanvasPlan.pick(paused, id: nil, at: now)?.id, trip.id, "a paused canvas isn't drawn")
    eq(CanvasPlan.pick(paused, id: verse.id, at: now)?.id, trip.id, "a picked paused canvas isn't drawn")
    check(CanvasPlan.pick(nil, id: nil, at: now) == nil, "no list, no canvas")

    eq(CanvasPlan.entryIndex(verse, at: now), 0, "the verse now")
    eq(CanvasPlan.entryIndex(verse, at: date("2027-03-10T22:00:00Z")), 1, "the verse at its time")
    eq(CanvasPlan.entryIndex(verse, at: date("2027-03-12T23:00:00Z")), 3, "the verse later")
    eq(CanvasPlan.entryIndex(verse, at: date("2028-01-01T00:00:00Z")), 13, "the last one stays")
    eq(CanvasPlan.entryIndex(today, at: date("2027-03-10T16:00:00Z")), 1, "Today turns into Tomorrow")

    // A picked rotation: one moment per dated entry, nothing else.
    let verseMoments = CanvasPlan.moments(list, id: verse.id, after: now, calendar: utc)
    eq(verseMoments, verse.entries.compactMap(\.at), "a picked rotation's moments")
    // Automatic: every live canvas's moments, Trip's midnights and its until included.
    let all = CanvasPlan.moments(list, id: nil, after: now, calendar: utc)
    check(all == all.sorted() && Set(all).count == all.count, "moments sorted, once each")
    check(all.allSatisfy { $0 > now && $0 <= now.addingTimeInterval(CanvasPlan.horizon) }, "moments within the horizon")
    check(all.contains(date("2027-03-11T00:00:00Z")), "Trip's first midnight")
    check(all.contains(date("2027-03-10T16:00:00Z")), "Today's next entry")
    check(all.count <= CanvasPlan.maxMoments, "at most \(CanvasPlan.maxMoments) moments")
    // Trip picked: its midnights within the horizon, then its timer and end fall later.
    let tripMoments = CanvasPlan.moments(list, id: trip.id, after: now, calendar: utc)
    check(tripMoments.contains(date("2027-03-12T00:00:00Z")), "a countdown's midnights")
    // Trip clears by itself, so what would show after it (the verse) is followed too.
    check(tripMoments.contains(verse.entries[1].at!), "a picked canvas that clears follows the rest")
    // Streak stays: nothing else matters, and a number has no moments.
    eq(CanvasPlan.moments(list, id: list.items[2].id, after: now, calendar: utc), [], "a picked canvas that stays")

    let timeline = CanvasPlan.timeline(CanvasSnapshot(list: list, signedIn: true), id: nil, now: now, canFetch: true)
    eq(timeline.entries.map(\.date), CanvasPlan.dates(list, id: nil, now: now), "a timeline entry for now and each moment")
    eq(timeline.entries.first?.date, now, "the first entry is now")
    eq(CanvasPlan.reload(after: now, canFetch: true), now.addingTimeInterval(1800), "rebuilt in half an hour with a key")
    eq(CanvasPlan.reload(after: now, canFetch: false), now.addingTimeInterval(6 * 3600), "rebuilt in hours without one")
    let at22 = CanvasTimelineEntry(date: date("2027-03-10T22:00:00Z"), snap: CanvasSnapshot(list: list, signedIn: true), canvasId: nil)
    eq(at22.current?.footer, "1 Thess 5:16-18", "the entry showing at a moment")
  }

  static func countdowns() {
    let target = date("2027-04-01T01:00:00Z")
    eq(CountdownShow.at(date("2027-03-10T09:00:00Z"), target: target, count: "down", calendar: utc), .days(22, since: false), "days to go")
    eq(CountdownShow.at(date("2027-03-31T00:30:00Z"), target: target, count: "down", calendar: utc), .days(1, since: false), "a day and a bit")
    let late = date("2027-03-31T02:00:00Z")
    eq(CountdownShow.at(late, target: target, count: "down", calendar: utc), .timer(from: late, to: target, down: true), "under a day: a timer")
    eq(CountdownShow.at(date("2027-04-01T02:00:00Z"), target: target, count: "down", calendar: utc), .now, "past: now")
    eq(CountdownShow.at(date("2027-04-01T02:00:00Z"), target: target, count: nil, calendar: utc), .now, "no count means down")
    eq(CountdownShow.at(date("2027-04-01T03:00:00Z"), target: target, count: "up", calendar: utc),
       .timer(from: target, to: target.addingTimeInterval(86_400), down: false), "counting up, under a day")
    eq(CountdownShow.at(date("2027-04-04T12:00:00Z"), target: target, count: "up", calendar: utc), .days(3, since: true), "days since")
    eq(CountdownShow.at(date("2027-03-30T12:00:00Z"), target: target, count: "up", calendar: utc), .days(2, since: false), "counting up, before")
  }

  static func icons() {
    eq(CanvasIcon("📖"), .emoji("📖"), "an emoji")
    eq(CanvasIcon("✈️"), .emoji("✈️"), "an emoji with a variation selector")
    eq(CanvasIcon("checklist"), .name("checklist"), "an icon name")
    eq(CanvasIcon(" Fire "), .name("fire"), "names are trimmed and lower-cased")
    check(CanvasIcon(nil) == nil && CanvasIcon("") == nil, "no icon")
    eq(CanvasIcon.symbols["checklist"], "checklist", "a known name's symbol")
    eq(CanvasEntry.format(12), "12", "a whole number")
    eq(CanvasEntry.format(-3), "-3", "a negative number")
    check(CanvasEntry.format(12.5).contains("12") && CanvasEntry.format(12.5).contains("5"), "a fraction")
    eq(CanvasStore.safeHash("painting-night_sky"), "painting-night_sky", "a painting's hash")
    check(CanvasStore.safeHash("../x") == nil && CanvasStore.safeHash("a/b") == nil && CanvasStore.safeHash("") == nil, "unsafe hashes")
  }

  static func sizes() {
    eq(CanvasFetch.size(of: .systemSmall), "home_small", "small")
    eq(CanvasFetch.size(of: .systemMedium), "home_medium", "medium")
    eq(CanvasFetch.size(of: .systemLarge), "home_large", "large")
    eq(CanvasFetch.size(of: .systemExtraLarge), "home_xl", "extra large")
    eq(CanvasFetch.pixels(for: ["home_small", "lock_rect"]), 516, "pixels for a small widget")
    eq(CanvasFetch.pixels(for: ["home_xl"]), 1200, "pixels never past the server's 1200")
    eq(CanvasFetch.pixels(for: []), 1200, "no sizes known: a generous default")
    eq(CanvasFetch.pixels(for: ["lock_circle"]), 300, "at least 300")
  }

  static func words() {
    let w = GlanceWords()
    eq(w.canvasDays(1), "1 day", "one day")
    eq(w.canvasDays(12), "12 days", "days")
    eq(w.canvas("canvas_in", ["time": "12 days"]), "in 12 days", "in")
    eq(w.canvas("canvas_empty"), "Ask a bot to put something here", "the empty state")
    eq(GlanceWords(map: ["canvas_now": "Ahora"]).canvas("canvas_now"), "Ahora", "the app's words win")
  }

  // MARK: The store

  static func store(_ dir: URL) {
    let suite = "ai.casama.canvas-tests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suite) else { return check(false, "a test suite") }
    let container = FileManager.default.temporaryDirectory.appendingPathComponent(suite, isDirectory: true)
    try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
    defer {
      defaults.removePersistentDomain(forName: suite)
      try? FileManager.default.removeItem(at: container)
    }
    check(CanvasStore.load(defaults: defaults, container: container) == nil, "nothing stored")
    guard let raw = try? String(contentsOf: dir.appendingPathComponent("canvases.json"), encoding: .utf8) else { return }
    CanvasStore.save(raw, defaults: defaults)
    eq(CanvasStore.load(defaults: defaults, container: container)?.version, "0bkP5NOEWoHcxjYEuGaTR6", "the key")
    // The Mac app's file, newer: it wins.
    let newer = raw.replacingOccurrences(of: "\"made_at\": \"2027-03-10T09:00:00.000Z\"", with: "\"made_at\": \"2027-03-10T10:00:00.000Z\"")
      .replacingOccurrences(of: "0bkP5NOEWoHcxjYEuGaTR6", with: "newer")
    try? newer.write(to: container.appendingPathComponent(CanvasStore.fileName), atomically: true, encoding: .utf8)
    eq(CanvasStore.load(defaults: defaults, container: container)?.version, "newer", "the newest wins")
    defaults.removeObject(forKey: CanvasStore.key)
    eq(CanvasStore.load(defaults: defaults, container: container)?.version, "newer", "the file alone")
    eq(CanvasStore.pictureFile("abc", container: container)?.lastPathComponent, "abc.jpg", "a picture's file")
    check(CanvasStore.pictureFile("../abc", container: container) == nil, "no file for an unsafe hash")
  }

  static func shrinking() {
    let w = 1000, h = 500
    guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
      return check(false, "a test picture")
    }
    ctx.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    let png = NSMutableData()
    guard let image = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithData(png as CFMutableData, "public.png" as CFString, 1, nil) else {
      return check(false, "a test picture")
    }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    guard let jpeg = CanvasFetch.shrink(png as Data, pixels: 200),
          let src = CGImageSourceCreateWithData(jpeg as CFData, nil),
          let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] else {
      return check(false, "shrink a picture")
    }
    eq(CGImageSourceGetType(src) as String?, "public.jpeg", "shrunk to JPEG")
    eq(props[kCGImagePropertyPixelWidth] as? Int, 200, "the long side")
    eq(props[kCGImagePropertyPixelHeight] as? Int, 100, "in proportion")
    check(CanvasFetch.shrink(Data("not a picture".utf8), pixels: 200) == nil, "not a picture")
  }
}
