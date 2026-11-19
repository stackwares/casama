import SwiftUI

// MARK: - The look (docs/WATCH-PROTOCOL.md §6, plan §6.9)
//
// Black, with dark grey cards. Colour only means something: amber is "needs you", green is
// "working", orchid is the one main button, red is Stop and high risk. Offline, the live colours
// drop to grey (§4.5 "true or dated"). System fonts; digits keep a fixed width so clocks don't jump.

extension Color {
  init(hex: UInt32, opacity: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xff) / 255,
      green: Double((hex >> 8) & 0xff) / 255,
      blue: Double(hex & 0xff) / 255,
      opacity: opacity
    )
  }
}

enum WatchTheme {
  static let background = Color.black
  static let card = Color(hex: 0x1C1C1E)
  static let cardRaised = Color(hex: 0x2A2A2E)
  static let amber = Color(hex: 0xF0A84A)
  static let onAmber = Color(hex: 0x201300)
  static let amberText = Color(hex: 0xFFE0B5)
  static let green = Color(hex: 0x5FD49A)
  static let greenText = Color(hex: 0xB9ECD3)
  static let orchid = Color(hex: 0xF2B0EC)
  static let onOrchid = Color(hex: 0x3B0A3D)
  static let red = Color(hex: 0xFF6B6B)
  static let secondary = Color(hex: 0x9A9AA0)
  static let dim = Color.white.opacity(0.38)

  /// Amber, or grey when what is shown may be out of date.
  static func needs(_ live: Bool) -> Color { live ? amber : secondary }
  static func working(_ live: Bool) -> Color { live ? green : secondary }

  static func needsCard(_ live: Bool) -> some ShapeStyle {
    LinearGradient(
      colors: live ? [amber.opacity(0.26), amber.opacity(0.13)] : [card, card],
      startPoint: .top, endPoint: .bottom)
  }

  static func liveCard(_ live: Bool) -> some ShapeStyle {
    LinearGradient(
      colors: live ? [green.opacity(0.22), green.opacity(0.10)] : [card, card],
      startPoint: .top, endPoint: .bottom)
  }
}

extension Font {
  /// The small upper-case label over a card ("NEEDS YOU · 2").
  static var watchEyebrow: Font { .system(.caption2, design: .rounded).weight(.heavy) }
  static var watchTitle: Font { .system(.headline, design: .rounded) }
  static var watchBody: Font { .system(.body, design: .rounded) }
  static var watchCaption: Font { .system(.footnote, design: .rounded) }
}
