import ActivityKit
import Foundation

// MARK: - A followed run as a Live Activity (D-324, docs/ISLAND-AND-MENU-BAR-PLAN.md §6 D, §8.5)
//
// Compiled into both the app (which starts, updates and ends activities from the island feed)
// and the widget extension (which draws them). The server's pushes (Phase 4) replace the
// content state alone, encoded with default JSON rules: snake_case keys, times in plain seconds.

/// What never changes while the run lasts.
struct RunActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// working, needsOk, takeOver, finished or problem (island_feed.dart, IslandPhase).
    var phase: String
    /// What the bot is doing, in everyday words ("Searching the web").
    var step: String
    /// What it's about: a site, a file, a search.
    var detail: String?
    /// Steps taken so far.
    var steps: Int
    var approvalId: String?
    var risk: String?
    /// When this state was made (seconds since 1970).
    var updatedAt: Double
    /// When the run ended, for Finished and Stopped with a problem.
    var endedAt: Double?

    enum CodingKeys: String, CodingKey {
      case phase, step, detail, steps, risk
      case approvalId = "approval_id"
      case updatedAt = "updated_at"
      case endedAt = "ended_at"
    }

    var needsPerson: Bool { phase == "needsOk" || phase == "takeOver" }
    var ended: Bool { phase == "finished" || phase == "problem" }
  }

  var runId: String
  var botId: String
  var botName: String
  /// The bot's icon as it stores it (`mascot:<name>`); nil draws its initials. Activities started
  /// by an older app or server have none.
  var botAvatar: String? = nil
  /// When the run started (seconds since 1970); timers count from here by themselves.
  var startedAt: Double
  /// Where tapping the activity goes: the run's chat.
  var link: String
  /// The words the widget shows, from app_en.arb (the widget holds no text of its own).
  var labels: [String: String]

  enum CodingKeys: String, CodingKey {
    case runId = "run_id"
    case botId = "bot_id"
    case botName = "bot_name"
    case botAvatar = "bot_avatar"
    case startedAt = "started_at"
    case link, labels
  }

  func label(_ key: String) -> String { labels[key] ?? "" }
  var started: Date { Date(timeIntervalSince1970: startedAt) }
}

/// The deep links the activity's buttons open (casama://app/…; the router has each path).
enum RunActivityLink {
  static func url(_ path: String) -> URL {
    URL(string: "casama://app" + path) ?? URL(string: "casama://app/")!
  }

  static func stop(_ runId: String) -> URL { url("/runs/\(runId)/stop") }
  static func review(_ approvalId: String) -> URL { url("/approvals/\(approvalId)") }
}
