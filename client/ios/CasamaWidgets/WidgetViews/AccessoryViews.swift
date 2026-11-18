#if os(iOS)
import SwiftUI
import WidgetKit

// MARK: - The Lock Screen (D-405 §6.2, §10)
//
// For knowing, not doing: no buttons (Apple keeps them dead while locked). Numbers and general
// words show; anything in the person's own words is marked private, which iOS hides until the
// phone is unlocked. One glyph on all of them; mascots don't survive the single-colour look.
// iPhone only: the Mac has no Lock Screen sizes.

private let lockGlyph = "cloud"

/// A short line for a Lock Screen widget that has nothing to show yet.
private func lockState(_ entry: GlanceEntry) -> String? {
  if !entry.snap.signedIn { return entry.words("sign_in") }
  if entry.snap.serverTooOld { return entry.words("update_server") }
  return nil
}

struct NeedsYouAccessory: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    let w = entry.words
    let g = entry.glance
    let count = g?.needsCount ?? 0
    Group {
      switch family {
      case .accessoryCircular:
        ZStack {
          AccessoryWidgetBackground()
          if count == 0 {
            Image(systemName: "checkmark").font(.system(size: 22, weight: .bold))
          } else {
            VStack(spacing: 0) {
              Text("\(count)").font(.system(size: 24, weight: .heavy)).monospacedDigit().contentTransition(.numericText())
              Text(w("needs_you").uppercased()).font(.system(size: 8, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 4)
          }
        }
        .widgetAccentable()
      default:
        VStack(alignment: .leading, spacing: 1) {
          if let s = lockState(entry) {
            Label(s, systemImage: lockGlyph).font(.system(size: 13, weight: .semibold)).lineLimit(3)
          } else if let g, let first = g.needs.first {
            Label(first.general(w), systemImage: lockGlyph).font(.system(size: 13, weight: .bold)).lineLimit(1)
            // The request itself waits for the unlock.
            Text(first.text).font(.system(size: 12)).lineLimit(2).privacySensitive()
          } else if let g {
            Label(w("all_clear"), systemImage: lockGlyph).font(.system(size: 13, weight: .bold)).lineLimit(1)
            Text(g.nextDue(w, at: entry.date)).font(.system(size: 12)).lineLimit(2).privacySensitive()
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .fontDesign(.rounded)
    .widgetURL(appURL(count == 1 ? (g?.needs.first?.link ?? "/bots") : "/bots"))
    .containerBackground(for: .widget) { Color.clear }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(count == 0 ? w("all_clear") : "\(w("needs_you")), \(count)")
  }
}

struct BotAccessory: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    let w = entry.words
    let g = entry.glance
    let bot = g.flatMap { g in entry.bot.map { b in g.bots.first { $0.id == b.id } } ?? g.bots.first }
    let name = bot?.name ?? entry.bot?.name ?? entry.snap.legacy?.name ?? "Casama"
    let status = bot.flatMap { b in g.map { $0.status(of: b, at: entry.date) } } ?? "idle"
    let word = statusWord(status, w)
    Group {
      switch family {
      case .accessoryCircular:
        ZStack {
          AccessoryWidgetBackground()
          // The ring shows where it stands: full while it works, open while it waits, thin idle.
          Circle()
            .trim(from: 0, to: status == "waiting" ? 0.75 : 1)
            .stroke(style: StrokeStyle(lineWidth: status == "working" || status == "waiting" ? 4 : 1.5, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .padding(3)
            .opacity(status == "disabled" ? 0.35 : 1)
          Text(BotArt(name: name, avatar: nil).initials).font(.system(size: 20, weight: .heavy))
        }
        .widgetAccentable()
      default:
        VStack(alignment: .leading, spacing: 1) {
          if let s = lockState(entry), entry.snap.legacy == nil {
            Label(s, systemImage: lockGlyph).font(.system(size: 13, weight: .semibold)).lineLimit(3)
          } else {
            Label(name, systemImage: lockGlyph).font(.system(size: 13, weight: .bold)).lineLimit(1)
            Text(bot == nil ? (entry.snap.legacy?.status ?? word) : word).font(.system(size: 12, weight: .semibold)).lineLimit(1)
            if status == "working", let step = bot?.step, !step.isEmpty {
              Text(step).font(.system(size: 12)).lineLimit(1)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .fontDesign(.rounded)
    .widgetURL(appURL(bot?.link ?? entry.bot.map { "/bots/\($0.id)/chat" } ?? "/bots"))
    .containerBackground(for: .widget) { Color.clear }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel([name, word, status == "working" ? bot?.step : nil].compactMap { $0 }.joined(separator: ", "))
  }

  private func statusWord(_ status: String, _ w: GlanceWords) -> String {
    switch status {
    case "working": return w("working")
    case "waiting": return w("waiting")
    case "disabled": return w("off")
    default: return w("idle")
    }
  }
}

/// Up next: the next routine, its bot and a countdown that ticks by itself.
struct RoutinesAccessory: View {
  let entry: GlanceEntry

  var body: some View {
    let w = entry.words
    let item = entry.glance.flatMap { RoutinesView.items(entry, $0).first }
    VStack(alignment: .leading, spacing: 1) {
      if let s = lockState(entry) {
        Label(s, systemImage: lockGlyph).font(.system(size: 13, weight: .semibold)).lineLimit(3)
      } else if let r = item {
        Label {
          Text([w("up_next"), r.nextAt.map { GlanceFormat.when($0, from: entry.date) }].compactMap { $0 }.joined(separator: " · "))
        } icon: { Image(systemName: lockGlyph) }
        .font(.system(size: 12, weight: .semibold)).lineLimit(1)
        Text(r.name).font(.system(size: 13, weight: .bold)).lineLimit(1).privacySensitive()
        HStack(spacing: 3) {
          Text(r.bot)
          if let at = r.nextAt {
            Text("·")
            Text(at, style: .relative)
          }
        }
        .font(.system(size: 12)).lineLimit(1)
      } else {
        Label(w("up_next"), systemImage: lockGlyph).font(.system(size: 12, weight: .semibold))
        Text(w("no_routines")).font(.system(size: 13, weight: .bold)).lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .fontDesign(.rounded)
    .widgetURL(appURL(item?.link ?? "/bots"))
    .containerBackground(for: .widget) { Color.clear }
    .accessibilityElement(children: .combine)
  }
}

struct CreditsAccessory: View {
  let entry: GlanceEntry

  var body: some View {
    let s = entry.glance.map { CreditsSummary($0.credits, entry.words, at: entry.date) }
    Group {
      if let share = s?.share {
        Gauge(value: share) {
          Image(systemName: lockGlyph)
        } currentValueLabel: {
          Text("\(GlanceFormat.percent(share))%").monospacedDigit()
        }
        .gaugeStyle(.accessoryCircularCapacity)
      } else {
        ZStack {
          AccessoryWidgetBackground()
          Text(entry.glance.map { GlanceFormat.money($0.credits.todayUsd) } ?? "–")
            .font(.system(size: 13, weight: .bold)).minimumScaleFactor(0.6).padding(4)
        }
      }
    }
    .widgetAccentable()
    .fontDesign(.rounded)
    .widgetURL(appURL("/settings/usage"))
    .containerBackground(for: .widget) { Color.clear }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel([entry.words("credits"), s?.share.map { entry.words("used_pct", ["n": GlanceFormat.percent($0)]) }, s?.headline]
      .compactMap { $0 }.joined(separator: ", "))
  }
}

/// The line above the clock: "Needs you · 2", else the next routine or brief, else All clear.
struct CasamaInlineView: View {
  let entry: GlanceEntry

  var body: some View {
    let w = entry.words
    let text: String
    if let s = lockState(entry) {
      text = s
    } else if let g = entry.glance {
      // Times and general words only: an inline line can't be hidden in part until unlock.
      let routine = g.upcoming(at: entry.date).first?.nextAt
      let brief = g.brief?.nextAt.flatMap { $0 > entry.date ? $0 : nil }
      if g.needsCount > 0 {
        text = "\(w("needs_you")) · \(g.needsCount)"
      } else if let b = brief, b <= (routine ?? .distantFuture) {
        text = w("brief_at", ["time": GlanceFormat.when(b, from: entry.date)])
      } else if let r = routine {
        text = "\(w("up_next")) · \(GlanceFormat.when(r, from: entry.date))"
      } else {
        text = w("all_clear")
      }
    } else {
      text = "Casama"
    }
    return Label(text, systemImage: lockGlyph)
      .widgetURL(appURL("/bots"))
      .containerBackground(for: .widget) { Color.clear }
  }
}
#endif
