import SwiftUI
import WidgetKit

// MARK: - A bot's mark, as the app draws it (client/lib/shared/widgets/bot_avatar.dart)
//
// A bot with a mascot shows that mascot (the art is in WatchAssets.xcassets as mascot-<name>, made
// from client/assets/mascots/<name>.png); any other bot shows its initials on its own gradient,
// picked from its name exactly as botPalette does (BotPalette in WatchLogic.swift).

struct BotArt: Equatable {
  let name: String
  let mascot: String?
  let colors: [Color]

  init(name: String, avatar: String?) {
    self.name = name
    mascot = BotPalette.mascot(avatar)
    if let key = mascot, let c = BotPalette.mascots[key] {
      colors = [Color(hex: c.0), Color(hex: c.1)]
    } else {
      let p = BotPalette.initials[BotPalette.index(name)]
      colors = [Color(hex: p.0), Color(hex: p.1)]
    }
  }

  var initials: String { BotPalette.letters(name) }
}

/// The bot's mark at [size]. On a tinted watch face the mascot keeps its shape and loses its
/// colour rather than fight the tint (§6.3).
struct BotMarkView: View {
  let art: BotArt
  var size: CGFloat = 30
  /// Wrist down with details hidden: an outline with the initial, no colour (mockup "Wrist down").
  var muted = false

  var body: some View {
    Group {
      if muted {
        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
          .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
          .overlay(initialsText.foregroundStyle(Color.white.opacity(0.7)))
      } else if let mascot = art.mascot {
        Image("mascot-\(mascot)")
          .resizable()
          .interpolation(.high)
          .widgetAccentedRenderingMode(.desaturated)
          .scaledToFit()
          // The art keeps a margin for the cloud's hops (mascot.dart, _zoom).
          .frame(width: size * 1.14, height: size * 1.14)
      } else {
        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
          .fill(LinearGradient(colors: art.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
          .overlay(initialsText.foregroundStyle(.white))
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }

  private var initialsText: some View {
    Text(art.initials)
      .font(.system(size: size * (art.name.trimmingCharacters(in: .whitespaces).contains(" ") ? 0.36 : 0.44), weight: .heavy, design: .rounded))
      .minimumScaleFactor(0.5)
      .lineLimit(1)
  }
}

extension BotMarkView {
  init(name: String, avatar: String?, size: CGFloat = 30, muted: Bool = false) {
    self.init(art: BotArt(name: name, avatar: avatar), size: size, muted: muted)
  }
}

/// A named mascot that isn't a bot's: the sleepy one for All clear, the winky one for signing in.
struct MascotView: View {
  let name: String
  var size: CGFloat = 58
  var body: some View {
    Image("mascot-\(name)")
      .resizable()
      .interpolation(.high)
      .widgetAccentedRenderingMode(.desaturated)
      .scaledToFit()
      .frame(width: size, height: size)
      .accessibilityHidden(true)
  }
}
