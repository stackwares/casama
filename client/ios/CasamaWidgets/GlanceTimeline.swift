import Foundation
import WidgetKit

// MARK: - Timelines for the glance widgets (D-405 §8.3)
//
// Every widget's timeline holds an entry for now and one for each known moment ahead (a routine's
// run, the brief's hour, the points where the data turns stale), so it stays right with no
// refresh. It asks to be rebuilt after half an hour, which is when a widget with a key fetches
// again. Shared by the iPhone and Mac widget extensions.

struct GlanceEntry: TimelineEntry {
  let date: Date
  let snap: GlanceSnapshot
  /// The bot the person picked (Bot, Ask), if any.
  var bot: WidgetBotEntity?
  /// The routines the person picked (Routines), if any.
  var routines: [WidgetRoutineEntity] = []
  /// Cached cover files by creation id (Library, Today).
  var covers: [String: URL] = [:]

  var glance: Glance? { snap.glance }
  var words: GlanceWords { snap.words }
}

enum GlanceTimeline {
  static let reloadAfter: TimeInterval = 30 * 60

  /// What the gallery shows: the person's own data when there is some, else a sample.
  static func preview(_ snap: GlanceSnapshot) -> GlanceSnapshot {
    snap.glance == nil ? .sample : snap
  }

  static func timeline(_ base: GlanceEntry) -> Timeline<GlanceEntry> {
    let now = base.date
    var entries = [base]
    for moment in base.glance?.moments(after: now) ?? [] {
      entries.append(GlanceEntry(date: moment, snap: base.snap, bot: base.bot, routines: base.routines, covers: base.covers))
    }
    return Timeline(entries: entries, policy: .after(now.addingTimeInterval(reloadAfter)))
  }
}

/// Widgets with nothing to choose: Needs you, Today, Brief, Library, Tasks, Credits, Casama.
struct GlanceProvider: TimelineProvider {
  /// Fetch covers for the recent creations (Library, Today).
  var covers = false

  func placeholder(in context: Context) -> GlanceEntry {
    GlanceEntry(date: Date(), snap: .sample)
  }

  func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) {
    let snap = GlanceSnapshot.load()
    completion(GlanceEntry(date: Date(), snap: context.isPreview ? GlanceTimeline.preview(snap) : snap))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
    let covers = self.covers
    Task {
      let snap = await GlanceFetch.refresh()
      let files = covers ? await GlanceFetch.covers(for: snap.glance?.recent ?? []) : [:]
      completion(GlanceTimeline.timeline(GlanceEntry(date: Date(), snap: snap, covers: files)))
    }
  }
}

/// Bot and Ask: a bot to pick.
struct BotProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> GlanceEntry {
    GlanceEntry(date: Date(), snap: .sample)
  }

  func snapshot(for configuration: ChooseBotIntent, in context: Context) async -> GlanceEntry {
    let snap = GlanceSnapshot.load()
    return GlanceEntry(date: Date(), snap: context.isPreview ? GlanceTimeline.preview(snap) : snap, bot: configuration.bot)
  }

  func timeline(for configuration: ChooseBotIntent, in context: Context) async -> Timeline<GlanceEntry> {
    let snap = await GlanceFetch.refresh()
    return GlanceTimeline.timeline(GlanceEntry(date: Date(), snap: snap, bot: configuration.bot))
  }
}

/// Routines: automatic, or up to four picked.
struct RoutinesProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> GlanceEntry {
    GlanceEntry(date: Date(), snap: .sample)
  }

  func snapshot(for configuration: ChooseRoutinesIntent, in context: Context) async -> GlanceEntry {
    let snap = GlanceSnapshot.load()
    return GlanceEntry(date: Date(), snap: context.isPreview ? GlanceTimeline.preview(snap) : snap, routines: configuration.routines ?? [])
  }

  func timeline(for configuration: ChooseRoutinesIntent, in context: Context) async -> Timeline<GlanceEntry> {
    let snap = await GlanceFetch.refresh()
    return GlanceTimeline.timeline(GlanceEntry(date: Date(), snap: snap, routines: configuration.routines ?? []))
  }
}
