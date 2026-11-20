import Foundation
import WidgetKit

// MARK: - The Canvas widget's timeline (docs/BOT-WIDGET-PLAN.md §6.4, §10.1)
//
// A canvas carries what shows now and up to 13 dated entries ahead; the timeline holds one entry
// for each, so the widget switches on the minute, offline. A countdown in days gets an entry at
// each midnight and where it turns into the system's self-ticking timer. A canvas's `until` clears
// it by itself. With a widget key (iPhone, iPad) the widget asks to be rebuilt after half an hour,
// when it fetches again; on the Mac, where the app writes the list and reloads the widget, after a
// few hours. Shared by the iPhone and Mac widget extensions.

struct CanvasTimelineEntry: TimelineEntry {
  let date: Date
  let snap: CanvasSnapshot
  /// The canvas picked in the widget's setting (nil: Automatic).
  var canvasId: String?

  var words: GlanceWords { snap.words }
  var isPrivate: Bool { snap.list?.isPrivate ?? false }
  /// The canvas to draw at [date].
  var canvas: BotCanvas? { CanvasPlan.pick(snap.list, id: canvasId, at: date) }
  /// Its entry showing at [date]; nil for a private list.
  var current: CanvasEntry? {
    guard !isPrivate, let c = canvas, let i = CanvasPlan.entryIndex(c, at: date) else { return nil }
    return c.entries[i]
  }
}

/// The timeline's pure logic, checked by scripts/test-canvas-swift.sh.
enum CanvasPlan {
  /// How far ahead the timeline looks.
  static let horizon: TimeInterval = 15 * 86_400
  /// At most this many timeline entries.
  static let maxMoments = 60
  /// Midnights per countdown entry.
  static let maxMidnights = 15

  /// Whether [c] draws at [date]: shown and not past its `until`.
  static func isLive(_ c: BotCanvas, at date: Date) -> Bool {
    c.status == "shown" && (c.until.map { $0 > date } ?? true)
  }

  /// The canvas a widget shows at [date]: the one picked when it's still there, else the one set
  /// most recently (the list's first live one).
  static func pick(_ list: CanvasList?, id: String?, at date: Date) -> BotCanvas? {
    guard let list else { return nil }
    // A picked canvas that's gone (cleared, its bot stopped, past its until) shows "no canvas
    // yet" (plan §6.5), as on Android; only Automatic moves on to another canvas.
    if let id { return list.items.first { $0.id == id && isLive($0, at: date) } }
    return list.items.first { isLive($0, at: date) }
  }

  /// The entry of [c] showing at [date]: the last one whose time has come.
  static func entryIndex(_ c: BotCanvas, at date: Date) -> Int? {
    guard !c.entries.isEmpty else { return nil }
    var index = 0
    for (i, e) in c.entries.enumerated() where e.at.map({ $0 <= date }) ?? true { index = i }
    return index
  }

  /// When an entry stops showing: the next dated entry, else nil (it stays).
  private static func end(of i: Int, in c: BotCanvas) -> Date? {
    c.entries.dropFirst(i + 1).compactMap(\.at).first
  }

  /// Every moment after [now] where what the widget draws may change, sorted, within the horizon.
  static func moments(_ list: CanvasList?, id: String?, after now: Date, calendar: Calendar = .current) -> [Date] {
    guard let list else { return [] }
    let limit = now.addingTimeInterval(horizon)
    var out = Set<Date>()
    // A picked canvas that stays is all that shows; with Automatic, or a picked one that clears
    // by itself, any live canvas may come to show.
    let picked = id.flatMap { id in list.items.first { $0.id == id && isLive($0, at: now) } }
    let relevant = picked.flatMap { $0.until == nil ? [$0] : nil } ?? list.items.filter { $0.status == "shown" }
    for c in relevant {
      if let u = c.until { out.insert(u) }
      for (i, e) in c.entries.enumerated() {
        if let at = e.at { out.insert(at) }
        guard e.template == "countdown", let target = e.target else { continue }
        // Where the countdown turns into a timer, ends, and (counting up) turns back into days.
        out.insert(target.addingTimeInterval(-CountdownShow.day))
        out.insert(target)
        if e.count == "up" { out.insert(target.addingTimeInterval(CountdownShow.day)) }
        let from = max(e.at ?? now, now)
        let to = min([end(of: i, in: c), c.until, limit].compactMap { $0 }.min() ?? limit, limit)
        var midnight = calendar.startOfDay(for: from)
        for _ in 0..<maxMidnights {
          guard let next = calendar.date(byAdding: .day, value: 1, to: midnight), next < to else { break }
          out.insert(next)
          midnight = next
        }
      }
    }
    return Array(out.filter { $0 > now && $0 <= limit }.sorted().prefix(maxMoments))
  }

  /// The dates of the timeline's entries: now, then each moment.
  static func dates(_ list: CanvasList?, id: String?, now: Date, calendar: Calendar = .current) -> [Date] {
    [now] + moments(list, id: id, after: now, calendar: calendar)
  }

  /// When to rebuild: half an hour with a key to fetch with, else a few hours.
  static func reload(after now: Date, canFetch: Bool) -> Date {
    now.addingTimeInterval(canFetch ? 30 * 60 : 6 * 3600)
  }

  static func timeline(_ snap: CanvasSnapshot, id: String?, now: Date, canFetch: Bool) -> Timeline<CanvasTimelineEntry> {
    let entries = dates(snap.list, id: id, now: now).map { CanvasTimelineEntry(date: $0, snap: snap, canvasId: id) }
    return Timeline(entries: entries, policy: .after(reload(after: now, canFetch: canFetch)))
  }
}

struct CanvasProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> CanvasTimelineEntry {
    CanvasTimelineEntry(date: Date(), snap: .sample)
  }

  func snapshot(for configuration: ChooseCanvasIntent, in context: Context) async -> CanvasTimelineEntry {
    let snap = CanvasSnapshot.load()
    let preview = context.isPreview && CanvasPlan.pick(snap.list, id: nil, at: Date()) == nil
    return CanvasTimelineEntry(date: Date(), snap: preview ? .sample : snap, canvasId: configuration.canvasId)
  }

  func timeline(for configuration: ChooseCanvasIntent, in context: Context) async -> Timeline<CanvasTimelineEntry> {
    let snap = await CanvasFetch.refresh()
    #if os(iOS)
    let canFetch = snap.signedIn && GlanceFetch.server() != nil && WidgetKey.read() != nil
    #else
    let canFetch = false
    #endif
    return CanvasPlan.timeline(snap, id: configuration.canvasId, now: Date(), canFetch: canFetch)
  }
}
