import SwiftUI
import WidgetKit

// MARK: - Today, Brief, Library, Tasks and Credits (D-405 §6.1 E–I)
//
// Shared by the iPhone and Mac widget extensions.

// MARK: E. Today

struct TodayView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    GlanceGate(entry: entry) { g in
      layout(g)
    }
    .glanceContainer()
  }

  private var w: GlanceWords { entry.words }

  private var isPortrait: Bool {
    #if os(iOS) || os(macOS)
    if #available(iOS 27.0, macOS 27.0, *) { return family == .systemExtraLargePortrait }
    #endif
    return false
  }

  @ViewBuilder
  private func layout(_ g: Glance) -> some View {
    if family == .systemExtraLarge {
      HStack(alignment: .top, spacing: 18) {
        main(g)
        VStack(alignment: .leading, spacing: 0) {
          briefBlock(g, lines: 8)
          Hairline()
          strip(g, count: 3)
          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
    } else if isPortrait {
      VStack(alignment: .leading, spacing: 0) {
        main(g)
        Hairline()
        briefBlock(g, lines: 5)
        Hairline()
        strip(g, count: 3)
      }
    } else {
      main(g)
    }
  }

  /// The large widget: the date and credits; Needs you; Up next; the last thing finished; Ask.
  private func main(_ g: Glance) -> some View {
    let p = Palette.of(scheme)
    let soon = Array(g.upcoming(at: entry.date).prefix(2))
    return VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: 6) {
        VStack(alignment: .leading, spacing: 0) {
          Eyebrow(text: entry.date.formatted(.dateTime.weekday(.wide).day()))
          Text(w("today")).font(.system(size: 19, weight: .bold))
        }
        Spacer(minLength: 4)
        if let share = g.credits.usedShare, g.credits.billing, !g.credits.unlimited {
          CreditsRing(share: share, size: 26, showsLabel: false)
          Text(w("used_pct", ["n": GlanceFormat.percent(share)])).font(.system(size: 12)).foregroundStyle(p.fg2)
        }
      }
      Hairline()
      if g.needsCount > 0 {
        Eyebrow(text: "\(w("needs_you")) · \(g.needsCount)", color: p.wait).padding(.bottom, 7)
        VStack(alignment: .leading, spacing: 8) {
          ForEach(Array(g.needs.prefix(2))) { need in
            NeedRow(need: need, words: w, inPlace: g.actsInPlace, markSize: 22, compact: true)
          }
        }
      } else {
        HStack(spacing: 6) {
          Text(w("all_clear")).font(.system(size: 13, weight: .semibold))
          Text(g.nextDue(w, at: entry.date)).font(.system(size: 12)).foregroundStyle(p.fg2).lineLimit(1)
        }
      }
      Hairline()
      Eyebrow(text: w("up_next")).padding(.bottom, 7)
      if soon.isEmpty {
        Text(w("nothing_next")).font(.system(size: 12)).foregroundStyle(p.fg2)
      } else {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(soon) { r in
            Link(destination: appURL(r.link)) {
              HStack(spacing: 8) {
                Text(r.nextAt.map { GlanceFormat.when($0, from: entry.date) } ?? "–")
                  .font(.system(size: 12.5, weight: .bold)).monospacedDigit().frame(width: 46, alignment: .leading)
                Text([r.name, r.bot].filter { !$0.isEmpty }.joined(separator: " · "))
                  .font(.system(size: 12.5, weight: .semibold)).lineLimit(1)
                Spacer(minLength: 0)
              }
            }
          }
        }
      }
      if let done = g.lately.first {
        Hairline()
        Link(destination: appURL(done.link)) {
          HStack(spacing: 8) {
            BotMarkView(art: BotArt(name: done.bot, avatar: done.botAvatar), size: 20)
            Text(w("finished", ["bot": done.bot, "title": done.title]) + " · " + GlanceFormat.when(done.at, from: entry.date))
              .font(.system(size: 11.5)).foregroundStyle(p.fg2).lineLimit(1)
            Spacer(minLength: 0)
          }
        }
      }
      Spacer(minLength: 8)
      AskPill(words: w, bot: g.bots.first)
      AgeLine(entry: entry).padding(.top, 4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private func briefBlock(_ g: Glance, lines: Int) -> some View {
    BriefBody(entry: entry, glance: g, lines: lines)
  }

  private func strip(_ g: Glance, count: Int) -> some View {
    HStack(spacing: 8) {
      ForEach(Array(g.recent.prefix(count))) { c in
        Link(destination: appURL(c.link)) {
          CreationTile(creation: c, cover: entry.covers[c.id], words: w)
        }
      }
      Spacer(minLength: 0)
    }
    .frame(maxHeight: 110)
  }
}

/// An ask field that opens quick ask, with the microphone that starts a call.
struct AskPill: View {
  let words: GlanceWords
  let bot: Glance.Bot?
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let p = Palette.of(scheme)
    HStack(spacing: 8) {
      Link(destination: appURL(askRoute(bot: bot?.id))) {
        HStack {
          Text(words("ask_bot", ["bot": bot?.name ?? "Casama"]))
            .font(.system(size: 13, weight: .medium)).foregroundStyle(p.fg2).lineLimit(1)
          Spacer(minLength: 0)
        }
      }
      if let bot {
        ActButton(act: .open("/bots/\(bot.id)/call")) { RoundLabel(symbol: "mic.fill", main: true) }
          .accessibilityLabel(words("talk"))
      }
    }
    .padding(.leading, 14)
    .padding(.trailing, 6)
    .padding(.vertical, 6)
    .background(Capsule().fill(p.fill))
  }
}

// MARK: F. Brief

/// The brief's text with its bot and time, or when the next one comes.
struct BriefBody: View {
  let entry: GlanceEntry
  let glance: Glance
  var lines = 4
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let p = Palette.of(scheme)
    let w = entry.words
    VStack(alignment: .leading, spacing: 7) {
      HStack {
        Eyebrow(text: w("brief"), color: p.primary)
        Spacer(minLength: 4)
        if let b = glance.brief {
          Text([b.bot, b.at.map { GlanceFormat.when($0, from: entry.date) }].compactMap { $0 }.joined(separator: " · "))
            .font(.system(size: 12)).foregroundStyle(p.fg2).lineLimit(1)
        }
      }
      if let b = glance.brief, let text = b.text, !text.isEmpty {
        Text(text).font(.system(size: 13)).lineSpacing(2).lineLimit(lines)
      } else if let b = glance.brief, let next = b.nextAt {
        HStack(spacing: 8) {
          BotMarkView(art: BotArt(name: b.bot, avatar: b.botAvatar), size: 28)
          Text(w("brief_at", ["time": GlanceFormat.when(next, from: entry.date)])).font(.system(size: 13, weight: .semibold))
        }
      } else {
        Text(w("no_brief")).font(.system(size: 13)).foregroundStyle(p.fg2)
      }
    }
  }
}

struct BriefView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    GlanceGate(entry: entry) { g in
      VStack(alignment: .leading, spacing: 0) {
        BriefBody(entry: entry, glance: g, lines: family == .systemLarge ? 14 : 4)
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .widgetURL(appURL(g.brief?.link ?? "/bots"))
    }
    .glanceContainer()
  }
}

// MARK: G. Library

/// A creation's tile: its cover when the widget has fetched one, else a tile in its kind's
/// colour with a symbol.
struct CreationTile: View {
  let creation: Glance.Creation
  let cover: URL?
  let words: GlanceWords
  var showsTitle = true

  static func symbol(_ kind: String) -> String {
    switch kind {
    case "page": return "doc.richtext"
    case "image": return "photo"
    case "video": return "play.rectangle.fill"
    case "audio": return "waveform"
    case "document": return "doc.text"
    default: return "doc"
    }
  }

  static func colors(_ kind: String) -> [Color] {
    switch kind {
    case "page": return [Color(hex: 0x8B5CF6), Color(hex: 0xA78BFA)]
    case "image": return [Color(hex: 0x7A90FF), Color(hex: 0x7DE9F4)]
    case "video": return [Color(hex: 0xFF6FAE), Color(hex: 0xFF9CC9)]
    case "audio": return [Color(hex: 0xFF9F43), Color(hex: 0xFFC94D)]
    case "document": return [Color(hex: 0x14B8A6), Color(hex: 0x4FD1C5)]
    default: return [Color(hex: 0x6B7280), Color(hex: 0x9CA3AF)]
    }
  }

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      CoverFill(creation: creation, cover: cover)
      if showsTitle && !creation.title.isEmpty {
        LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
        Text(creation.title)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(.white)
          .lineLimit(2)
          .padding(7)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(creation.title.isEmpty ? words("library") : creation.title)
  }
}

/// The cover, filling its box, or the kind's colour and symbol.
struct CoverFill: View {
  let creation: Glance.Creation
  let cover: URL?

  var body: some View {
    if let cover, let image = GlanceFetch.coverImage(cover) {
      Image(decorative: image, scale: 1)
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    } else {
      LinearGradient(colors: CreationTile.colors(creation.kind), startPoint: .topLeading, endPoint: .bottomTrailing)
        .overlay(
          Image(systemName: CreationTile.symbol(creation.kind))
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
        )
    }
  }
}

struct LibraryView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    if family == .systemSmall, let g = entry.glance, entry.snap.signedIn, let c = g.recent.first {
      small(c)
    } else {
      GlanceGate(entry: entry, needsBots: false) { g in
        if g.recent.isEmpty {
          MessageView(text: entry.words("no_creations"), mascot: "starry", route: "/library")
        } else {
          grid(g)
        }
      }
      .glanceContainer()
    }
  }

  /// The newest creation, its cover filling the widget.
  private func small(_ c: Glance.Creation) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      Spacer(minLength: 0)
      Text(c.title).font(.system(size: 15, weight: .bold)).lineLimit(2)
      if let bot = c.bot { Text(bot).font(.system(size: 12)).opacity(0.9).lineLimit(1) }
    }
    .foregroundStyle(.white)
    .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    .fontDesign(.rounded)
    .widgetURL(appURL(c.link))
    .containerBackground(for: .widget) {
      ZStack {
        CoverFill(creation: c, cover: entry.covers[c.id])
        LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .center, endPoint: .bottom)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel([entry.words("library"), c.title, c.bot ?? ""].filter { !$0.isEmpty }.joined(separator: ", "))
  }

  private func grid(_ g: Glance) -> some View {
    let count = family == .systemLarge ? 6 : 3
    let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    return VStack(alignment: .leading, spacing: 8) {
      Eyebrow(text: entry.words("library"))
      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(Array(g.recent.prefix(count))) { c in
          Link(destination: appURL(c.link)) {
            CreationTile(creation: c, cover: entry.covers[c.id], words: entry.words)
              .frame(height: family == .systemLarge ? 128 : 104)
          }
        }
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(appURL("/library"))
  }
}

// MARK: H. Tasks

struct TasksView: View {
  let entry: GlanceEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    GlanceGate(entry: entry, needsBots: false) { g in
      content(g)
    }
    .glanceContainer()
  }

  private var w: GlanceWords { entry.words }

  private func content(_ g: Glance) -> some View {
    let p = Palette.of(scheme)
    let c = g.taskCounts
    // In review first: those wait on a person.
    let rows = g.tasks.sorted { ($0.status == "in_review" ? 0 : 1) < ($1.status == "in_review" ? 0 : 1) }
    let spoken = "\(w("tasks")): \(w("todo")) \(c.todo), \(w("in_progress")) \(c.inProgress), \(w("in_review")) \(c.inReview), \(w("blocked")) \(c.blocked)"
    return VStack(alignment: .leading, spacing: 8) {
      Eyebrow(text: w("tasks"))
      HStack(spacing: 6) {
        TaskCount(n: c.todo, label: w("todo"), color: nil)
        TaskCount(n: c.inProgress, label: w("in_progress"), color: nil)
        TaskCount(n: c.inReview, label: w("in_review"), color: c.inReview > 0 ? p.wait : nil)
        TaskCount(n: c.blocked, label: w("blocked"), color: nil)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(spoken)
      if !rows.isEmpty {
        Hairline().padding(.vertical, -4)
        ForEach(Array(rows.prefix(family == .systemLarge ? 3 : 1))) { t in
          Link(destination: appURL(t.link)) {
            HStack(spacing: 8) {
              Circle().fill(t.status == "in_review" ? p.wait : p.fg2.opacity(0.5)).frame(width: 7, height: 7)
              Text(t.title).font(.system(size: 12.5, weight: .semibold)).lineLimit(1)
              Spacer(minLength: 4)
              if let bot = t.bot { Text(bot).font(.system(size: 11)).foregroundStyle(p.fg2).lineLimit(1) }
            }
          }
        }
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(appURL("/tasks"))
  }
}

struct TaskCount: View {
  let n: Int
  let label: String
  let color: Color?
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let p = Palette.of(scheme)
    VStack(alignment: .leading, spacing: 0) {
      Text("\(n)")
        .font(.system(size: 22, weight: .heavy))
        .monospacedDigit()
        .foregroundStyle(color ?? p.fg)
        .contentTransition(.numericText())
        .widgetAccentable()
      Text(label).font(.system(size: 11)).foregroundStyle(p.fg2).lineLimit(1).minimumScaleFactor(0.85)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: I. Credits

/// What the credits widget says, from the glance (§6.1 I).
struct CreditsSummary {
  /// The share used: of the period, or of today's cap on the Free plan; nil with billing off.
  let share: Double?
  let headline: String
  let detail: String

  init(_ c: Glance.Credits, _ w: GlanceWords, at date: Date) {
    let today = w("spent_today", ["amount": GlanceFormat.money(c.todayUsd)])
    if !c.billing || c.unlimited {
      // A self-hosted server with billing off: today's and this month's spend.
      share = nil
      headline = today
      detail = "\(w("this_month")) \(GlanceFormat.money(c.monthUsd))"
    } else if let cap = c.dailyCapUsd, cap > 0 {
      share = min(1, (c.dailyUsedUsd ?? c.todayUsd) / cap)
      headline = w("credits_left", ["amount": GlanceFormat.money(max(0, cap - (c.dailyUsedUsd ?? c.todayUsd)))])
      detail = c.resetsAt.map { w("resets_at", ["time": GlanceFormat.when($0, from: date)]) } ?? today
    } else {
      share = c.usedShare
      headline = c.leftUsd.map { w("credits_left", ["amount": GlanceFormat.money($0)]) } ?? today
      detail = today
    }
  }
}

struct CreditsView: View {
  let entry: GlanceEntry
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    GlanceGate(entry: entry, needsBots: false) { g in
      content(g)
    }
    .glanceContainer()
  }

  private func content(_ g: Glance) -> some View {
    let p = Palette.of(scheme)
    let s = CreditsSummary(g.credits, entry.words, at: entry.date)
    return VStack(alignment: .leading, spacing: 1) {
      if let share = s.share {
        CreditsRing(share: share)
      } else {
        Eyebrow(text: entry.words("credits"))
      }
      Spacer(minLength: 0)
      Text(s.headline).font(.system(size: 15, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
      Text(s.detail).font(.system(size: 12)).foregroundStyle(p.fg2).lineLimit(1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(appURL("/settings/usage"))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel([entry.words("credits"), s.share.map { entry.words("used_pct", ["n": GlanceFormat.percent($0)]) }, s.headline, s.detail]
      .compactMap { $0 }.joined(separator: ", "))
  }
}
