import SwiftUI
import WidgetKit

// MARK: - Needs you, Bot, Ask and Routines on the Home Screen and desktop (D-405 §6.1 A–D)
//
// Shared by the iPhone and Mac widget extensions. The Mac draws the same views with every button
// opening Casama (ActButton), since a Mac widget can't run its buttons inside the app.

extension Glance.Need {
  /// The request in the person's words, or general words when the glance is private.
  func line(_ w: GlanceWords) -> String {
    text.isEmpty ? general(w) : text
  }

  /// "Milo needs your OK", "Ada suggests", "Scout needs you to take over".
  func general(_ w: GlanceWords) -> String {
    switch kind {
    case "approval": return w("needs_ok_from", ["bot": bot])
    case "takeover": return w("take_over", ["bot": bot])
    default: return w("suggests", ["bot": bot])
    }
  }

  /// The quieter line under it: who, or who suggests.
  func subline(_ w: GlanceWords) -> String {
    if text.isEmpty { return bot }
    if kind == "suggestion" { return w("suggests", ["bot": bot]) }
    // A low-risk approval says so, since it is the one that can be answered right here.
    if kind == "approval" && risk == "low" { return "\(bot) · \(w("low_risk"))" }
    return bot
  }

  var art: BotArt { BotArt(name: bot, avatar: botAvatar) }
}

extension Glance {
  /// Acting buttons run in place on iPhone unless the glance is private (the app lock is on,
  /// §8.4). On the Mac they never do.
  var actsInPlace: Bool { WidgetPlatform.actsInPlace && !flags.isPrivate }

  /// The next thing due, for "All clear" ("Brief at 7:00", "Inbox sweep · 9:00").
  func nextDue(_ w: GlanceWords, at date: Date) -> String {
    let routine = upcoming(at: date).first
    if let b = brief?.nextAt, b > date, b <= (routine?.nextAt ?? .distantFuture) {
      return w("brief_at", ["time": GlanceFormat.when(b, from: date)])
    }
    if let r = routine, let at = r.nextAt {
      return "\(r.name.isEmpty ? r.bot : r.name) · \(GlanceFormat.when(at, from: date))"
    }
    return w("nothing_next")
  }
}

/// A need's buttons (§6.1 A): Allow and Deny on a low-risk approval, Review on any other,
/// Open on a takeover, Do it on a suggestion. Private: each opens the app.
struct NeedButtons: View {
  let need: Glance.Need
  let words: GlanceWords
  let inPlace: Bool
  /// Today shows one button per row.
  var compact = false

  var body: some View {
    HStack(spacing: 6) {
      switch need.kind {
      case "approval":
        if need.risk == "low" && inPlace {
          ActButton(act: .answer(approval: need.id, allow: true)) { CapsuleLabel(title: words("allow"), tone: .needs) }
          if !compact {
            ActButton(act: .answer(approval: need.id, allow: false)) { CapsuleLabel(title: words("deny")) }
          }
        } else {
          ActButton(act: .open("/approvals/\(need.id)")) { CapsuleLabel(title: words("review")) }
        }
      case "takeover":
        ActButton(act: .open(need.link)) { CapsuleLabel(title: words("open")) }
      default:
        if WidgetPlatform.actsInPlace {
          // Private: the accept link opens the app, whose lock asks first.
          ActButton(act: .accept(suggestion: need.id, bot: need.botId), inPlace: inPlace) { CapsuleLabel(title: words("do_it"), tone: .main) }
        } else {
          ActButton(act: .open(need.link)) { CapsuleLabel(title: words("open")) }
        }
      }
    }
  }
}

/// One waiting thing: the bot, one line, its buttons. Tapping the row opens it.
struct NeedRow: View {
  let need: Glance.Need
  let words: GlanceWords
  let inPlace: Bool
  var markSize: CGFloat = 30
  var compact = false
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let p = Palette.of(scheme)
    HStack(spacing: 8) {
      Link(destination: appURL(need.link)) {
        HStack(spacing: 8) {
          BotMarkView(art: need.art, size: markSize)
          VStack(alignment: .leading, spacing: 1) {
            Text(need.line(words)).font(.system(size: 12.5, weight: .semibold)).lineLimit(1)
            if !compact {
              Text(need.subline(words)).font(.system(size: 11)).foregroundStyle(p.fg2).lineLimit(1)
            }
          }
          Spacer(minLength: 0)
        }
      }
      NeedButtons(need: need, words: words, inPlace: inPlace, compact: compact)
    }
    .accessibilityElement(children: .contain)
  }
}

struct Hairline: View {
  @Environment(\.colorScheme) private var scheme
  var body: some View {
    Rectangle().fill(Palette.of(scheme).line).frame(height: 1).padding(.vertical, 8)
  }
}

// MARK: A. Needs you

struct NeedsYouView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    GlanceGate(entry: entry) { g in
      if g.needsCount == 0 {
        allClear(g)
      } else if family == .systemSmall {
        small(g)
      } else {
        medium(g)
      }
    }
    .glanceContainer()
  }

  private var w: GlanceWords { entry.words }

  private func spoken(_ g: Glance) -> String {
    guard let first = g.needs.first else { return "\(w("needs_you")), \(g.needsCount)" }
    return "\(w("needs_you")), \(g.needsCount). \(first.line(w))"
  }

  private func small(_ g: Glance) -> some View {
    let p = Palette.of(scheme)
    let first = g.needs.first
    return VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text("\(g.needsCount)")
          .font(.system(size: 44, weight: .heavy))
          .monospacedDigit()
          .foregroundStyle(p.wait)
          .contentTransition(.numericText())
          .widgetAccentable()
        Spacer(minLength: 4)
        if let first { BotMarkView(art: first.art, size: 30) }
      }
      Text(w("needs_you")).font(.system(size: 15, weight: .bold)).padding(.top, 4)
      Spacer(minLength: 0)
      if let first {
        Text(first.line(w)).font(.system(size: 12)).foregroundStyle(p.fg2).lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    // One thing: open it. Several: the Needs you list.
    .widgetURL(appURL(g.needsCount == 1 ? (first?.link ?? "/bots") : "/bots"))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken(g))
  }

  private func medium(_ g: Glance) -> some View {
    let p = Palette.of(scheme)
    return VStack(alignment: .leading, spacing: 0) {
      HStack {
        Eyebrow(text: "\(w("needs_you")) · \(g.needsCount)", color: p.wait)
        Spacer(minLength: 4)
        AgeLine(entry: entry)
      }
      .padding(.bottom, 8)
      ForEach(Array(g.needs.prefix(2).enumerated()), id: \.element.id) { i, need in
        if i > 0 { Hairline() }
        NeedRow(need: need, words: w, inPlace: g.actsInPlace)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(appURL("/bots"))
    .accessibilityLabel(spoken(g))
  }

  private func allClear(_ g: Glance) -> some View {
    let p = Palette.of(scheme)
    let bot = g.bots.first
    return VStack(alignment: .leading, spacing: 2) {
      if let bot { BotMarkView(art: BotArt(name: bot.name, avatar: bot.avatar), size: family == .systemSmall ? 44 : 36) }
      Spacer(minLength: 0)
      Text(w("all_clear")).font(.system(size: 15, weight: .bold))
      Text(g.nextDue(w, at: entry.date)).font(.system(size: 12)).foregroundStyle(p.fg2).lineLimit(2)
      AgeLine(entry: entry)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(appURL("/bots"))
    .accessibilityElement(children: .combine)
  }
}

// MARK: B. Bot

/// Where a bot stands, in words and colour (§6.1 B).
struct BotState {
  let word: String
  let detail: String?
  let color: Color?

  init(_ bot: Glance.Bot, _ g: Glance, _ w: GlanceWords, at date: Date, palette p: Palette) {
    switch g.status(of: bot, at: date) {
    case "working":
      word = w("working")
      detail = bot.step
      color = p.work
    case "waiting":
      word = w("waiting")
      detail = nil
      color = p.wait
    case "disabled":
      word = w("off")
      detail = nil
      color = nil
    default:
      word = w("idle")
      // When it last replied; once "Working" has gone out of date, when it was last busy.
      let at = bot.status == "working" ? (bot.busyAt ?? bot.lastAt) : (bot.lastAt ?? bot.busyAt)
      detail = at.map { w("replied_at", ["time": GlanceFormat.when($0, from: date)]) }
      color = nil
    }
  }
}

struct BotView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    Group {
      if entry.glance == nil, entry.snap.signedIn, let legacy = entry.snap.legacy {
        legacyView(legacy)
      } else {
        GlanceGate(entry: entry) { g in
          if let bot = pick(g) {
            content(bot, g)
          } else if let chosen = entry.bot {
            // Picked, but not among the bots the glance lists: its face and name only.
            BotHeader(art: BotArt(name: chosen.name, avatar: chosen.avatar), name: chosen.name, state: nil, size: markSize)
              .widgetURL(appURL("/bots/\(chosen.id)/chat"))
          }
        }
      }
    }
    .glanceContainer()
  }

  private var w: GlanceWords { entry.words }
  private var markSize: CGFloat { family == .systemSmall ? 52 : 46 }

  private func pick(_ g: Glance) -> Glance.Bot? {
    guard let id = entry.bot?.id else { return g.bots.first }
    return g.bots.first { $0.id == id }
  }

  @ViewBuilder
  private func content(_ bot: Glance.Bot, _ g: Glance) -> some View {
    let p = Palette.of(scheme)
    let state = BotState(bot, g, w, at: entry.date, palette: p)
    let header = BotHeader(art: BotArt(name: bot.name, avatar: bot.avatar), name: bot.name, state: state, size: markSize)
    let spoken = [bot.name, state.word, state.detail].compactMap { $0 }.joined(separator: ", ")
    if family == .systemSmall {
      header
        .widgetURL(appURL(bot.link))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    } else {
      HStack(alignment: .top, spacing: 14) {
        header.frame(width: 118, alignment: .leading)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(spoken)
        VStack(alignment: .leading, spacing: 6) {
          if let text = bot.lastText, !text.isEmpty, !g.flags.hideReplyText, !g.flags.isPrivate {
            Text(text).font(.system(size: 13)).lineSpacing(1).lineLimit(3)
          }
          Spacer(minLength: 0)
          AgeLine(entry: entry)
          HStack(spacing: 6) {
            ActButton(act: .open(askRoute(bot: bot.id))) { CapsuleLabel(title: w("ask"), symbol: "bubble.left.fill", tone: .main) }
            ActButton(act: .open("/bots/\(bot.id)/call")) { CapsuleLabel(title: w("talk"), symbol: "mic.fill") }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .widgetURL(appURL(bot.link))
    }
  }

  /// A server too old for the glance: the four strings the app wrote before D-405 (§6.6).
  private func legacyView(_ legacy: LegacyBot) -> some View {
    BotHeader(art: BotArt(name: legacy.name, avatar: legacy.avatar), name: legacy.name,
              state: BotState(word: legacy.status), size: markSize)
      .widgetURL(appURL("/quick-ask"))
  }
}

extension BotState {
  init(word: String) {
    self.word = word
    detail = nil
    color = nil
  }
}

/// The bot's face, name and where it stands, as on the small Bot widget.
struct BotHeader: View {
  let art: BotArt
  let name: String
  let state: BotState?
  var size: CGFloat = 52
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let p = Palette.of(scheme)
    VStack(alignment: .leading, spacing: 1) {
      BotMarkView(art: art, size: size)
      Spacer(minLength: 0)
      Text(name).font(.system(size: 15, weight: .bold)).lineLimit(1)
      if let state {
        HStack(spacing: 5) {
          if let c = state.color { Circle().fill(c).frame(width: 8, height: 8).widgetAccentable() }
          Text(state.word).font(.system(size: 12, weight: .semibold)).foregroundStyle(state.color ?? p.fg2)
        }
        .lineLimit(1)
        if let d = state.detail, !d.isEmpty {
          Text(d).font(.system(size: 12)).foregroundStyle(p.fg2).lineLimit(1)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

// MARK: C. Ask

struct AskView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    GlanceGate(entry: entry) { g in
      let bot = pick(g)
      if family == .systemSmall { small(bot) } else { medium(bot, g) }
    }
    .glanceContainer()
  }

  private var w: GlanceWords { entry.words }

  /// The picked bot (by id, name and mark), else the first.
  private func pick(_ g: Glance) -> (id: String, name: String, avatar: String)? {
    if let chosen = entry.bot { return (chosen.id, chosen.name, chosen.avatar) }
    return g.bots.first.map { ($0.id, $0.name, $0.avatar) }
  }

  private func small(_ bot: (id: String, name: String, avatar: String)?) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      if let bot { BotMarkView(art: BotArt(name: bot.name, avatar: bot.avatar), size: 48) }
      Spacer(minLength: 0)
      HStack(alignment: .center) {
        Text(w("ask")).font(.system(size: 19, weight: .bold))
        Spacer(minLength: 4)
        if let bot {
          ActButton(act: .open("/bots/\(bot.id)/call")) { RoundLabel(symbol: "mic.fill", main: true, size: 36) }
            .accessibilityLabel(w("talk"))
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(appURL(askRoute(bot: bot?.id)))
    .accessibilityLabel(w("ask_bot", ["bot": bot?.name ?? "Casama"]))
  }

  private func medium(_ bot: (id: String, name: String, avatar: String)?, _ g: Glance) -> some View {
    let p = Palette.of(scheme)
    let starters = Array(g.starters.prefix(2))
    return VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        Link(destination: appURL(askRoute(bot: bot?.id))) {
          HStack(spacing: 8) {
            if let bot { BotMarkView(art: BotArt(name: bot.name, avatar: bot.avatar), size: 30) }
            Text(w("ask_bot", ["bot": bot?.name ?? "Casama"]))
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(p.fg2)
              .lineLimit(1)
            Spacer(minLength: 0)
          }
        }
        if let bot {
          ActButton(act: .open("/bots/\(bot.id)/call")) { RoundLabel(symbol: "mic.fill", main: true) }
            .accessibilityLabel(w("talk"))
        }
      }
      .padding(.leading, 8)
      .padding(.trailing, 6)
      .padding(.vertical, 6)
      .background(Capsule().fill(p.fill))
      Spacer(minLength: 0)
      if !starters.isEmpty {
        Eyebrow(text: w("try")).padding(.bottom, 6)
        HStack(spacing: 8) {
          ForEach(Array(starters.enumerated()), id: \.offset) { _, s in
            Link(destination: appURL(askRoute(bot: bot?.id, text: s.text))) {
              Text("\(s.emoji) \(s.text)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(p.primary)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.primaryBg))
            }
          }
          Spacer(minLength: 0)
        }
      } else if let b = bot.flatMap({ chosen in g.bots.first { $0.id == chosen.id } }) {
        // No starters yet: where the bot stands, so this is never a plain launcher.
        let state = BotState(b, g, w, at: entry.date, palette: p)
        Text([state.word, state.detail].compactMap { $0 }.joined(separator: " · "))
          .font(.system(size: 12)).foregroundStyle(state.color ?? p.fg2).lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

// MARK: D. Routines

/// A routine as a row shows it: from the glance when it lists it, else from what was picked.
struct RoutineItem: Identifiable {
  let id: String
  let botId: String
  let name: String
  let bot: String
  let every: String
  let nextAt: Date?
  let link: String
}

struct RoutinesView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    GlanceGate(entry: entry) { g in
      let items = Self.items(entry, g)
      if items.isEmpty {
        MessageView(text: w("no_routines"), mascot: "sleepy", route: g.bots.first.map { "/bots/\($0.id)/routines" } ?? "/bots")
      } else if family == .systemSmall {
        small(items[0], g)
      } else {
        medium(Array(items.prefix(3)), g)
      }
    }
    .glanceContainer()
  }

  private var w: GlanceWords { entry.words }

  static func items(_ entry: GlanceEntry, _ g: Glance) -> [RoutineItem] {
    if !entry.routines.isEmpty {
      return entry.routines.map { picked in
        if let r = g.next.first(where: { $0.id == picked.id }) {
          return RoutineItem(id: r.id, botId: r.botId, name: r.name, bot: r.bot, every: r.every, nextAt: r.nextAt.flatMap { $0 > entry.date ? $0 : nil }, link: r.link)
        }
        return RoutineItem(id: picked.id, botId: picked.botId, name: picked.name, bot: picked.bot, every: "", nextAt: nil, link: "/bots/\(picked.botId)/routines")
      }
    }
    return g.upcoming(at: entry.date).map {
      RoutineItem(id: $0.id, botId: $0.botId, name: $0.name, bot: $0.bot, every: $0.every, nextAt: $0.nextAt, link: $0.link)
    }
  }

  private func when(_ r: RoutineItem) -> String { r.nextAt.map { GlanceFormat.when($0, from: entry.date) } ?? "–" }

  private func spoken(_ r: RoutineItem) -> String {
    [w("up_next"), when(r), r.name, r.bot].filter { !$0.isEmpty }.joined(separator: ", ")
  }

  /// Run now, or Started for a few minutes after it was pressed.
  @ViewBuilder
  private func runButton(_ r: RoutineItem, _ g: Glance, size: CGFloat = 30) -> some View {
    if let at = entry.snap.started[r.id], entry.date.timeIntervalSince(at) < 5 * 60 {
      CapsuleLabel(title: w("started"))
    } else {
      ActButton(act: .runRoutine(routine: r.id, bot: r.botId), inPlace: g.actsInPlace) {
        RoundLabel(symbol: "play.fill", size: size)
      }
      .accessibilityLabel("\(w("run_now")), \(r.name)")
    }
  }

  private func small(_ r: RoutineItem, _ g: Glance) -> some View {
    let p = Palette.of(scheme)
    return VStack(alignment: .leading, spacing: 2) {
      Eyebrow(text: w("up_next"))
      Spacer(minLength: 0)
      Text(when(r)).font(.system(size: 24, weight: .heavy)).monospacedDigit().widgetAccentable()
      Text(r.name.isEmpty ? r.bot : r.name).font(.system(size: 14, weight: .semibold)).lineLimit(1)
      HStack(alignment: .bottom) {
        Text(r.name.isEmpty ? r.every : r.bot).font(.system(size: 11)).foregroundStyle(p.fg2).lineLimit(1)
        Spacer(minLength: 4)
        runButton(r, g, size: 34)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(appURL(r.link))
    .accessibilityElement(children: .contain)
    .accessibilityLabel(spoken(r))
  }

  private func medium(_ items: [RoutineItem], _ g: Glance) -> some View {
    let p = Palette.of(scheme)
    return VStack(alignment: .leading, spacing: 8) {
      Eyebrow(text: w("up_next"))
      ForEach(items) { r in
        HStack(spacing: 8) {
          Link(destination: appURL(r.link)) {
            HStack(spacing: 8) {
              Text(when(r)).font(.system(size: 12.5, weight: .bold)).monospacedDigit().frame(width: 46, alignment: .leading)
              VStack(alignment: .leading, spacing: 1) {
                Text(r.name.isEmpty ? r.bot : r.name).font(.system(size: 12.5, weight: .semibold)).lineLimit(1)
                Text([r.bot, r.every].filter { !$0.isEmpty }.joined(separator: " · "))
                  .font(.system(size: 11)).foregroundStyle(p.fg2).lineLimit(1)
              }
              Spacer(minLength: 0)
            }
          }
          .accessibilityLabel(spoken(r))
          runButton(r, g)
        }
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
