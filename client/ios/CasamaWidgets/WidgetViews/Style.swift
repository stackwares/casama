import SwiftUI
import WidgetKit

// MARK: - The widgets' look (D-405 §6.7, docs/media/widgets-mockups.html)
//
// Plain white or the app's dark grey behind (the Plain theme, D-380), the system's rounded font,
// orange only for "needs you", green only for "working", the brand purple on the one main button,
// text grey for the rest. Shared by the iPhone and Mac widget extensions.

struct Palette {
  let bg, fg, fg2, line, fill, primary, primaryBg, wait, work: Color

  static func of(_ scheme: ColorScheme) -> Palette {
    scheme == .dark
      ? Palette(bg: Color(hex: 0x1C1C1E), fg: Color(hex: 0xF2F1F4), fg2: Color(hex: 0xC9C6D0), line: Color(hex: 0x38383C),
                fill: Color(hex: 0x2A2A2D), primary: Color(hex: 0xD9B6F7), primaryBg: Color(hex: 0x3A2A47),
                wait: Color(hex: 0xF0A84A), work: Color(hex: 0x5FD49A))
      : Palette(bg: .white, fg: Color(hex: 0x1D1B20), fg2: Color(hex: 0x5F5C66), line: Color(hex: 0xE3E2E7),
                fill: Color(hex: 0xF2F2F5), primary: Color(hex: 0x7A3FA8), primaryBg: Color(hex: 0xF1E2FC),
                wait: Color(hex: 0xC47F00), work: Color(hex: 0x1FA463))
  }
}

/// casama://app<route>, which the app's router opens (core/router.dart).
func appURL(_ route: String) -> URL {
  URL(string: "casama://app" + (route.hasPrefix("/") ? route : "/" + route)) ?? URL(string: "casama://app/")!
}

/// /quick-ask for a bot, with a starter typed in (not sent).
func askRoute(bot: String?, text: String? = nil) -> String {
  var c = URLComponents()
  c.path = "/quick-ask"
  var items: [URLQueryItem] = []
  if let bot, !bot.isEmpty { items.append(URLQueryItem(name: "bot", value: bot)) }
  if let text, !text.isEmpty { items.append(URLQueryItem(name: "text", value: text)) }
  c.queryItems = items.isEmpty ? nil : items
  return c.string ?? "/quick-ask"
}

enum GlanceFormat {
  /// "7:00" today, "Fri" within the week, "18 Nov" after that.
  static func when(_ date: Date, from now: Date) -> String {
    let cal = Calendar.current
    if cal.isDate(date, inSameDayAs: now) { return date.formatted(date: .omitted, time: .shortened) }
    if date > now, date.timeIntervalSince(now) < 6 * 86400 { return date.formatted(.dateTime.weekday(.abbreviated)) }
    return date.formatted(.dateTime.day().month(.abbreviated))
  }

  static func time(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }

  static func money(_ usd: Double) -> String { usd.formatted(.currency(code: "USD")) }

  static func percent(_ share: Double) -> String { "\(Int((share * 100).rounded()))" }
}

/// The small upper-case label over a section ("UP NEXT", "NEEDS YOU · 2").
struct Eyebrow: View {
  let text: String
  var color: Color?
  @Environment(\.colorScheme) private var scheme
  var body: some View {
    Text(text.uppercased())
      .font(.system(size: 11, weight: .bold, design: .rounded))
      .tracking(0.3)
      .foregroundStyle(color ?? Palette.of(scheme).fg2)
      .lineLimit(1)
  }
}

enum CapsuleTone { case plain, main, needs }

/// A capsule button's face: one main button per row at most (§6.7).
struct CapsuleLabel: View {
  let title: String
  var symbol: String?
  var tone: CapsuleTone = .plain
  @Environment(\.colorScheme) private var scheme
  var body: some View {
    let p = Palette.of(scheme)
    HStack(spacing: 4) {
      if let symbol { Image(systemName: symbol).font(.system(size: 10, weight: .bold)) }
      Text(title).font(.system(size: 12, weight: .bold, design: .rounded)).lineLimit(1)
    }
    .padding(.horizontal, 11)
    .padding(.vertical, 6)
    .foregroundStyle(tone == .plain ? p.fg : (scheme == .dark ? Color(hex: 0x1C1C1E) : .white))
    .background(Capsule().fill(tone == .main ? p.primary : tone == .needs ? p.wait : p.fill))
    .widgetAccentable()
    .fixedSize()
  }
}

/// A round button's face (Run now's play, Ask's microphone).
struct RoundLabel: View {
  let symbol: String
  var main = false
  var size: CGFloat = 30
  @Environment(\.colorScheme) private var scheme
  var body: some View {
    let p = Palette.of(scheme)
    Image(systemName: symbol)
      .font(.system(size: size * 0.42, weight: .bold))
      .foregroundStyle(main ? p.bg : p.fg)
      .frame(width: size, height: size)
      .background(Circle().fill(main ? p.primary : p.fill))
      .widgetAccentable()
  }
}

enum WidgetPlatform {
  /// A Mac widget can't run its buttons inside the app (LiveActivityIntent is iPhone-only), so
  /// every button there opens Casama (§2.3, §6.5).
  #if os(macOS)
  static let actsInPlace = false
  #else
  static let actsInPlace = true
  #endif
}

/// What a widget's button does (§8.4). On iPhone the acting ones run in place through the app;
/// on the Mac, or while the glance is private (the app lock is on), every one opens Casama at
/// the right place instead.
enum WidgetAct {
  case open(String)
  case runRoutine(routine: String, bot: String)
  case accept(suggestion: String, bot: String)
  case answer(approval: String, allow: Bool)

  /// Where the app opens when the act can't be done in place.
  var route: String {
    switch self {
    case let .open(r): return r
    case let .runRoutine(routine, bot): return "/run-routine/\(routine):\(bot)"
    case let .accept(id, bot): return "/suggestions/\(id)/accept?bot=\(bot)"
    case let .answer(id, _): return "/approvals/\(id)"
    }
  }
}

struct ActButton<Label: View>: View {
  let act: WidgetAct
  /// False while the glance is private: acting buttons open the app instead (§8.4, §10).
  var inPlace = true
  @ViewBuilder let label: () -> Label
  @Environment(\.widgetFamily) private var family

  var body: some View {
    #if os(iOS)
    if inPlace {
      switch act {
      case let .runRoutine(routine, bot):
        Button(intent: RunRoutineWidgetIntent(routineId: routine, botId: bot), label: label).buttonStyle(.plain)
      case let .accept(id, bot):
        Button(intent: AcceptSuggestionIntent(suggestionId: id, botId: bot), label: label).buttonStyle(.plain)
      case let .answer(id, allow):
        Button(intent: AnswerRequestIntent(approvalId: id, allow: allow, fromWidget: true), label: label).buttonStyle(.plain)
      case let .open(route):
        opener(route)
      }
    } else {
      opener(act.route)
    }
    #else
    Link(destination: appURL(act.route), label: label)
    #endif
  }

  #if os(iOS)
  /// A small widget can't hold links, only buttons: there an intent opens the app instead.
  @ViewBuilder
  private func opener(_ route: String) -> some View {
    if family == .systemSmall {
      Button(intent: OpenCasamaIntent(path: route), label: label).buttonStyle(.plain)
    } else {
      Link(destination: appURL(route), label: label)
    }
  }
  #endif
}

/// The share of credits used, as a ring in the brand colour.
struct CreditsRing: View {
  let share: Double
  var size: CGFloat = 54
  var showsLabel = true
  @Environment(\.colorScheme) private var scheme
  var body: some View {
    let p = Palette.of(scheme)
    ZStack {
      Circle().stroke(p.fill, lineWidth: size * 0.11)
      Circle()
        .trim(from: 0, to: max(0.001, min(1, share)))
        .stroke(p.primary, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .widgetAccentable()
      if showsLabel {
        Text("\(GlanceFormat.percent(share))%")
          .font(.system(size: max(11, size * 0.22), weight: .heavy, design: .rounded))
          .monospacedDigit()
          .contentTransition(.numericText())
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

/// "As of 9:41", under a widget whose data is too old to speak about now (§6.6).
struct AgeLine: View {
  let entry: GlanceEntry
  @Environment(\.colorScheme) private var scheme
  var body: some View {
    if let g = entry.glance, g.showsAge(at: entry.date) {
      Text(entry.words("as_of", ["time": GlanceFormat.when(g.freshAt, from: entry.date)]))
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(Palette.of(scheme).fg2)
        .lineLimit(1)
    }
  }
}

/// A one-line message with a face: signed out, no bots, a server too old (§6.6).
struct MessageView: View {
  let text: String
  var mascot = "winky"
  let route: String
  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family
  var body: some View {
    let p = Palette.of(scheme)
    VStack(alignment: .leading, spacing: 6) {
      BotMarkView(art: BotArt(name: "Casama", avatar: "mascot:\(mascot)"), size: family == .systemSmall ? 40 : 34)
      Spacer(minLength: 0)
      Text(text)
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundStyle(p.fg)
        .lineLimit(3)
        .minimumScaleFactor(0.9)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(appURL(route))
    .accessibilityElement(children: .combine)
  }
}

/// Shows a widget's content only when there is a glance to draw it from; otherwise the state
/// that explains why (§6.6).
struct GlanceGate<Content: View>: View {
  let entry: GlanceEntry
  /// The widget means nothing without a bot (Bot, Ask, Needs you's empty state…).
  var needsBots = true
  @ViewBuilder let content: (Glance) -> Content

  var body: some View {
    let w = entry.words
    if !entry.snap.signedIn {
      MessageView(text: w("sign_in"), route: "/")
    } else if !entry.snap.unsupported, let g = entry.glance {
      if needsBots && g.bots.isEmpty {
        MessageView(text: w("no_bots"), mascot: "wow", route: "/bots")
      } else {
        content(g)
      }
    } else {
      MessageView(text: w("update_server"), mascot: "thinker", route: "/settings")
    }
  }
}

extension View {
  /// The widget's background (white or dark grey) that the system swaps for its own material on
  /// tinted and clear Home Screens and in StandBy; and the rounded system font.
  func glanceContainer() -> some View {
    modifier(GlanceContainer())
  }
}

private struct GlanceContainer: ViewModifier {
  @Environment(\.colorScheme) private var scheme
  func body(content: Content) -> some View {
    content
      .fontDesign(.rounded)
      .foregroundStyle(Palette.of(scheme).fg)
      .containerBackground(for: .widget) { Palette.of(scheme).bg }
  }
}
