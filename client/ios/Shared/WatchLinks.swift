import Foundation

// MARK: - Where a tap lands (D-410)
//
// Notifications, complications, controls, Siri and the iPhone's Live Activity all hand the watch
// an app route ("/approvals/<id>", "/bots/<id>/chat?c=…") or a watch link
// (casama://app/watch/ask?bot=…). This turns either into the screen to open. Routes the watch has
// no screen for fall back to Now, never to an error.

enum WatchLink: Equatable, Hashable {
  case now
  case needs
  case approval(String)
  case suggestion(String)
  case run(String)
  case chat(bot: String, conversation: String?)
  case ask(bot: String?)
  case bots
  case upNext
  case brief
  case talk(bot: String?)
  case settings

  static let scheme = "casama"

  /// casama://app/<route>, as the iPhone's links are, so the Live Activity's taps work too.
  static func parse(_ url: URL) -> WatchLink {
    guard url.scheme?.lowercased() == scheme else { return .now }
    var route = url.path
    if let host = url.host, host != "app" { route = "/" + host + route }
    if let q = url.query, !q.isEmpty { route += "?" + q }
    return parse(route: route)
  }

  static func parse(route raw: String) -> WatchLink {
    var trimmed = raw.trimmingCharacters(in: .whitespaces)
    if trimmed.hasPrefix("/open/") { trimmed = String(trimmed.dropFirst("/open".count)) }  // casama.ai/open links (D-326)
    guard let comps = URLComponents(string: trimmed.hasPrefix("/") ? trimmed : "/" + trimmed) else { return .now }
    let parts = comps.path.split(separator: "/").map(String.init)
    let query = Dictionary((comps.queryItems ?? []).map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { a, _ in a })
    func q(_ name: String) -> String? { query[name].flatMap { $0.isEmpty ? nil : $0 } }

    switch parts.first {
    case "watch":
      switch parts.dropFirst().first {
      case "needs": return .needs
      case "ask": return .ask(bot: q("bot"))
      case "bots": return .bots
      case "next": return .upNext
      case "brief": return .brief
      case "talk": return .talk(bot: q("bot"))
      case "settings": return .settings
      case "run": return parts.count > 2 ? .run(parts[2]) : .now
      case "approval": return parts.count > 2 ? .approval(parts[2]) : .needs
      case "suggestion": return parts.count > 2 ? .suggestion(parts[2]) : .needs
      case "chat": return parts.count > 2 ? .chat(bot: parts[2], conversation: q("c")) : .bots
      default: return .now
      }
    case "approvals":
      return parts.count > 1 ? .approval(parts[1]) : .needs
    case "suggestions":
      return parts.count > 1 ? .suggestion(parts[1]) : .needs
    case "runs":
      return parts.count > 1 ? .run(parts[1]) : .now
    case "inbox", "for-you":
      return .needs
    case "quick-ask":
      return .ask(bot: q("bot"))
    case "bots":
      guard parts.count > 1 else { return .bots }
      let bot = parts[1]
      switch parts.dropFirst(2).first {
      case "routines": return .upNext
      case "call": return .talk(bot: bot)
      default: return .chat(bot: bot, conversation: q("c"))
      }
    case "routines":
      return .upNext
    default:
      return .now
    }
  }

  /// The watch's own link for this screen.
  var route: String {
    switch self {
    case .now: return "/watch/now"
    case .needs: return "/watch/needs"
    case .approval(let id): return "/watch/approval/\(id)"
    case .suggestion(let id): return "/watch/suggestion/\(id)"
    case .run(let id): return "/watch/run/\(id)"
    case .chat(let bot, let c): return "/watch/chat/\(bot)" + (c.map { "?c=\($0)" } ?? "")
    case .ask(let bot): return "/watch/ask" + (bot.map { "?bot=\($0)" } ?? "")
    case .bots: return "/watch/bots"
    case .upNext: return "/watch/next"
    case .brief: return "/watch/brief"
    case .talk(let bot): return "/watch/talk" + (bot.map { "?bot=\($0)" } ?? "")
    case .settings: return "/watch/settings"
    }
  }

  var url: URL? { URL(string: "\(WatchLink.scheme)://app\(route)") }
}

/// The phone app's route for a call with a bot (the Talk control, until Phase 6).
enum PhoneRoutes {
  static func call(bot: String) -> String { "/bots/\(bot)/call" }
  static func chat(bot: String, conversation: String?) -> String {
    "/bots/\(bot)/chat" + (conversation.map { "?c=\($0)" } ?? "")
  }
  static func approval(_ id: String) -> String { "/approvals/\(id)" }
}
