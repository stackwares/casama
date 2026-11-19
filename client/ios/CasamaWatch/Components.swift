import SwiftUI
import WatchKit

// MARK: - Pieces every screen uses (mockups: docs/media/watch-mockups.html)

enum Haptic {
  /// One for "needs you", one for "done", one for a problem, a click when a hold completes (§6.7).
  static func needsYou() { WKInterfaceDevice.current().play(.notification) }
  static func done() { WKInterfaceDevice.current().play(.success) }
  static func problem() { WKInterfaceDevice.current().play(.failure) }
  static func click() { WKInterfaceDevice.current().play(.click) }
}

/// Whether the person's words should be hidden now: wrist down with the switch on (§6.1 J, §10).
struct WristDownKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
  var hideWords: Bool {
    get { self[WristDownKey.self] }
    set { self[WristDownKey.self] = newValue }
  }
}

/// Text that becomes grey bars when the wrist is down: counts, bot names and clocks stay, the
/// person's words don't.
struct PrivateText: View {
  let text: String
  var font: Font = .watchBody
  var color: Color = .white
  var lines: Int? = 2
  @Environment(\.hideWords) private var hide

  init(_ text: String, font: Font = .watchBody, color: Color = .white, lines: Int? = 2) {
    self.text = text
    self.font = font
    self.color = color
    self.lines = lines
  }

  var body: some View {
    if hide {
      VStack(alignment: .leading, spacing: 5) {
        Capsule().fill(WatchTheme.dim).frame(width: 86, height: 8)
        if (lines ?? 2) > 1 { Capsule().fill(WatchTheme.dim).frame(width: 54, height: 8) }
      }
      .padding(.vertical, 3)
      .accessibilityHidden(true)
    } else {
      Text(text)
        .font(font)
        .foregroundStyle(color)
        .lineLimit(lines)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

struct Card<Background: ShapeStyle, Content: View>: View {
  let background: Background
  @ViewBuilder let content: Content
  @Environment(\.hideWords) private var hide

  init(_ background: Background, @ViewBuilder content: () -> Content) {
    self.background = background
    self.content = content()
  }

  var body: some View {
    content
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        // Wrist down the cards lose their fill (mockup "Wrist down"): only an outline.
        if hide {
          RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        } else {
          RoundedRectangle(cornerRadius: 17, style: .continuous).fill(background)
        }
      }
  }
}

extension Card where Background == Color {
  init(@ViewBuilder content: () -> Content) { self.init(WatchTheme.card, content: content) }
}

/// "NEEDS YOU · 2" and the like.
struct Eyebrow: View {
  let text: String
  var color: Color
  var body: some View {
    Text(text.uppercased())
      .font(.watchEyebrow)
      .tracking(0.4)
      .foregroundStyle(color)
      .lineLimit(1)
  }
}

struct RiskChip: View {
  let risk: WatchRisk
  var body: some View {
    let (text, color): (String, Color) = {
      switch risk {
      case .low: return (WatchL10n.lowRisk, Color(hex: 0x6E9BFF))
      case .medium: return (WatchL10n.mediumRisk, WatchTheme.amber)
      case .high: return (WatchL10n.highRisk, WatchTheme.red)
      }
    }()
    HStack(spacing: 4) {
      Image(systemName: risk == .high ? "lock.fill" : "circle.fill")
        .font(.system(size: risk == .high ? 9 : 6))
      Text(text).font(.system(.caption2, design: .rounded).weight(.bold))
    }
    .foregroundStyle(risk == .low ? Color.white : color)
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(Capsule().fill(Color.white.opacity(0.12)))
    .accessibilityElement(children: .combine)
  }
}

/// A capsule button in one of the colours that mean something.
struct PillStyle: ButtonStyle {
  enum Tone { case allow, main, plain, stop }
  var tone: Tone = .plain
  var small = false

  func makeBody(configuration: Configuration) -> some View {
    let (fill, text): (Color, Color) = {
      switch tone {
      case .allow: return (WatchTheme.amber, WatchTheme.onAmber)
      case .main: return (WatchTheme.orchid, WatchTheme.onOrchid)
      case .plain: return (WatchTheme.cardRaised, .white)
      case .stop: return (WatchTheme.red.opacity(0.22), WatchTheme.red)
      }
    }()
    configuration.label
      .font(.system(small ? .footnote : .body, design: .rounded).weight(.semibold))
      .foregroundStyle(text)
      .lineLimit(2)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 12)
      .padding(.vertical, small ? 6 : 9)
      .frame(maxWidth: .infinity, minHeight: small ? 32 : 40)
      .background(Capsule().fill(fill))
      .opacity(configuration.isPressed ? 0.75 : 1)
      .contentShape(Capsule())
  }
}

/// A round glass button for the bottom bar (mockup `.g`).
struct RoundIcon: View {
  let symbol: String
  var size: CGFloat = 30
  var tone: PillStyle.Tone = .plain
  var body: some View {
    let (fill, fg): (Color, Color) = {
      switch tone {
      case .main: return (WatchTheme.orchid, WatchTheme.onOrchid)
      case .stop: return (WatchTheme.red.opacity(0.22), WatchTheme.red)
      case .allow: return (WatchTheme.amber, WatchTheme.onAmber)
      case .plain: return (Color.white.opacity(0.15), .white)
      }
    }()
    Image(systemName: symbol)
      .font(.system(size: size * 0.45, weight: .semibold))
      .foregroundStyle(fg)
      .frame(width: size, height: size)
      .background(Circle().fill(fill))
  }
}

/// "Offline · as of 9:12", above anything that may be out of date.
struct DatedBanner: View {
  let savedAt: Date?
  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: "wifi.slash").font(.caption2)
      Text(savedAt.map { "\(WatchL10n.offline) · \(WatchTime.asOf($0))" } ?? WatchL10n.offline)
        .font(.watchCaption)
        .lineLimit(2)
    }
    .foregroundStyle(WatchTheme.secondary)
    .padding(.horizontal, 6)
    .accessibilityElement(children: .combine)
  }
}

/// A running clock that ticks by itself, digits fixed so it doesn't jump.
struct RunClock: View {
  let start: Date?
  var end: Date? = nil
  var color: Color = WatchTheme.green
  var body: some View {
    Group {
      if let start, let end {
        Text(WatchTime.elapsed(end.timeIntervalSince(start)))
      } else if let start {
        Text(timerInterval: start...Date.distantFuture, countsDown: false)
      } else {
        Text(verbatim: "–:––")
      }
    }
    .font(.system(.footnote, design: .rounded).weight(.semibold))
    .monospacedDigit()
    .foregroundStyle(color)
  }
}

/// The bot's face in a turning ring while it works (still with Reduce Motion, §6.9).
struct WorkingRing: View {
  let name: String
  let avatar: String
  var size: CGFloat = 78
  var color: Color = WatchTheme.green
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var turn = false

  var body: some View {
    ZStack {
      Circle().stroke(Color.white.opacity(0.12), lineWidth: 5)
      Circle()
        .trim(from: 0, to: 0.34)
        .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        .rotationEffect(.degrees(turn ? 270 : -90))
      BotMarkView(name: name, avatar: avatar, size: size * 0.66)
    }
    .frame(width: size, height: size)
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) { turn = true }
    }
    .accessibilityHidden(true)
  }
}

/// The full-screen tick after an answer: it draws, the wrist taps, and it closes itself.
struct DoneOverlay: View {
  let flash: Flash
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var drawn = false

  private var text: String {
    switch flash.kind {
    case .allowed: return WatchL10n.allowed
    case .denied: return WatchL10n.denied
    case .done: return WatchL10n.done
    case .started: return WatchL10n.started
    case .sent: return WatchL10n.sentToPhone
    case .alreadyAnswered: return WatchL10n.alreadyAnswered
    }
  }

  private var color: Color {
    switch flash.kind {
    case .denied, .alreadyAnswered: return WatchTheme.secondary
    default: return WatchTheme.green
    }
  }

  var body: some View {
    VStack(spacing: 10) {
      ZStack {
        Circle().stroke(color.opacity(0.3), lineWidth: 4)
        TickShape()
          .trim(from: 0, to: drawn ? 1 : 0)
          .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
          .padding(18)
      }
      .frame(width: 72, height: 72)
      Text(text).font(.watchTitle).multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .onAppear {
      if reduceMotion { drawn = true } else { withAnimation(.easeOut(duration: 0.35)) { drawn = true } }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(text)
    .accessibilityAddTraits(.isStaticText)
  }
}

struct TickShape: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
    p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.12))
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12))
    return p
  }
}

/// Hold to allow (§6.1 B, §6.7): fills over most of a second, clicks when it completes. With
/// VoiceOver it is a tap followed by a confirmation, since a hold can't be performed there.
struct HoldToAllowButton: View {
  let confirmTitle: String
  let action: () -> Void
  var duration: Double = 0.8

  @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var progress: CGFloat = 0
  @State private var confirming = false

  var body: some View {
    if voiceOver {
      Button(WatchL10n.allow) { confirming = true }
        .buttonStyle(PillStyle(tone: .allow))
        .accessibilityHint(WatchL10n.holdHint)
        .confirmationDialog(confirmTitle, isPresented: $confirming, titleVisibility: .visible) {
          Button(WatchL10n.allow) { action() }
          Button(WatchL10n.notNow, role: .cancel) {}
        }
    } else {
      ZStack(alignment: .leading) {
        Capsule().fill(WatchTheme.amber.opacity(0.35))
        GeometryReader { geo in
          Capsule().fill(WatchTheme.amber).frame(width: max(0, geo.size.width * progress))
        }
        Text(WatchL10n.holdToAllow)
          .font(.system(.body, design: .rounded).weight(.semibold))
          // Light on the dim capsule, dark once the solid fill is under the words.
          .foregroundStyle(progress < 0.5 ? WatchTheme.amberText : WatchTheme.onAmber)
          .frame(maxWidth: .infinity)
          .lineLimit(2)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 10)
      }
      .frame(minHeight: 40)
      .clipShape(Capsule())
      .contentShape(Capsule())
      .onLongPressGesture(minimumDuration: duration, maximumDistance: 20, perform: {
        Haptic.click()
        progress = 1
        action()
      }, onPressingChanged: { pressing in
        if pressing {
          if reduceMotion { progress = 0.5 } else { withAnimation(.linear(duration: duration)) { progress = 1 } }
        } else {
          withAnimation(.easeOut(duration: 0.15)) { progress = 0 }
        }
      })
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(WatchL10n.holdToAllow)
      .accessibilityAddTraits(.isButton)
    }
  }
}

/// A plain message screen: a face, a line, and maybe a button.
struct MessageScreen<Actions: View>: View {
  var mascot: String = "winky"
  let title: String
  var detail: String? = nil
  @ViewBuilder var actions: Actions

  var body: some View {
    ScrollView {
      VStack(spacing: 6) {
        MascotView(name: mascot, size: 58)
        Text(title).font(.watchTitle).multilineTextAlignment(.center)
        if let detail {
          Text(detail).font(.watchCaption).foregroundStyle(WatchTheme.secondary).multilineTextAlignment(.center)
        }
        actions.padding(.top, 4)
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 6)
    }
  }
}

extension MessageScreen where Actions == EmptyView {
  init(mascot: String = "winky", title: String, detail: String? = nil) {
    self.init(mascot: mascot, title: title, detail: detail) { EmptyView() }
  }
}
