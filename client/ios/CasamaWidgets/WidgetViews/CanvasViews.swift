import SwiftUI
import WidgetKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - The Canvas widget's views (docs/BOT-WIDGET-PLAN.md §6.1–§6.5, §10.1)
//
// Five templates (text, countdown, number, list, picture) across the Home Screen sizes and, on
// iPhone, the three Lock Screen sizes. The server cut every text and chose the text colour (`ink`),
// so these only draw: never a colour of their own for text in full colour. On tinted and clear Home
// Screens and in StandBy the system drops the background, and the text follows the system. Hide on
// a locked phone draws the canvas's name only while locked; a private list (the app lock is on)
// draws names and bots only. Shared by the iPhone and Mac widget extensions.

/// The widget: Home Screen sizes, or the Lock Screen's on iPhone.
struct CanvasWidgetView: View {
  let entry: CanvasTimelineEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    #if os(iOS)
    case .accessoryRectangular, .accessoryInline, .accessoryCircular:
      CanvasAccessory(entry: entry)
    #endif
    default:
      CanvasHome(entry: entry)
    }
  }
}

// MARK: - The look

/// A canvas look turned into colours and type for one rendering.
struct CanvasStyle {
  let look: CanvasLook
  let scheme: ColorScheme
  /// Full colour with the widget's background showing: the server's ink applies. Otherwise (tinted,
  /// clear, StandBy, the Lock Screen) the system's own colour does.
  let fullColor: Bool

  static func color(_ hex: String?) -> Color? {
    guard var s = hex?.trimmingCharacters(in: .whitespaces), !s.isEmpty else { return nil }
    if s.hasPrefix("#") { s.removeFirst() }
    guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
    return Color(hex: v)
  }

  /// The text colour: white for `light`, near-black for `dark`, the app's text colour for `auto`.
  var ink: Color {
    guard fullColor else { return .primary }
    switch look.ink {
    case "light": return .white
    case "dark": return Color(hex: 0x1D1B20)
    default: return Palette.of(scheme).fg
    }
  }

  var inkSoft: Color { ink.opacity(0.78) }

  /// Rings, bars and ticks.
  var accent: Color {
    guard fullColor else { return .primary }
    return Self.color(look.accent) ?? Palette.of(scheme).primary
  }

  var design: Font.Design {
    switch look.font {
    case "serif": return .serif
    case "rounded": return .rounded
    case "mono": return .monospaced
    default: return .default
    }
  }

  var centered: Bool { look.align == "center" }
  var hAlign: HorizontalAlignment { centered ? .center : .leading }
  var textAlign: TextAlignment { centered ? .center : .leading }
  var frameAlign: Alignment { centered ? .center : .leading }

  /// The surface behind an `auto` background: the app's, or its dark grey under light ink so the
  /// text stays readable when a picture is missing.
  var surface: Color {
    look.ink == "light" ? Color(hex: 0x1C1C1E) : Palette.of(scheme).bg
  }
}

/// Type sizes and how much fits, by size.
private struct CanvasMetrics {
  let title, body, big: CGFloat
  let lines, rows: Int
  let mark: CGFloat

  static func of(_ family: WidgetFamily) -> CanvasMetrics {
    switch family {
    case .systemMedium: return CanvasMetrics(title: 14, body: 17, big: 40, lines: 6, rows: 4, mark: 18)
    case .systemLarge: return CanvasMetrics(title: 16, body: 22, big: 56, lines: 12, rows: 5, mark: 20)
    case .systemExtraLarge: return CanvasMetrics(title: 18, body: 26, big: 64, lines: 12, rows: 5, mark: 22)
    default: return CanvasMetrics(title: 13, body: 15, big: 34, lines: 6, rows: 3, mark: 16)
    }
  }
}

/// An emoji as text, a known icon name as a system symbol; unknown names draw nothing.
struct CanvasIconView: View {
  let icon: String?
  var size: CGFloat = 14

  var body: some View {
    switch CanvasIcon(icon) {
    case let .emoji(s)?:
      Text(s).font(.system(size: size)).accessibilityHidden(true)
    case let .name(n)?:
      if let symbol = Self.symbol(n) {
        Image(systemName: symbol).font(.system(size: size, weight: .semibold)).widgetAccentable().accessibilityHidden(true)
      }
    case nil:
      EmptyView()
    }
  }

  static func symbol(_ name: String) -> String? {
    let candidate = CanvasIcon.symbols[name] ?? name
    #if canImport(UIKit)
    return UIImage(systemName: candidate) == nil ? nil : candidate
    #elseif canImport(AppKit)
    return NSImage(systemSymbolName: candidate, accessibilityDescription: nil) == nil ? nil : candidate
    #else
    return nil
    #endif
  }
}

/// A stored picture filling its box, shrunk to what the widget draws.
struct CanvasPictureFill: View {
  let file: URL
  let pixels: Int

  var body: some View {
    if let image = GlanceFetch.coverImage(file, pixels: pixels) {
      picture(Image(decorative: image, scale: 1).resizable())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
  }

  /// On a tinted or clear Home Screen the picture loses its colour rather than fight the tint.
  @ViewBuilder
  private func picture(_ image: Image) -> some View {
    if #available(iOS 18.0, macOS 15.0, *) {
      image.widgetAccentedRenderingMode(.desaturated).scaledToFill()
    } else {
      image.scaledToFill()
    }
  }
}

/// The widget's background: the entry's picture for `picture`, else the look's background. A
/// picture under light text gets a soft dark shade.
struct CanvasBackdrop: View {
  let entry: CanvasEntry
  let style: CanvasStyle
  let pixels: Int

  var body: some View {
    let bg = entry.look.background
    let shade = entry.look.ink == "light"
    if entry.template == "picture", let file = CanvasStore.picture(entry.picture) {
      CanvasPictureFill(file: file, pixels: pixels)
        .overlay(LinearGradient(colors: [.clear, .black.opacity(shade ? 0.55 : 0)], startPoint: .center, endPoint: .bottom))
    } else {
      switch bg.kind {
      case "color":
        CanvasStyle.color(bg.color) ?? style.surface
      case "gradient":
        LinearGradient(
          colors: [CanvasStyle.color(bg.from) ?? style.surface, CanvasStyle.color(bg.to) ?? style.surface],
          startPoint: .topLeading, endPoint: .bottomTrailing)
      case "picture":
        if let file = CanvasStore.picture(bg.picture) {
          CanvasPictureFill(file: file, pixels: pixels).overlay(Color.black.opacity(shade ? 0.3 : 0))
        } else {
          style.surface
        }
      default:
        style.surface
      }
    }
  }
}

// MARK: - The Home Screen and the desktop

struct CanvasHome: View {
  let entry: CanvasTimelineEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetRenderingMode) private var mode
  @Environment(\.showsWidgetContainerBackground) private var showsBackground
  @Environment(\.redactionReasons) private var redaction
  @Environment(\.displayScale) private var displayScale

  var body: some View {
    let w = entry.words
    if !entry.snap.signedIn {
      MessageView(text: w("sign_in"), route: "/").glanceContainer()
    } else if let c = entry.canvas {
      if let e = entry.current, !(c.hideWhenLocked && redaction.contains(.privacy)) {
        let style = CanvasStyle(look: e.look, scheme: scheme, fullColor: mode == .fullColor && showsBackground)
        CanvasContent(canvas: c, entry: e, date: entry.date, words: w, style: style)
          .privacySensitive(c.hideWhenLocked)
          .overlay(alignment: .topTrailing) {
            BotMarkView(art: BotArt(name: c.bot, avatar: c.botAvatar), size: CanvasMetrics.of(family).mark).opacity(0.95)
          }
          .widgetURL(appURL(c.link))
          .containerBackground(for: .widget) { CanvasBackdrop(entry: e, style: style, pixels: pixels) }
      } else {
        CanvasNames(canvas: c).glanceContainer()
      }
    } else {
      CanvasEmpty(words: w).glanceContainer()
    }
  }

  /// The picture size this widget draws, in pixels.
  private var pixels: Int {
    let points = CanvasFetch.size(of: family).map(CanvasFetch.points(of:)) ?? 400
    return max(200, Int(CGFloat(points) * max(1, displayScale)))
  }
}

/// No canvas yet (§6.5).
struct CanvasEmpty: View {
  let words: GlanceWords
  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family

  var body: some View {
    let p = Palette.of(scheme)
    VStack(alignment: .leading, spacing: 6) {
      BotMarkView(art: BotArt(name: "Casama", avatar: "mascot:starry"), size: family == .systemSmall ? 36 : 32)
      Spacer(minLength: 0)
      Text(words.canvas("canvas_empty"))
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundStyle(p.fg)
        .lineLimit(3)
        .minimumScaleFactor(0.85)
      Text(words.canvas("canvas_try"))
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(p.fg2)
        .lineLimit(family == .systemSmall ? 2 : 3)
        .minimumScaleFactor(0.85)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(appURL("/bots"))
    .accessibilityElement(children: .combine)
  }
}

/// A canvas by name and bot only: a private list, or Hide on a locked phone while locked.
struct CanvasNames: View {
  let canvas: BotCanvas
  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family

  var body: some View {
    let p = Palette.of(scheme)
    VStack(alignment: .leading, spacing: 4) {
      BotMarkView(art: BotArt(name: canvas.bot, avatar: canvas.botAvatar), size: family == .systemSmall ? 34 : 30)
      Spacer(minLength: 0)
      Text(canvas.name)
        .font(.system(size: family == .systemSmall ? 17 : 19, weight: .bold, design: .rounded))
        .foregroundStyle(p.fg)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
      Text(canvas.bot)
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(p.fg2)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(appURL(canvas.link))
    .accessibilityElement(children: .combine)
  }
}

/// One entry, drawn by its template.
struct CanvasContent: View {
  let canvas: BotCanvas
  let entry: CanvasEntry
  let date: Date
  let words: GlanceWords
  let style: CanvasStyle
  @Environment(\.widgetFamily) private var family

  private var m: CanvasMetrics { CanvasMetrics.of(family) }
  private var wide: Bool { family != .systemSmall }
  private var large: Bool { family == .systemLarge || family == .systemExtraLarge }

  var body: some View {
    Group {
      switch entry.template {
      case "countdown": countdown
      case "number": number
      case "list": list
      case "picture": picture
      default: text
      }
    }
    .foregroundStyle(style.ink)
    .fontDesign(style.design)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: style.frameAlign)
    .accessibilityElement(children: .combine)
  }

  // MARK: Pieces

  /// Icon and title, clear of the bot's mark in the corner.
  @ViewBuilder
  private var header: some View {
    let title = entry.title.flatMap { $0.isEmpty ? nil : $0 }
    if title != nil || CanvasIcon(entry.look.icon) != nil {
      HStack(spacing: 5) {
        CanvasIconView(icon: entry.look.icon, size: m.title + 2)
        if let title {
          Text(title).font(.system(size: m.title, weight: .bold)).lineLimit(1).widgetAccentable()
        }
      }
      .padding(style.centered ? .horizontal : .trailing, m.mark + 4)
      .frame(maxWidth: .infinity, alignment: style.frameAlign)
    }
  }

  @ViewBuilder
  private var footer: some View {
    if let f = entry.footer, !f.isEmpty {
      Text(f)
        .font(.system(size: max(11, m.title - 1), weight: .medium))
        .foregroundStyle(style.inkSoft)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: style.frameAlign)
    }
  }

  @ViewBuilder
  private var longText: some View {
    if let t = entry.text, !t.isEmpty {
      Text(t)
        .font(.system(size: max(12, m.body - 4), weight: .regular))
        .foregroundStyle(style.inkSoft)
        .multilineTextAlignment(style.textAlign)
        .lineLimit(3)
        .frame(maxWidth: .infinity, alignment: style.frameAlign)
    }
  }

  // MARK: text

  private var text: some View {
    VStack(alignment: style.hAlign, spacing: 6) {
      header
      Spacer(minLength: 0)
      Text(entry.text ?? entry.short)
        .font(.system(size: m.body, weight: .semibold))
        .multilineTextAlignment(style.textAlign)
        .lineLimit(m.lines)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity, alignment: style.frameAlign)
      Spacer(minLength: 0)
      footer
    }
  }

  // MARK: countdown

  private var countdown: some View {
    VStack(alignment: style.hAlign, spacing: 4) {
      header
      Spacer(minLength: 0)
      if let target = entry.target {
        CanvasCount(show: CountdownShow.at(date, target: target, count: entry.count), words: words, size: m.big, style: style)
          .frame(maxWidth: .infinity, alignment: style.frameAlign)
        if wide {
          Text(target.formatted(date: .abbreviated, time: Calendar.current.component(.hour, from: target) == 0 ? .omitted : .shortened))
            .font(.system(size: max(11, m.title - 1), weight: .semibold))
            .foregroundStyle(style.inkSoft)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: style.frameAlign)
        }
      }
      if large { longText }
      Spacer(minLength: 0)
      if wide { footer }
    }
  }

  // MARK: number

  private var share: Double? {
    guard let of = entry.of, of > 0 else { return nil }
    return min(1, max(0, (entry.value ?? 0) / of))
  }

  private var valueText: String { entry.value.map(CanvasEntry.format) ?? "–" }

  private var number: some View {
    VStack(alignment: style.hAlign, spacing: 6) {
      header
      Spacer(minLength: 0)
      if wide {
        HStack(spacing: 14) {
          gauge(size: m.big * 1.8)
          VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
              Text(valueText).font(.system(size: m.big * 0.75, weight: .heavy)).monospacedDigit().contentTransition(.numericText())
              if let of = entry.of {
                Text("/ \(CanvasEntry.format(of))").font(.system(size: m.title + 2, weight: .semibold)).foregroundStyle(style.inkSoft)
              }
            }
            .lineLimit(1).minimumScaleFactor(0.6)
            if let u = entry.unit, !u.isEmpty {
              Text(u).font(.system(size: m.title, weight: .semibold)).foregroundStyle(style.inkSoft).lineLimit(1)
            }
            footer
          }
        }
        .frame(maxWidth: .infinity, alignment: style.frameAlign)
        if large { longText }
      } else {
        gauge(size: 74).frame(maxWidth: .infinity, alignment: style.frameAlign)
        if entry.of == nil { footer }
      }
      Spacer(minLength: 0)
    }
  }

  /// The value in a ring when there's a goal, else large with its unit.
  @ViewBuilder
  private func gauge(size: CGFloat) -> some View {
    if let share {
      ZStack {
        Circle().stroke(style.ink.opacity(0.18), lineWidth: size * 0.1)
        Circle()
          .trim(from: 0, to: max(0.001, share))
          .stroke(style.accent, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
          .rotationEffect(.degrees(-90))
          .widgetAccentable()
        VStack(spacing: 0) {
          Text(valueText).font(.system(size: size * 0.3, weight: .heavy)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
          if !wide, let u = entry.unit, !u.isEmpty {
            Text(u).font(.system(size: max(9, size * 0.13), weight: .semibold)).foregroundStyle(style.inkSoft).lineLimit(1)
          }
        }
        .padding(size * 0.14)
      }
      .frame(width: size, height: size)
    } else {
      VStack(alignment: style.hAlign, spacing: 0) {
        Text(valueText).font(.system(size: m.big, weight: .heavy)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
        if let u = entry.unit, !u.isEmpty {
          Text(u).font(.system(size: m.title, weight: .semibold)).foregroundStyle(style.inkSoft).lineLimit(1)
        }
      }
    }
  }

  // MARK: list

  private var list: some View {
    VStack(alignment: .leading, spacing: wide ? 6 : 5) {
      header
      ForEach(Array(entry.items.prefix(m.rows).enumerated()), id: \.offset) { _, item in
        HStack(spacing: 7) {
          Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
            .font(.system(size: m.title + 1, weight: .semibold))
            .foregroundStyle(item.done ? style.accent : style.inkSoft)
            .widgetAccentable(item.done)
          Text(item.text)
            .font(.system(size: m.title + 1, weight: .medium))
            .strikethrough(item.done)
            .foregroundStyle(item.done ? style.inkSoft : style.ink)
            .lineLimit(1)
        }
      }
      Spacer(minLength: 0)
      footer
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  // MARK: picture

  private var picture: some View {
    VStack(alignment: style.hAlign, spacing: 3) {
      header
      Spacer(minLength: 0)
      if let t = entry.text, !t.isEmpty {
        Text(t)
          .font(.system(size: m.title + 1, weight: .semibold))
          .multilineTextAlignment(style.textAlign)
          .lineLimit(large ? 3 : 2)
          .frame(maxWidth: .infinity, alignment: style.frameAlign)
      }
      footer
    }
  }
}

/// A countdown's time: whole days as text, under a day a timer the system ticks.
struct CanvasCount: View {
  let show: CountdownShow
  let words: GlanceWords
  let size: CGFloat
  let style: CanvasStyle

  var body: some View {
    switch show {
    case let .days(n, since):
      VStack(alignment: style.hAlign, spacing: 0) {
        Text("\(n)").font(.system(size: size, weight: .heavy)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5).contentTransition(.numericText())
        let unit = words.canvasDayUnit(n)
        Text(since ? words.canvas("canvas_since", ["time": unit]) : unit)
          .font(.system(size: max(11, size * 0.32), weight: .semibold))
          .foregroundStyle(style.inkSoft)
          .lineLimit(1)
      }
    case let .timer(from, to, down):
      Text(timerInterval: from...to, countsDown: down)
        .font(.system(size: size * 0.7, weight: .heavy))
        .monospacedDigit()
        .multilineTextAlignment(style.textAlign)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    case .now:
      Text(words.canvas("canvas_now")).font(.system(size: size * 0.8, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.5)
    }
  }
}

// MARK: - The Lock Screen (iPhone only)

#if os(iOS)
/// One colour, no background: the Lock Screen's look. Rectangular draws the title and two lines,
/// inline one line above the clock, circular a number, a ring or the icon (§6.3).
struct CanvasAccessory: View {
  let entry: CanvasTimelineEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.redactionReasons) private var redaction

  var body: some View {
    Group {
      if !entry.snap.signedIn {
        message(entry.words("sign_in"), symbol: "cloud")
      } else if let c = entry.canvas {
        if let e = entry.current, !(c.hideWhenLocked && redaction.contains(.privacy)) {
          content(c, e).privacySensitive(c.hideWhenLocked)
        } else {
          names(c)
        }
      } else {
        message(entry.words.canvas("canvas_empty"), symbol: "square.dashed")
      }
    }
    .fontDesign(.rounded)
    .widgetURL(appURL(entry.canvas?.link ?? "/bots"))
    .containerBackground(for: .widget) { Color.clear }
  }

  // MARK: States

  @ViewBuilder
  private func message(_ text: String, symbol: String) -> some View {
    switch family {
    case .accessoryCircular:
      ZStack {
        AccessoryWidgetBackground()
        Image(systemName: symbol).font(.system(size: 22, weight: .semibold))
      }
      .accessibilityLabel(text)
    case .accessoryInline:
      Label(text, systemImage: symbol)
    default:
      Label(text, systemImage: symbol).font(.system(size: 13, weight: .semibold)).lineLimit(3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private func names(_ c: BotCanvas) -> some View {
    switch family {
    case .accessoryCircular:
      ZStack {
        AccessoryWidgetBackground()
        Text(BotArt(name: c.name, avatar: nil).initials).font(.system(size: 20, weight: .heavy))
      }
      .widgetAccentable()
      .accessibilityLabel(c.name)
    case .accessoryInline:
      Text(c.name)
    default:
      VStack(alignment: .leading, spacing: 1) {
        Text(c.name).font(.system(size: 14, weight: .bold)).lineLimit(1).widgetAccentable()
        Text(c.bot).font(.system(size: 12)).lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // MARK: Content

  @ViewBuilder
  private func content(_ c: BotCanvas, _ e: CanvasEntry) -> some View {
    switch family {
    case .accessoryCircular: circular(c, e)
    case .accessoryInline: inline(c, e)
    default: rectangular(c, e)
    }
  }

  private func title(_ c: BotCanvas, _ e: CanvasEntry) -> String {
    e.title.flatMap { $0.isEmpty ? nil : $0 } ?? c.name
  }

  private func share(_ e: CanvasEntry) -> Double? {
    guard let of = e.of, of > 0 else { return nil }
    return min(1, max(0, (e.value ?? 0) / of))
  }

  /// A line for a countdown: "12 days", a ticking timer, or Now.
  private func countLine(_ e: CanvasEntry) -> Text {
    guard let target = e.target else { return Text(e.short) }
    let w = entry.words
    switch CountdownShow.at(entry.date, target: target, count: e.count) {
    case let .days(n, since):
      return Text(since ? w.canvas("canvas_since", ["time": w.canvasDays(n)]) : w.canvas("canvas_in", ["time": w.canvasDays(n)]))
    case let .timer(from, to, down):
      return Text(timerInterval: from...to, countsDown: down)
    case .now:
      return Text(w.canvas("canvas_now"))
    }
  }

  @ViewBuilder
  private func rectangular(_ c: BotCanvas, _ e: CanvasEntry) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      HStack(spacing: 4) {
        CanvasIconView(icon: e.look.icon, size: 13)
        Text(title(c, e)).font(.system(size: 14, weight: .bold)).lineLimit(1)
      }
      .widgetAccentable()
      switch e.template {
      case "countdown":
        countLine(e).font(.system(size: 15, weight: .semibold)).monospacedDigit().lineLimit(1)
        if let f = e.footer, !f.isEmpty { Text(f).font(.system(size: 12)).lineLimit(1) }
      case "number":
        Text([e.value.map(CanvasEntry.format), e.of.map { "/ \(CanvasEntry.format($0))" }, e.unit].compactMap { $0 }.joined(separator: " "))
          .font(.system(size: 14, weight: .semibold)).monospacedDigit().lineLimit(1)
        if let s = share(e) {
          ProgressView(value: s).progressViewStyle(.linear).widgetAccentable()
        }
      case "list":
        ForEach(Array(e.items.prefix(2).enumerated()), id: \.offset) { _, item in
          Label {
            Text(item.text).strikethrough(item.done).lineLimit(1)
          } icon: {
            Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
          }
          .font(.system(size: 12))
        }
      default:
        Text(e.short).font(.system(size: 12)).lineLimit(e.template == "picture" ? 3 : 2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private func inline(_ c: BotCanvas, _ e: CanvasEntry) -> some View {
    let emoji: String? = { if case let .emoji(s)? = CanvasIcon(e.look.icon) { return s } else { return nil } }()
    let symbol: String? = { if case let .name(n)? = CanvasIcon(e.look.icon) { return CanvasIconView.symbol(n) } else { return nil } }()
    let prefix = emoji.map { "\($0) " } ?? ""
    let line: Text = {
      switch e.template {
      case "countdown":
        return Text(prefix + title(c, e) + " ") + countLine(e)
      case "number":
        return Text(prefix + [e.value.map(CanvasEntry.format), e.unit].compactMap { $0 }.joined(separator: " "))
      case "list":
        return Text(prefix + (e.items.first { !$0.done }?.text ?? e.tiny))
      default:
        return Text(prefix + e.tiny)
      }
    }()
    if let symbol {
      Label { line } icon: { Image(systemName: symbol) }
    } else {
      line
    }
  }

  @ViewBuilder
  private func circular(_ c: BotCanvas, _ e: CanvasEntry) -> some View {
    switch e.template {
    case "countdown":
      ZStack {
        AccessoryWidgetBackground()
        if let target = e.target {
          switch CountdownShow.at(entry.date, target: target, count: e.count) {
          case let .days(n, _):
            VStack(spacing: -2) {
              Text("\(n)").font(.system(size: 22, weight: .heavy)).monospacedDigit().minimumScaleFactor(0.6)
              Text(entry.words.canvasDayUnit(n).uppercased())
                .font(.system(size: 8, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 4)
          case let .timer(from, to, down):
            Text(timerInterval: from...to, countsDown: down)
              .font(.system(size: 12, weight: .bold)).monospacedDigit()
              .multilineTextAlignment(.center).minimumScaleFactor(0.6).padding(.horizontal, 6)
          case .now:
            Image(systemName: "checkmark").font(.system(size: 22, weight: .bold))
          }
        }
      }
      .widgetAccentable()
      .accessibilityElement(children: .combine)
    case "number":
      if let s = share(e) {
        Gauge(value: s) {
          CanvasIconView(icon: e.look.icon, size: 10)
        } currentValueLabel: {
          Text(e.value.map(CanvasEntry.format) ?? "–").monospacedDigit()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
      } else {
        ZStack {
          AccessoryWidgetBackground()
          VStack(spacing: -2) {
            Text(e.value.map(CanvasEntry.format) ?? "–").font(.system(size: 20, weight: .heavy)).monospacedDigit().minimumScaleFactor(0.5)
            if let u = e.unit, !u.isEmpty { Text(u).font(.system(size: 8, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6) }
          }
          .padding(.horizontal, 5)
        }
        .widgetAccentable()
      }
    case "list":
      ZStack {
        AccessoryWidgetBackground()
        VStack(spacing: -2) {
          Text("\(e.itemsLeft)").font(.system(size: 22, weight: .heavy)).monospacedDigit()
          Text(entry.words.canvas("canvas_left_unit").uppercased()).font(.system(size: 8, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6)
        }
      }
      .widgetAccentable()
      .accessibilityLabel(entry.words.canvas("canvas_left", ["n": "\(e.itemsLeft)"]))
    default:
      ZStack {
        AccessoryWidgetBackground()
        if CanvasIcon(e.look.icon) != nil {
          CanvasIconView(icon: e.look.icon, size: 26)
        } else {
          Text(BotArt(name: c.name, avatar: nil).initials).font(.system(size: 20, weight: .heavy))
        }
      }
      .widgetAccentable()
      .accessibilityLabel(c.name)
    }
  }
}
#endif
