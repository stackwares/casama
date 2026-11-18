import SwiftUI
import WidgetKit

// MARK: - The Mac's own widgets (D-405 §6.5, Phase 5)
//
// The iPhone's views (client/ios/CasamaWidgets/WidgetViews, built into this target too), on the
// desktop and in Notification Center. View only: a Mac widget can't run its buttons inside the
// app, so every click opens Casama at the right place (ActButton), and Allow, Deny and Stop stay
// with the notch and the menu bar panel. The glance comes from the Team-ID-named app group that
// MacBridge writes (MainFlutterWindow.swift).

@main
struct CasamaWidgetsMac: WidgetBundle {
  var body: some Widget {
    GlanceBundle.refreshable(MacNeedsYouWidget.self)
    GlanceBundle.refreshable(MacBotWidget.self)
    GlanceBundle.refreshable(MacRoutinesWidget.self)
    GlanceBundle.refreshable(MacTodayWidget.self)
    GlanceBundle.refreshable(MacBriefWidget.self)
    GlanceBundle.refreshable(MacLibraryWidget.self)
    GlanceBundle.refreshable(MacTasksWidget.self)
    GlanceBundle.refreshable(MacCreditsWidget.self)
  }
}

struct MacNeedsYouWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "NeedsYouWidget", provider: GlanceProvider()) { entry in
      NeedsYouView(entry: entry)
    }
    .configurationDisplayName("Needs you")
    .description("See which bots are waiting on you.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct MacBotWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: "BotStatusWidget", intent: ChooseBotIntent.self, provider: BotProvider()) { entry in
      BotView(entry: entry)
    }
    .configurationDisplayName("Bot")
    .description("Keep an eye on what one of your bots is doing.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct MacRoutinesWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: "RoutinesWidget", intent: ChooseRoutinesIntent.self, provider: RoutinesProvider()) { entry in
      RoutinesView(entry: entry)
    }
    .configurationDisplayName("Routines")
    .description("See what runs next.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct MacTodayWidget: Widget {
  /// Extra large portrait arrives with macOS 27.
  private var families: [WidgetFamily] {
    var f: [WidgetFamily] = [.systemLarge, .systemExtraLarge]
    if #available(macOS 27.0, *) { f.append(.systemExtraLargePortrait) }
    return f
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "TodayWidget", provider: GlanceProvider(covers: true)) { entry in
      TodayView(entry: entry)
    }
    .configurationDisplayName("Today")
    .description("Get your day in one place: what needs you, what runs next, and your credits.")
    .supportedFamilies(families)
  }
}

struct MacBriefWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "BriefWidget", provider: GlanceProvider()) { entry in
      BriefView(entry: entry)
    }
    .configurationDisplayName("Brief")
    .description("Read what your bot told you this morning.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct MacLibraryWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "LibraryWidget", provider: GlanceProvider(covers: true)) { entry in
      LibraryView(entry: entry)
    }
    .configurationDisplayName("Library")
    .description("Open what your bots made lately.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

struct MacTasksWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "TasksWidget", provider: GlanceProvider()) { entry in
      TasksView(entry: entry)
    }
    .configurationDisplayName("Tasks")
    .description("See where the board stands, with what waits on you first.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct MacCreditsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "CreditsWidget", provider: GlanceProvider()) { entry in
      CreditsView(entry: entry)
    }
    .configurationDisplayName("Credits")
    .description("Check how much of your credits you've used.")
    .supportedFamilies([.systemSmall])
  }
}
