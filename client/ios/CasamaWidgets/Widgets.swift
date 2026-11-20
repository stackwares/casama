import SwiftUI
import WidgetKit

// MARK: - The iPhone and iPad widgets (D-405 §6.1, §6.2)
//
// Each answers one question. The views are in WidgetViews/ (shared with the Mac); what a widget
// shows comes from the glance (Glance.swift, GlanceTimeline.swift). The gallery's descriptions
// start with a verb, as Apple asks.

/// Every Home Screen widget can lose its background in StandBy and on tinted or clear Home
/// Screens; the views draw nothing that needs it.
private extension WidgetConfiguration {
  func glanceDefaults() -> some WidgetConfiguration {
    containerBackgroundRemovable(true)
  }
}

struct NeedsYouWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "NeedsYouWidget", provider: GlanceProvider()) { entry in
      NeedsYouFamilyView(entry: entry)
    }
    .configurationDisplayName("Needs you")
    .description("See which bots are waiting on you, and answer the simple ones.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    .glanceDefaults()
  }
}

struct NeedsYouFamilyView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  var body: some View {
    switch family {
    case .accessoryCircular, .accessoryRectangular: NeedsYouAccessory(entry: entry)
    default: NeedsYouView(entry: entry)
    }
  }
}

/// Took over from Bot status under the same kind, so widgets people placed become this one.
struct BotWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: "BotStatusWidget", intent: ChooseBotIntent.self, provider: BotProvider()) { entry in
      BotFamilyView(entry: entry)
    }
    .configurationDisplayName("Bot")
    .description("Keep an eye on what one of your bots is doing.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    .glanceDefaults()
  }
}

struct BotFamilyView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  var body: some View {
    switch family {
    case .accessoryCircular, .accessoryRectangular: BotAccessory(entry: entry)
    default: BotView(entry: entry)
    }
  }
}

struct AskWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: "AskWidget", intent: ChooseBotIntent.self, provider: BotProvider()) { entry in
      AskView(entry: entry)
    }
    .configurationDisplayName("Ask")
    .description("Ask a bot or start a call with one tap, with ideas to try.")
    .supportedFamilies([.systemSmall, .systemMedium])
    .glanceDefaults()
  }
}

struct RoutinesWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: "RoutinesWidget", intent: ChooseRoutinesIntent.self, provider: RoutinesProvider()) { entry in
      RoutinesFamilyView(entry: entry)
    }
    .configurationDisplayName("Routines")
    .description("See what runs next, and run a routine now.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    .glanceDefaults()
  }
}

struct RoutinesFamilyView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  var body: some View {
    switch family {
    case .accessoryRectangular: RoutinesAccessory(entry: entry)
    default: RoutinesView(entry: entry)
    }
  }
}

struct TodayWidget: Widget {
  /// Extra large portrait arrives with iOS 27.
  private var families: [WidgetFamily] {
    var f: [WidgetFamily] = [.systemLarge, .systemExtraLarge]
    if #available(iOS 27.0, *) { f.append(.systemExtraLargePortrait) }
    return f
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "TodayWidget", provider: GlanceProvider(covers: true)) { entry in
      TodayView(entry: entry)
    }
    .configurationDisplayName("Today")
    .description("Get your day in one place: what needs you, what runs next, and your credits.")
    .supportedFamilies(families)
    .glanceDefaults()
  }
}

// Brief and Tasks come in no small size, the only one CarPlay shows, so they never reach CarPlay
// (§10) without a disfavoredLocations line.
struct BriefWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "BriefWidget", provider: GlanceProvider()) { entry in
      BriefView(entry: entry)
    }
    .configurationDisplayName("Brief")
    .description("Read what your bot told you this morning.")
    .supportedFamilies([.systemMedium, .systemLarge])
    .glanceDefaults()
  }
}

struct LibraryWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "LibraryWidget", provider: GlanceProvider(covers: true)) { entry in
      LibraryView(entry: entry)
    }
    .configurationDisplayName("Library")
    .description("Open what your bots made lately.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    // A cover is the whole small widget: keep it in StandBy and on tinted Home Screens.
    .containerBackgroundRemovable(false)
  }
}

struct TasksWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "TasksWidget", provider: GlanceProvider()) { entry in
      TasksView(entry: entry)
    }
    .configurationDisplayName("Tasks")
    .description("See where the board stands, with what waits on you first.")
    .supportedFamilies([.systemMedium, .systemLarge])
    .glanceDefaults()
  }
}

struct CreditsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "CreditsWidget", provider: GlanceProvider()) { entry in
      CreditsFamilyView(entry: entry)
    }
    .configurationDisplayName("Credits")
    .description("Check how much of your credits you've used.")
    .supportedFamilies([.systemSmall, .accessoryCircular])
    .glanceDefaults()
  }
}

struct CreditsFamilyView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  var body: some View {
    switch family {
    case .accessoryCircular: CreditsAccessory(entry: entry)
    default: CreditsView(entry: entry)
    }
  }
}

/// The line above the clock.
struct CasamaInlineWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "CasamaInlineWidget", provider: GlanceProvider()) { entry in
      CasamaInlineView(entry: entry)
    }
    .configurationDisplayName("Casama")
    .description("See the one thing that matters most, above the clock.")
    .supportedFamilies([.accessoryInline])
  }
}

/// What a bot put here (docs/BOT-WIDGET-PLAN.md §10.1): Automatic or one canvas, on the Home
/// Screen and the Lock Screen. Views in WidgetViews/CanvasViews.swift.
struct CanvasWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: CanvasFetch.kind, intent: ChooseCanvasIntent.self, provider: CanvasProvider()) { entry in
      CanvasWidgetView(entry: entry)
    }
    .configurationDisplayName("Canvas")
    .description("Show what your bots put here: a verse, a countdown, a streak, a list or a picture.")
    .supportedFamilies([
      .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
      .accessoryRectangular, .accessoryInline, .accessoryCircular,
    ])
    .glanceDefaults()
  }
}

/// The Canvas widget kept out of CarPlay (its small size would reach it; §10.1) and refreshed by
/// server pushes, on the systems that have both (iOS 26).
@available(iOS 26.0, *)
struct CanvasWidgetPushed: Widget {
  var body: some WidgetConfiguration {
    CanvasWidget().body
      .disfavoredLocations([.carPlay], for: [.systemSmall])
      .pushHandler(GlancePushHandler.self)
  }
}

enum CanvasBundle {
  /// The Canvas widget under one kind on every system, as GlanceBundle.refreshable does for the
  /// others; CarPlay only exists where pushes do.
  static func widget() -> some Widget {
    WidgetBundleBuilder.buildOptional(pick())
  }

  private static func pick() -> any Widget & _LimitedAvailabilityWidgetMarker {
    if #available(iOS 26.0, *) {
      return WidgetBundleBuilder.buildLimitedAvailability(CanvasWidgetPushed())
    }
    return WidgetBundleBuilder.buildLimitedAvailability(CanvasWidget())
  }
}
