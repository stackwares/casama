import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Data the app shares with its widgets through the App Group (written by home_widget and
/// live_activities on the Dart side).
private let groupId = "group.ai.casama.app"
private let shared = UserDefaults(suiteName: groupId)

// MARK: - A bot's mark, as the app draws it (client/lib/ui/bot_avatar.dart)
//
// A bot that picked a mascot shows that mascot (the art is in Assets.xcassets as mascot-<name>,
// made from assets/mascots/<name>.png); any other bot shows its initials on its gradient, the
// gradient picked from its name exactly as botPalette does. Keep both lists in step with
// bot_avatar.dart and mascot.dart.

extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xff) / 255,
      green: Double((hex >> 8) & 0xff) / 255,
      blue: Double(hex & 0xff) / 255
    )
  }
}

/// The mascots (mascot.dart, `Mascot`) and their own two colours.
private let mascotColors: [String: (UInt32, UInt32)] = [
  "winky": (0x7A90FF, 0x7DE9F4),
  "sleepy": (0x7C83F2, 0xA59CF6),
  "starry": (0xFF9F43, 0xFFC94D),
  "lovey": (0xFF6FAE, 0xFF9CC9),
  "cool": (0x14B8A6, 0x4FD1C5),
  "thinker": (0xF59E0B, 0xFBBF24),
  "giggly": (0x22C55E, 0x4ADE80),
  "shy": (0xFB7185, 0xFDA4AF),
  "focused": (0x3B82F6, 0x60A5FA),
  "wow": (0x8B5CF6, 0xA78BFA),
]

/// The initials gradients (bot_avatar.dart, `_palettes`).
private let initialsPalettes: [(UInt32, UInt32)] = [
  (0x14B8A6, 0x0F766E),
  (0x6366F1, 0x4338CA),
  (0xF59E0B, 0xD97706),
  (0xEC4899, 0xBE185D),
  (0x3B82F6, 0x1D4ED8),
  (0x8B5CF6, 0x6D28D9),
  (0x10B981, 0x047857),
  (0xF97316, 0xC2410C),
]

/// Everything needed to draw one bot: its mascot or initials, and its colours.
struct BotArt {
  let name: String
  /// The mascot's key (`winky`), when the bot has one we ship.
  let mascot: String?
  let colors: [Color]

  init(name: String, avatar: String?) {
    self.name = name
    var key: String?
    if let avatar, avatar.hasPrefix("mascot:") {
      let k = String(avatar.dropFirst("mascot:".count))
      if mascotColors[k] != nil { key = k }
    }
    mascot = key
    if let key, let c = mascotColors[key] {
      colors = [Color(hex: c.0), Color(hex: c.1)]
    } else {
      // botPalette: (h * 31 + code unit) & 0x7fffffff over the lower-cased name's UTF-16.
      var h = 0
      for u in name.lowercased().utf16 { h = (h &* 31 &+ Int(u)) & 0x7fffffff }
      let p = initialsPalettes[h % initialsPalettes.count]
      colors = [Color(hex: p.0), Color(hex: p.1)]
    }
  }

  /// The colour things in the bot's colour use (a timer, a glow).
  var accent: Color { colors[0] }

  /// One or two letters, as `botInitials` makes them.
  var initials: String {
    let parts = name.split(whereSeparator: { $0.isWhitespace })
    guard let first = parts.first?.first else { return "?" }
    if parts.count == 1 { return String(first).uppercased() }
    return (String(first) + String(parts[1].first!)).uppercased()
  }
}

/// The bot's mark at [size]: its mascot (transparent, a little larger than the box, as the app
/// draws it) or its initials on a rounded square in its gradient.
struct BotMarkView: View {
  let art: BotArt
  var size: CGFloat = 24
  var body: some View {
    Group {
      if let mascot = art.mascot {
        Image("mascot-\(mascot)")
          .resizable()
          .interpolation(.high)
          .scaledToFit()
          // The art keeps a margin for the cloud's hops (mascot.dart, _zoom).
          .frame(width: size * 1.14, height: size * 1.14)
          .frame(width: size, height: size)
      } else {
        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
          .fill(LinearGradient(colors: art.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
          .overlay(
            Text(art.initials)
              .font(.system(size: size * (art.name.trimmingCharacters(in: .whitespaces).contains(" ") ? 0.36 : 0.44), weight: .heavy, design: .rounded))
              .foregroundColor(.white)
              .minimumScaleFactor(0.5)
              .lineLimit(1)
          )
          .frame(width: size, height: size)
      }
    }
    .accessibilityHidden(true)
  }
}

// MARK: - Home-screen widget: bot status and a quick-ask button

struct BotStatusEntry: TimelineEntry {
  let date: Date
  let bot: String
  let avatar: String?
  let status: String
  let cost: String
}

struct BotStatusProvider: TimelineProvider {
  func placeholder(in context: Context) -> BotStatusEntry {
    BotStatusEntry(date: Date(), bot: "Assistant", avatar: "mascot:winky", status: "Idle", cost: "$0.00 today")
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
      bot: shared?.string(forKey: "bot_name") ?? "Casama",
      avatar: shared?.string(forKey: "bot_avatar"),
      status: shared?.string(forKey: "bot_status") ?? "Open the app to sign in",
      cost: shared?.string(forKey: "bot_cost") ?? ""
    )
  }
}

struct BotStatusView: View {
  let entry: BotStatusEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      BotMarkView(art: BotArt(name: entry.bot, avatar: entry.avatar), size: 34)
        .padding(.bottom, 4)
      Text(entry.bot).font(.headline).lineLimit(1)
      Text(entry.status).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
      if !entry.cost.isEmpty { Text(entry.cost).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
      Spacer(minLength: 0)
      Link(destination: URL(string: "casama://app/quick-ask")!) {
        Label("Ask", systemImage: "bubble.left").font(.caption.bold())
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Live Activity: a followed run on the Lock Screen and in the Dynamic Island (D-324, §6 D)
//
// Drawn from RunActivityAttributes alone (RunActivityAttributes.swift), so a push from the server
// can redraw it while the app isn't running. Timers tick by themselves. The activity opens the
// run's chat and Review opens the request (deep links); Stop, Allow and Deny act without opening
// the app (RunActionIntents.swift; Allow and Deny behind Face ID, D-324 Phase 6).
//
// The look: the bot itself leads (its mascot or initials, never a stand-in), with a small badge
// for how the run stands, the way BotAvatar's status dot does in the app. The bot's own colour
// glows from behind it and tints its timer; anything that needs the person turns orange, Finished
// green, a problem yellow. On a dark glass card so it reads on any wallpaper.
//
// Apple Watch and CarPlay: iOS 18's .supplementalActivityFamilies([.small]) can't be chosen at run
// time in a widget bundle, and this extension still runs on iOS 17, so they use the compact views
// for now (docs/ISLAND-AND-MENU-BAR-PLAN.md §19).

enum RunTone {
  static let needsYou = Color(hex: 0xFF9F0A)
  static let finished = Color(hex: 0x30D158)
  static let problem = Color(hex: 0xFFD60A)
}

extension RunActivityAttributes {
  var art: BotArt { BotArt(name: botName, avatar: botAvatar) }
  var displayName: String { botName.isEmpty ? "Casama" : botName }
}

/// The colour for where the run stands: the bot's own while it works.
func runTone(_ s: RunActivityAttributes.ContentState, _ art: BotArt) -> Color {
  switch s.phase {
  case "needsOk", "takeOver": return RunTone.needsYou
  case "finished": return RunTone.finished
  case "problem": return RunTone.problem
  default: return art.accent
  }
}

/// How the run stands, as a glyph.
func runSymbol(_ s: RunActivityAttributes.ContentState) -> String {
  switch s.phase {
  case "needsOk": return "hand.raised.fill"
  case "takeOver": return "hand.point.up.left.fill"
  case "finished": return "checkmark"
  case "problem": return "exclamationmark"
  default: return "sparkles"
  }
}

/// The badge on the bot's mark: a filled circle in the run's colour with its glyph, ringed in the
/// card's colour so it sits on the mark like the app's status dot.
struct RunBadge: View {
  let state: RunActivityAttributes.ContentState
  let tone: Color
  var size: CGFloat = 18
  var body: some View {
    Image(systemName: runSymbol(state))
      .font(.system(size: size * 0.5, weight: .bold))
      .foregroundColor(.black.opacity(0.85))
      .frame(width: size, height: size)
      .background(Circle().fill(tone))
      .overlay(Circle().stroke(Color.black.opacity(0.85), lineWidth: size * 0.12))
      .accessibilityHidden(true)
  }
}

/// The bot's mark with its badge.
struct RunMark: View {
  let attributes: RunActivityAttributes
  let state: RunActivityAttributes.ContentState
  var size: CGFloat = 44
  var body: some View {
    let art = attributes.art
    BotMarkView(art: art, size: size)
      .overlay(alignment: .bottomTrailing) {
        RunBadge(state: state, tone: runTone(state, art), size: max(14, size * 0.4))
          .offset(x: size * 0.1, y: size * 0.1)
      }
  }
}

/// The running time while it runs; how long it took once it ended.
struct RunTime: View {
  let attributes: RunActivityAttributes
  let state: RunActivityAttributes.ContentState
  var body: some View {
    if let end = state.endedAt {
      Text(Duration.seconds(max(0, end - attributes.startedAt)).formatted(.time(pattern: .minuteSecond)))
        .monospacedDigit()
    } else {
      Text(timerInterval: attributes.started...Date.distantFuture, countsDown: false)
        .monospacedDigit()
    }
  }
}

/// The words for where it stands: the step while it works, Needs your OK, Finished.
func runHeadline(_ a: RunActivityAttributes, _ s: RunActivityAttributes.ContentState) -> String {
  switch s.phase {
  case "needsOk": return a.label("needs_ok")
  case "takeOver": return a.label("take_over")
  case "finished": return a.label("finished")
  case "problem": return a.label("problem")
  // A server with private notifications sends no words (D-324): the phase says enough.
  default: return s.step.isEmpty ? a.label("working") : s.step
  }
}

/// The quieter line under it: what it's about and the steps so far, or what the request is.
func runSubline(_ a: RunActivityAttributes, _ s: RunActivityAttributes.ContentState, stale: Bool) -> String? {
  // An ended run's card says how it ended; only a running one can be out of date.
  if stale { return a.label("stale").isEmpty ? nil : a.label("stale") }
  if s.needsPerson { return s.step.isEmpty ? nil : s.step }
  var parts: [String] = []
  if !s.ended, let d = s.detail, !d.isEmpty { parts.append(d) }
  if s.steps > 0 {
    let one = a.label("steps_one"), other = a.label("steps_other")
    let text = s.steps == 1 ? one : other.replacingOccurrences(of: "%d", with: "\(s.steps)")
    if !text.isEmpty { parts.append(text) }
  }
  return parts.isEmpty ? nil : parts.joined(separator: " · ")
}

struct RunButtonLabel: View {
  let title: String
  var symbol: String? = nil
  var prominent = false
  var tint: Color = .white
  var body: some View {
    HStack(spacing: 5) {
      if let symbol { Image(systemName: symbol).font(.caption2.weight(.bold)) }
      Text(title).font(.footnote.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
    }
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, minHeight: 34)
    .background(Capsule().fill(prominent ? tint : Color.white.opacity(0.14)))
    .foregroundColor(prominent ? .black : .white)
  }
}

struct RunButton: View {
  let title: String
  var symbol: String? = nil
  let url: URL
  var prominent = false
  var tint: Color = .white
  var body: some View {
    Link(destination: url) { RunButtonLabel(title: title, symbol: symbol, prominent: prominent, tint: tint) }
  }
}

/// A button that runs an intent in the app's process, without opening it.
struct RunIntentButton<I: AppIntent>: View {
  let title: String
  var symbol: String? = nil
  let intent: I
  var prominent = false
  var tint: Color = .white
  var body: some View {
    Button(intent: intent) { RunButtonLabel(title: title, symbol: symbol, prominent: prominent, tint: tint) }
      .buttonStyle(.plain)
  }
}

/// The run's buttons: Allow, Deny and Review when it needs an OK (Review alone for a high-risk
/// request), Stop while it works, Open otherwise.
struct RunButtons: View {
  let attributes: RunActivityAttributes
  let state: RunActivityAttributes.ContentState

  /// Only a request whose risk is known and isn't high. Labels from before Phase 6 have no Allow
  /// or Deny: Review alone then.
  private var answersHere: Bool {
    guard let risk = state.risk, !risk.isEmpty, risk != "high" else { return false }
    return !attributes.label("allow").isEmpty && !attributes.label("deny").isEmpty
  }

  var body: some View {
    let open = RunActivityLink.url(attributes.link)
    HStack(spacing: 8) {
      if state.phase == "needsOk", let approval = state.approvalId {
        if answersHere {
          RunIntentButton(title: attributes.label("allow"), symbol: "checkmark", intent: AnswerRequestIntent(approvalId: approval, allow: true), prominent: true, tint: RunTone.needsYou)
          RunIntentButton(title: attributes.label("deny"), symbol: "xmark", intent: AnswerRequestIntent(approvalId: approval, allow: false))
          RunButton(title: attributes.label("review"), url: RunActivityLink.review(approval))
        } else {
          RunButton(title: attributes.label("review"), symbol: "eye", url: RunActivityLink.review(approval), prominent: true, tint: RunTone.needsYou)
          RunButton(title: attributes.label("open"), url: open)
        }
      } else if state.phase == "takeOver" {
        RunButton(title: attributes.label("open"), symbol: "arrow.up.forward", url: open, prominent: true, tint: RunTone.needsYou)
      } else {
        if state.phase == "working" {
          RunIntentButton(title: attributes.label("stop"), symbol: "stop.fill", intent: StopRunIntent(runId: attributes.runId))
        }
        RunButton(title: attributes.label("open"), symbol: "arrow.up.forward", url: open, prominent: state.ended)
      }
    }
  }
}

/// The glow behind the bot: its colour (or the run's, when it needs the person) fading out.
struct RunGlow: View {
  let tone: Color
  var body: some View {
    RadialGradient(colors: [tone.opacity(0.38), tone.opacity(0.08), .clear], center: .topLeading, startRadius: 4, endRadius: 300)
      .accessibilityHidden(true)
  }
}

/// The Lock Screen, the banner and StandBy (under 160 pt).
struct RunLockScreenView: View {
  let context: ActivityViewContext<RunActivityAttributes>
  var body: some View {
    let a = context.attributes
    let s = context.state
    let tone = runTone(s, a.art)
    let stale = context.isStale && !s.ended
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center, spacing: 12) {
        RunMark(attributes: a, state: s, size: 46)
        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(a.displayName)
              .font(.system(.headline, design: .rounded))
              .lineLimit(1)
            Spacer(minLength: 4)
            RunTime(attributes: a, state: s)
              .font(.system(.subheadline, design: .rounded).weight(.semibold))
              .foregroundColor(s.ended ? .white.opacity(0.55) : tone)
          }
          Text(runHeadline(a, s))
            .font(.subheadline.weight(.semibold))
            .foregroundColor(s.needsPerson || s.ended ? tone : .white)
            .lineLimit(s.needsPerson ? 1 : 2)
          if let sub = runSubline(a, s, stale: stale) {
            Text(sub).font(.footnote).foregroundColor(.white.opacity(0.6)).lineLimit(1)
          }
        }
      }
      if !s.ended || s.phase == "problem" { RunButtons(attributes: a, state: s) }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RunGlow(tone: s.needsPerson ? RunTone.needsYou : a.art.accent))
    .foregroundColor(.white)
    .opacity(stale ? 0.6 : 1)
    .activityBackgroundTint(Color(hex: 0x111114).opacity(0.86))
    .activitySystemActionForegroundColor(.white)
    .widgetURL(RunActivityLink.url(a.link))
    .accessibilityElement(children: .contain)
  }
}

/// The Dynamic Island's compact right side: the timer in the bot's colour while it works; a
/// glyph once it needs the person or has ended.
struct RunCompactTrailing: View {
  let attributes: RunActivityAttributes
  let state: RunActivityAttributes.ContentState
  var body: some View {
    let tone = runTone(state, attributes.art)
    if state.phase == "working" {
      RunTime(attributes: attributes, state: state)
        .font(.system(.caption, design: .rounded).weight(.semibold))
        .foregroundColor(tone)
        .frame(maxWidth: 44)
    } else {
      Image(systemName: runSymbol(state))
        .font(.caption.weight(.bold))
        .foregroundColor(tone)
    }
  }
}

struct RunActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RunActivityAttributes.self) { context in
      RunLockScreenView(context: context)
    } dynamicIsland: { context in
      let a = context.attributes
      let s = context.state
      let tone = runTone(s, a.art)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          RunMark(attributes: a, state: s, size: 44)
            .padding(.leading, 4)
            .padding(.top, 2)
        }
        DynamicIslandExpandedRegion(.trailing) {
          RunTime(attributes: a, state: s)
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundColor(s.ended ? .white.opacity(0.55) : tone)
            .frame(maxWidth: 72, alignment: .trailing)
            .padding(.trailing, 4)
            .padding(.top, 2)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(a.displayName)
              .font(.system(.headline, design: .rounded))
              .lineLimit(1)
            Text(runHeadline(a, s))
              .font(.subheadline.weight(.medium))
              .foregroundColor(s.needsPerson || s.ended ? tone : .white.opacity(0.8))
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 10) {
            if let sub = runSubline(a, s, stale: context.isStale && !s.ended) {
              Text(sub).font(.footnote).foregroundColor(.white.opacity(0.55)).lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !s.ended || s.phase == "problem" { RunButtons(attributes: a, state: s) }
          }
          .padding(.horizontal, 4)
          .padding(.top, 4)
        }
      } compactLeading: {
        BotMarkView(art: a.art, size: 22)
      } compactTrailing: {
        RunCompactTrailing(attributes: a, state: s)
      } minimal: {
        BotMarkView(art: a.art, size: 20)
          .overlay(alignment: .bottomTrailing) {
            if s.phase != "working" {
              Circle().fill(tone).frame(width: 8, height: 8)
                .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                .offset(x: 2, y: 2)
            }
          }
      }
      .widgetURL(RunActivityLink.url(a.link))
      .keylineTint(tone)
    }
  }
}

// MARK: - The live_activities plugin's activities: a live call (D-327 §9)
//
// Calls use the live_activities plugin (call_glance.dart); runs use RunActivityAttributes above
// (D-324). An activity of this type that isn't a call comes from an app version before D-324.

/// Named exactly as live_activities expects.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState
  public struct ContentState: Codable, Hashable {}
  var id = UUID()
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String { "\(id)_\(key)" }
}

/// One value the app wrote for this activity.
private func activityValue(_ attributes: LiveActivitiesAppAttributes, _ key: String) -> String? {
  shared?.string(forKey: attributes.prefixedKey(key))
}

struct CallActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      if activityValue(context.attributes, "kind") == "call" {
        CallActivityView(call: CallActivityData(context.attributes))
      } else {
        LegacyRunActivityView(attributes: context.attributes)
      }
    } dynamicIsland: { context in
      if activityValue(context.attributes, "kind") == "call" {
        return callIsland(CallActivityData(context.attributes))
      }
      return legacyRunIsland(context.attributes)
    }
  }
}

struct LegacyRunActivityView: View {
  let attributes: LiveActivitiesAppAttributes
  var body: some View {
    let bot = activityValue(attributes, "bot") ?? "Bot"
    let step = activityValue(attributes, "step") ?? "Working…"
    HStack {
      BotMarkView(art: BotArt(name: bot, avatar: nil), size: 32)
      VStack(alignment: .leading) {
        Text(bot).font(.headline)
        Text(step).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
      }
      Spacer()
    }
    .padding()
  }
}

private func legacyRunIsland(_ attributes: LiveActivitiesAppAttributes) -> DynamicIsland {
  let bot = activityValue(attributes, "bot") ?? "Bot"
  let step = activityValue(attributes, "step") ?? "Working…"
  return DynamicIsland {
    DynamicIslandExpandedRegion(.leading) { Text(bot).font(.headline) }
    DynamicIslandExpandedRegion(.bottom) { Text(step).lineLimit(2) }
  } compactLeading: {
    BotMarkView(art: BotArt(name: bot, avatar: nil), size: 22)
  } compactTrailing: {
    Text(String(step.prefix(12)))
  } minimal: {
    BotMarkView(art: BotArt(name: bot, avatar: nil), size: 20)
  }
}

// MARK: - A live call (D-327 §9): the bot, the timer, the job, Mute and End Call

private let callGreen = Color(hex: 0x30D158)

/// What the app wrote for a call (`LiveActivityCallGlance.data` in call_glance.dart).
struct CallActivityData {
  let bot: String
  let art: BotArt
  let step: String
  let since: Date?
  let muted: Bool
  let link: URL?
  let muteLabel: String
  let unmuteLabel: String
  let endLabel: String

  init(_ attributes: LiveActivitiesAppAttributes) {
    bot = activityValue(attributes, "bot") ?? "Casama"
    art = BotArt(name: bot, avatar: activityValue(attributes, "avatar"))
    step = activityValue(attributes, "step") ?? ""
    since = Double(activityValue(attributes, "since") ?? "").map { Date(timeIntervalSince1970: $0) }
    muted = activityValue(attributes, "muted") == "1"
    link = URL(string: activityValue(attributes, "link") ?? "")
    muteLabel = activityValue(attributes, "mute") ?? "Mute"
    unmuteLabel = activityValue(attributes, "unmute") ?? "Unmute"
    endLabel = activityValue(attributes, "end") ?? "End Call"
  }
}

/// The call's timer, counting up from when it went live.
struct CallTimer: View {
  let since: Date?
  var body: some View {
    if let since {
      Text(timerInterval: since...Date.distantFuture, countsDown: false)
        .monospacedDigit()
    } else {
      Text("…")
    }
  }
}

/// The bot on a call: its mark with a green phone badge (a slashed mic while muted).
struct CallMark: View {
  let call: CallActivityData
  var size: CGFloat = 44
  var body: some View {
    let badge = max(14, size * 0.4)
    BotMarkView(art: call.art, size: size)
      .overlay(alignment: .bottomTrailing) {
        Image(systemName: call.muted ? "mic.slash.fill" : "phone.fill")
          .font(.system(size: badge * 0.5, weight: .bold))
          .foregroundColor(.black.opacity(0.85))
          .frame(width: badge, height: badge)
          .background(Circle().fill(call.muted ? RunTone.needsYou : callGreen))
          .overlay(Circle().stroke(Color.black.opacity(0.85), lineWidth: badge * 0.12))
          .offset(x: size * 0.1, y: size * 0.1)
      }
  }
}

/// Mute (or Unmute) and End Call, run without opening the app.
struct CallButtons: View {
  let call: CallActivityData
  var body: some View {
    HStack(spacing: 10) {
      Button(intent: CallActionIntent(action: call.muted ? "unmute" : "mute")) {
        Image(systemName: call.muted ? "mic.slash.fill" : "mic.fill")
          .font(.system(size: 16, weight: .semibold))
          .frame(width: 44, height: 44)
          .background(Circle().fill(call.muted ? Color.white : Color.white.opacity(0.16)))
          .foregroundColor(call.muted ? .black : .white)
          .accessibilityLabel(call.muted ? call.unmuteLabel : call.muteLabel)
      }
      .buttonStyle(.plain)
      Button(intent: CallActionIntent(action: "end")) {
        Image(systemName: "phone.down.fill")
          .font(.system(size: 16, weight: .semibold))
          .frame(width: 44, height: 44)
          .background(Circle().fill(Color(hex: 0xFF453A)))
          .foregroundColor(.white)
          .accessibilityLabel(call.endLabel)
      }
      .buttonStyle(.plain)
    }
  }
}

struct CallActivityView: View {
  let call: CallActivityData
  var body: some View {
    HStack(spacing: 12) {
      CallMark(call: call, size: 46)
      VStack(alignment: .leading, spacing: 2) {
        Text(call.bot).font(.system(.headline, design: .rounded)).lineLimit(1)
        CallTimer(since: call.since)
          .font(.system(.subheadline, design: .rounded).weight(.semibold))
          .foregroundColor(callGreen)
        if !call.step.isEmpty {
          Text(call.step).font(.footnote).foregroundColor(.white.opacity(0.6)).lineLimit(1)
        }
      }
      Spacer(minLength: 8)
      CallButtons(call: call)
    }
    .padding(16)
    .background(RunGlow(tone: call.art.accent))
    .foregroundColor(.white)
    .activityBackgroundTint(Color(hex: 0x111114).opacity(0.86))
    .activitySystemActionForegroundColor(.white)
    .widgetURL(call.link)
  }
}

private func callIsland(_ call: CallActivityData) -> DynamicIsland {
  DynamicIsland {
    DynamicIslandExpandedRegion(.leading) {
      CallMark(call: call, size: 44).padding(.leading, 4).padding(.top, 2)
    }
    DynamicIslandExpandedRegion(.trailing) {
      CallTimer(since: call.since)
        .font(.system(.headline, design: .rounded).weight(.semibold))
        .foregroundColor(callGreen)
        .frame(maxWidth: 72, alignment: .trailing)
        .padding(.trailing, 4)
        .padding(.top, 2)
    }
    DynamicIslandExpandedRegion(.center) {
      Text(call.bot)
        .font(.system(.headline, design: .rounded))
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    DynamicIslandExpandedRegion(.bottom) {
      HStack(spacing: 12) {
        Text(call.step).font(.footnote).foregroundColor(.white.opacity(0.6)).lineLimit(2)
        Spacer(minLength: 4)
        CallButtons(call: call)
      }
      .padding(.horizontal, 4)
    }
  } compactLeading: {
    BotMarkView(art: call.art, size: 22)
  } compactTrailing: {
    HStack(spacing: 3) {
      if call.muted { Image(systemName: "mic.slash.fill").foregroundColor(RunTone.needsYou) }
      CallTimer(since: call.since).foregroundColor(callGreen).frame(maxWidth: 44)
    }
    .font(.system(.caption, design: .rounded).weight(.semibold))
  } minimal: {
    BotMarkView(art: call.art, size: 20)
      .overlay(alignment: .bottomTrailing) {
        Circle().fill(callGreen).frame(width: 8, height: 8)
          .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
          .offset(x: 2, y: 2)
      }
  }
  .widgetURL(call.link)
  .keylineTint(callGreen)
}

/// A call button pressed on the lock screen or the Dynamic Island. Runs in the widget's process,
/// so it tells the app with a Darwin notification (`CallGlanceBridge` in AppDelegate.swift
/// passes it to Flutter); the app redraws the activity.
struct CallActionIntent: AppIntent {
  static var title: LocalizedStringResource = "Call action"
  static var isDiscoverable = false
  static var openAppWhenRun = false

  @Parameter(title: "Action") var action: String

  init() {}
  init(action: String) { self.action = action }

  func perform() async throws -> some IntentResult {
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName("ai.casama.app.call.\(action)" as CFString), nil, nil, true)
    return .result()
  }
}

@main
struct CasamaWidgets: WidgetBundle {
  var body: some Widget {
    BotStatusWidget()
    RunActivityWidget()
    CallActivityWidget()
  }
}
