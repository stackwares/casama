import AppIntents
import SwiftUI
import WidgetKit

// MARK: - What every complication draws from (§6.3)
//
// The saved glance (GlanceCache, in the app group the watch app writes), refreshed here when it is
// older than a few minutes so a complication stays right even when the app hasn't opened. The
// extension never shows a spinner: a placeholder with the shape of the thing, or the saved copy
// with "as of".

struct GlanceEntry: TimelineEntry {
  let date: Date
  let glance: Glance?
  let savedAt: Date?
  let signedIn: Bool
  /// The bot a configured complication shows (Ask, Bot).
  var botId: String? = nil
  var relevance: TimelineEntryRelevance? = nil

  var bot: Glance.Bot? {
    guard let glance else { return nil }
    if let botId, let b = glance.bot(botId) { return b }
    return glance.bots.first
  }

  /// Older than half an hour: draw it as dated.
  var isStale: Bool {
    guard let savedAt else { return true }
    return date.timeIntervalSince(savedAt) > 30 * 60
  }

  static let placeholder = GlanceEntry(date: Date(), glance: nil, savedAt: nil, signedIn: true)
}

enum GlanceLoader {
  /// Ask the server again when the saved copy is older than this.
  static let freshFor: TimeInterval = 5 * 60
  /// How long until WidgetKit asks for a new timeline.
  static let nextReload: TimeInterval = 15 * 60

  static var signedIn: Bool { WatchAccount.accepted && WatchKeyStore.read() != nil }

  static func saved(at date: Date = Date(), botId: String? = nil) -> GlanceEntry {
    guard signedIn else { return GlanceEntry(date: date, glance: nil, savedAt: nil, signedIn: false) }
    let s = GlanceCache.glance()
    var entry = GlanceEntry(date: date, glance: s?.glance, savedAt: s?.savedAt, signedIn: true, botId: botId)
    entry.relevance = score(entry)
    return entry
  }

  /// The saved copy, refreshed first when it is old.
  static func load(botId: String? = nil) async -> GlanceEntry {
    if signedIn {
      let savedAt = GlanceCache.glance()?.savedAt ?? .distantPast
      if Date().timeIntervalSince(savedAt) > freshFor {
        await WatchSync.refreshGlance()
      }
    }
    return saved(botId: botId)
  }

  /// Entries for the next stretch: now, and the minute the next routine is due (so Up next turns
  /// over without waiting for the next reload).
  static func timeline(botId: String? = nil) async -> Timeline<GlanceEntry> {
    let now = await load(botId: botId)
    var entries = [now]
    if let at = now.glance?.nextRoutine?.nextAt, at > now.date, at.timeIntervalSince(now.date) < nextReload {
      entries.append(saved(at: at.addingTimeInterval(1), botId: botId))
    }
    return Timeline(entries: entries, policy: .after(Date().addingTimeInterval(nextReload)))
  }

  /// How much the Smart Stack should want this now (§6.3): needs you most, then a live run, then
  /// a routine due within half an hour, then a fresh brief.
  static func score(_ entry: GlanceEntry) -> TimelineEntryRelevance? {
    guard let g = entry.glance else { return nil }
    if g.needsCount > 0 { return TimelineEntryRelevance(score: 100, duration: 30 * 60) }
    if !g.liveRuns.isEmpty { return TimelineEntryRelevance(score: 70, duration: 10 * 60) }
    if let at = g.nextRoutine?.nextAt, at > entry.date, at.timeIntervalSince(entry.date) <= 30 * 60 {
      return TimelineEntryRelevance(score: 50, duration: at.timeIntervalSince(entry.date) + 5 * 60)
    }
    if let at = g.brief?.at, entry.date.timeIntervalSince(at) < 3600, entry.date >= at {
      return TimelineEntryRelevance(score: 30, duration: 3600 - entry.date.timeIntervalSince(at))
    }
    return TimelineEntryRelevance(score: 0)
  }
}

/// One provider for the complications that show the whole glance. `kind` decides its Smart Stack
/// relevance: each card says when it matters.
struct GlanceProvider: TimelineProvider {
  enum Relevance { case none, needs, working, upNext, brief }
  var relevanceKind: Relevance = .none

  func placeholder(in context: Context) -> GlanceEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) {
    completion(context.isPreview && GlanceCache.glance() == nil ? .placeholder : GlanceLoader.saved())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
    Task { completion(await GlanceLoader.timeline()) }
  }

  func relevance() async -> WidgetRelevance<Void> {
    guard GlanceLoader.signedIn, let g = GlanceCache.glance()?.glance else { return WidgetRelevance([]) }
    let now = Date()
    var attributes: [WidgetRelevanceAttribute<Void>] = []
    switch relevanceKind {
    case .needs where g.needsCount > 0:
      attributes.append(WidgetRelevanceAttribute(context: .date(range: now...now.addingTimeInterval(2 * 3600), kind: .default)))
    case .working where !g.liveRuns.isEmpty:
      attributes.append(WidgetRelevanceAttribute(context: .date(range: now...now.addingTimeInterval(30 * 60), kind: .default)))
    case .upNext:
      if let at = g.nextRoutine?.nextAt, at > now {
        attributes.append(WidgetRelevanceAttribute(context: .date(range: at.addingTimeInterval(-30 * 60)...at.addingTimeInterval(5 * 60), kind: .scheduled)))
      }
    case .brief:
      if let at = g.brief?.at, now.timeIntervalSince(at) < 3600 {
        attributes.append(WidgetRelevanceAttribute(context: .date(range: at...at.addingTimeInterval(3600), kind: .informational)))
      }
      if let next = g.brief?.nextAt, next > now {
        attributes.append(WidgetRelevanceAttribute(context: .date(range: next...next.addingTimeInterval(3600), kind: .informational)))
      }
    default:
      break
    }
    return WidgetRelevance(attributes)
  }
}

/// The configured complications (Ask, Bot): which bot comes from ChooseWatchBotIntent.
struct BotProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> GlanceEntry { .placeholder }

  func snapshot(for configuration: ChooseWatchBotIntent, in context: Context) async -> GlanceEntry {
    GlanceLoader.saved(botId: Self.botId(configuration))
  }

  func timeline(for configuration: ChooseWatchBotIntent, in context: Context) async -> Timeline<GlanceEntry> {
    await GlanceLoader.timeline(botId: Self.botId(configuration))
  }

  /// The picked bot, or the one Ask uses when none is picked.
  static func botId(_ configuration: ChooseWatchBotIntent) -> String? {
    configuration.bot?.id ?? WatchAccount.lastAskBot ?? WatchAccount.askBot
  }

  func recommendations() -> [AppIntentRecommendation<ChooseWatchBotIntent>] {
    // Offer each known bot ready-made in the face editor.
    let bots = GlanceCache.glance()?.glance.bots ?? []
    return bots.prefix(6).map { b in
      AppIntentRecommendation(intent: ChooseWatchBotIntent(bot: WatchBotEntity(b)), description: Text(b.name))
    }
  }
}
