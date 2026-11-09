import ActivityKit
import SwiftUI
import WidgetKit

/// Data the app shares with its widgets through the App Group (written by home_widget and
/// live_activities on the Dart side).
private let groupId = "group.dev.kasama.app"
private let shared = UserDefaults(suiteName: groupId)

// MARK: - Home-screen widget: bot status and a quick-ask button

struct BotStatusEntry: TimelineEntry {
  let date: Date
  let bot: String
  let status: String
  let cost: String
}

struct BotStatusProvider: TimelineProvider {
  func placeholder(in context: Context) -> BotStatusEntry {
    BotStatusEntry(date: Date(), bot: "Assistant", status: "Idle", cost: "$0.00 today")
  }

  func getSnapshot(in context: Context, completion: @escaping (BotStatusEntry) -> Void) {
    completion(entry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<BotStatusEntry>) -> Void) {
    completion(Timeline(entries: [entry()], policy: .after(Date().addingTimeInterval(15 * 60))))
  }

  private func entry() -> BotStatusEntry {
    BotStatusEntry(
      date: Date(),
      bot: shared?.string(forKey: "bot_name") ?? "Kasama",
      status: shared?.string(forKey: "bot_status") ?? "Open the app to sign in",
      cost: shared?.string(forKey: "bot_cost") ?? ""
    )
  }
}

struct BotStatusView: View {
  let entry: BotStatusEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(entry.bot).font(.headline)
      Text(entry.status).font(.subheadline).foregroundStyle(.secondary)
      if !entry.cost.isEmpty { Text(entry.cost).font(.caption).foregroundStyle(.secondary) }
      Spacer()
      Link(destination: URL(string: "kasama://app/quick-ask")!) {
        Label("Ask", systemImage: "bubble.left").font(.caption.bold())
      }
    }
    .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct BotStatusWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "BotStatusWidget", provider: BotStatusProvider()) { entry in
      BotStatusView(entry: entry)
    }
    .configurationDisplayName("Bot status")
    .description("Your bot's status and a quick-ask button.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - Live Activity: a running bot on the lock screen and Dynamic Island

/// Named exactly as live_activities expects.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState
  public struct ContentState: Codable, Hashable {}
  var id = UUID()
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String { "\(id)_\(key)" }
}

struct RunActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      let bot = shared?.string(forKey: context.attributes.prefixedKey("bot")) ?? "Bot"
      let step = shared?.string(forKey: context.attributes.prefixedKey("step")) ?? "Working…"
      HStack {
        Image(systemName: "sparkles")
        VStack(alignment: .leading) {
          Text(bot).font(.headline)
          Text(step).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
        }
        Spacer()
      }
      .padding()
    } dynamicIsland: { context in
      let bot = shared?.string(forKey: context.attributes.prefixedKey("bot")) ?? "Bot"
      let step = shared?.string(forKey: context.attributes.prefixedKey("step")) ?? "Working…"
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) { Text(bot).font(.headline) }
        DynamicIslandExpandedRegion(.bottom) { Text(step).lineLimit(2) }
      } compactLeading: {
        Image(systemName: "sparkles")
      } compactTrailing: {
        Text(String(step.prefix(12)))
      } minimal: {
        Image(systemName: "sparkles")
      }
    }
  }
}

@main
struct KasamaWidgets: WidgetBundle {
  var body: some Widget {
    BotStatusWidget()
    RunActivityWidget()
  }
}
