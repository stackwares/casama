import SwiftUI
import WidgetKit

// MARK: - A bot's mark, as the app draws it (client/lib/ui/bot_avatar.dart)
//
// A bot that picked a mascot shows that mascot (the art is in Assets.xcassets as mascot-<name>,
// made from assets/mascots/<name>.png); any other bot shows its initials on its gradient, the
// gradient picked from its name exactly as botPalette does. Keep both lists in step with
// bot_avatar.dart and mascot.dart. Shared by the iPhone and Mac widget extensions.

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
/// draws it) or its initials on a rounded square in its gradient. On a tinted or clear Home
/// Screen the mascot loses its colour rather than fight the person's tint (§6.7).
struct BotMarkView: View {
  let art: BotArt
  var size: CGFloat = 24
  var body: some View {
    Group {
      if let mascot = art.mascot {
        mascotImage(mascot)
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

  @ViewBuilder
  private func mascotImage(_ mascot: String) -> some View {
    let image = Image("mascot-\(mascot)").resizable().interpolation(.high)
    if #available(iOS 18.0, macOS 15.0, *) {
      image.widgetAccentedRenderingMode(.desaturated).scaledToFit()
    } else {
      image.scaledToFit()
    }
  }
}
