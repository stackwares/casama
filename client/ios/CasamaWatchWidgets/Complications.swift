import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Complications and Smart Stack cards (§6.3, mockups "Complications")
//
// Words the person wrote are privacySensitive: the system hides them when the watch is locked or
// in Always On with "Hide sensitive complications" on. A private workspace (flags.private) shows
// counts only. On a tinted face the accent parts take the tint and the mascots lose their colour.

private extension GlanceEntry {
  var hideWords: Bool { glance?.flags.isPrivate ?? false }
  /// Signed in, with a saved copy too old to draw as now (the watch couldn't refresh it).
  var dated: Bool { signedIn && glance != nil && isStale }
  var needsLine: String {
    guard let g = glance else { return WatchL10n.needsYou }
    return g.needsCount == 1 ? WatchL10n.needsYouOne : WatchL10n.needsYouMany("\(g.needsCount)")
  }
}

private func link(_ entry: GlanceEntry, _ target: WatchLink) -> URL? {
  (entry.signedIn ? target : .now).url
}

/// The Casama mark for signed-out and empty states.
private struct CasamaMark: View {
  var size: CGFloat = 26
  var body: some View { MascotView(name: "winky", size: size) }
}

// MARK: Inline: "Casama", or what matters most

struct InlineView: View {
  let entry: GlanceEntry
  var body: some View {
    Group {
      if !entry.signedIn || entry.glance == nil || entry.dated {
        Text(WatchL10n.compCasama)
      } else if let g = entry.glance, g.needsCount > 0 {
        Label(entry.needsLine, systemImage: "exclamationmark.circle.fill")
      } else if let run = entry.glance?.liveRuns.first {
        Label(WatchL10n.isWorking(run.bot), systemImage: "sparkles")
      } else if let next = entry.glance?.nextRoutine, let at = next.nextAt {
        Label("\(next.name) \(WatchTime.upcoming(at, now: entry.date))", systemImage: "clock")
      } else {
        Text(WatchL10n.compCasama)
      }
    }
    .widgetURL(link(entry, .now))
  }
}

// MARK: Needs you

struct NeedsCircularView: View {
  let entry: GlanceEntry
  var body: some View {
    let count = entry.glance?.needsCount ?? 0
    ZStack {
      AccessoryWidgetBackground()
      if !entry.signedIn || entry.dated {
        CasamaMark(size: 30)
      } else if count > 0 {
        VStack(spacing: -2) {
          Text("\(count)")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(WatchTheme.amber)
            .widgetAccentable()
          Text(WatchL10n.needYouShort)
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
      } else {
        Image(systemName: "checkmark")
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(WatchTheme.green)
          .widgetAccentable()
      }
    }
    .widgetURL(link(entry, count > 0 ? .needs : .now))
    .accessibilityLabel(entry.dated ? (entry.asOf ?? WatchL10n.compCasama) : (count > 0 ? entry.needsLine : WatchL10n.allClear))
  }
}

struct NeedsCornerView: View {
  let entry: GlanceEntry
  var body: some View {
    let count = entry.glance?.needsCount ?? 0
    Image(systemName: entry.dated ? "bubble.fill" : (count > 0 ? "exclamationmark.bubble.fill" : "checkmark.bubble.fill"))
      .font(.system(size: 20, weight: .semibold))
      .foregroundStyle(entry.dated ? WatchTheme.secondary : (count > 0 ? WatchTheme.amber : WatchTheme.green))
      .widgetAccentable()
      .widgetLabel {
        if entry.dated {
          Text(entry.asOf ?? WatchL10n.compCasama)
        } else {
          Text(entry.signedIn ? (count > 0 ? entry.needsLine : WatchL10n.allClear) : WatchL10n.compCasama)
        }
      }
      .widgetURL(link(entry, count > 0 ? .needs : .now))
  }
}

struct NeedsRectView: View {
  let entry: GlanceEntry
  var body: some View {
    let g = entry.glance
    let first = g?.needs.first
    VStack(alignment: .leading, spacing: 2) {
      if !entry.signedIn {
        Text(WatchL10n.compCasama).font(.headline).widgetAccentable()
        Text(WatchL10n.openToSignIn).font(.caption2).foregroundStyle(.secondary)
      } else if let g, entry.dated {
        // Couldn't be refreshed for a while: what was last known, said as old, with no button.
        Text(g.needsCount > 0 ? "\(WatchL10n.needsYou.uppercased()) · \(g.needsCount)" : WatchL10n.compCasama)
          .font(.system(.caption2, design: .rounded).weight(.heavy))
          .foregroundStyle(.secondary)
        if let asOf = entry.asOf { Text(asOf).font(.caption2).foregroundStyle(.secondary) }
      } else if let g, g.needsCount > 0 {
        Text("\(WatchL10n.needsYou.uppercased()) · \(g.needsCount)")
          .font(.system(.caption2, design: .rounded).weight(.heavy))
          .foregroundStyle(WatchTheme.amber)
          .widgetAccentable()
        if let first {
          HStack(spacing: 4) {
            BotMarkView(name: first.bot, avatar: first.botAvatar, size: 16)
            Text(first.bot).font(.caption2.weight(.semibold)).lineLimit(1)
          }
          if !entry.hideWords {
            Text(first.text).font(.caption2).lineLimit(1).privacySensitive()
          }
          // Allow in place only for what a tap may allow: low risk, and the person's watches set
          // to allow at all. AllowRequestIntent still asks the server first. A medium-risk request
          // needs a hold and a high-risk one the phone, so those say Review: a tap opens the request.
          if first.kind == "approval", g.needsCount == 1 {
            if first.risk == .low, GlanceCache.me()?.prefs?.allow != "none" {
              Button(intent: AllowRequestIntent(approvalId: first.id)) {
                Text(WatchL10n.allow).font(.caption2.weight(.semibold))
              }
              .tint(WatchTheme.amber)
            } else {
              Text(WatchL10n.review)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WatchTheme.amber)
                .widgetAccentable()
            }
          }
        }
      } else {
        HStack(spacing: 6) {
          MascotView(name: "sleepy", size: 26)
          VStack(alignment: .leading, spacing: 0) {
            Text(WatchL10n.allClear).font(.headline)
            Text(WatchL10n.nothingWaiting).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(link(entry, first.map { $0.kind == "approval" ? .approval($0.id) : .needs } ?? .now))
  }
}

// MARK: Ask

struct AskCircularView: View {
  let entry: GlanceEntry
  var body: some View {
    let bot = entry.bot
    ZStack {
      AccessoryWidgetBackground()
      if let bot {
        BotMarkView(name: bot.name, avatar: bot.avatar, size: 30)
        Image(systemName: "mic.fill")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(WatchTheme.onOrchid)
          .padding(3)
          .background(Circle().fill(WatchTheme.orchid))
          .widgetAccentable()
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
      } else {
        Image(systemName: "mic.fill").font(.system(size: 20, weight: .semibold)).widgetAccentable()
      }
    }
    .widgetURL(link(entry, .ask(bot: bot?.id)))
    .accessibilityLabel(bot.map { WatchL10n.askBot($0.name) } ?? WatchL10n.ask)
  }
}

// MARK: Credits

struct CreditsCircularView: View {
  let entry: GlanceEntry
  var body: some View {
    let c = entry.glance?.credits
    Group {
      if let c, c.billing, !c.unlimited, let used = c.usedShare {
        Gauge(value: 1 - used) {
          Image(systemName: "bolt.fill")
        } currentValueLabel: {
          Text("\(Int(((1 - used) * 100).rounded()))")
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(used > 0.9 ? WatchTheme.red : WatchTheme.green)
      } else {
        ZStack {
          AccessoryWidgetBackground()
          Image(systemName: c?.unlimited == true ? "infinity" : "bolt.fill").font(.system(size: 18, weight: .semibold))
        }
      }
    }
    .widgetAccentable()
    .widgetURL(link(entry, .settings))
    .accessibilityLabel(WatchL10n.credits)
  }
}

// MARK: A bot

struct BotRectView: View {
  let entry: GlanceEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      if let bot = entry.bot, entry.signedIn {
        HStack(spacing: 5) {
          BotMarkView(name: bot.name, avatar: bot.avatar, size: 18)
          Text(bot.name).font(.headline).lineLimit(1).widgetAccentable()
        }
        switch bot.status {
        case .working where entry.dated, .waiting where entry.dated:
          // Working or waiting when last seen, a while ago: not said as if it were now.
          Text(entry.asOf ?? WatchL10n.idle).font(.caption2).foregroundStyle(.secondary)
        case .working:
          Text(WatchL10n.working).font(.caption2.weight(.semibold)).foregroundStyle(WatchTheme.green)
          if let step = bot.step, !entry.hideWords { Text(step).font(.caption2).lineLimit(1).privacySensitive() }
        case .waiting:
          Text(WatchL10n.waitingForYou).font(.caption2.weight(.semibold)).foregroundStyle(WatchTheme.amber)
        case .disabled:
          Text(WatchL10n.off).font(.caption2).foregroundStyle(.secondary)
        case .idle:
          if let last = bot.lastText, !entry.hideWords {
            Text(last).font(.caption2).lineLimit(2).privacySensitive()
          } else {
            Text(WatchL10n.idle).font(.caption2).foregroundStyle(.secondary)
          }
        }
      } else {
        Text(WatchL10n.compCasama).font(.headline).widgetAccentable()
        Text(entry.signedIn ? WatchL10n.noBots : WatchL10n.openToSignIn).font(.caption2).foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(link(entry, entry.bot.map { .chat(bot: $0.id, conversation: nil) } ?? .bots))
  }
}

// MARK: Up next, with a countdown inside the hour

struct UpNextRectView: View {
  let entry: GlanceEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(WatchL10n.upNext.uppercased())
        .font(.system(.caption2, design: .rounded).weight(.heavy))
        .foregroundStyle(.secondary)
      if let next = entry.glance?.nextRoutine, let at = next.nextAt, entry.signedIn {
        Text(next.name).font(.headline).lineLimit(1).widgetAccentable()
        HStack(spacing: 4) {
          BotMarkView(name: next.bot, avatar: next.botAvatar, size: 14)
          if at > entry.date && at.timeIntervalSince(entry.date) < 3600 {
            Text(timerInterval: entry.date...at, countsDown: true)
              .font(.caption2.monospacedDigit())
          } else {
            Text(WatchTime.upcoming(at, now: entry.date)).font(.caption2)
          }
        }
      } else {
        Text(entry.signedIn ? WatchL10n.noRoutines : WatchL10n.openToSignIn).font(.caption2).foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(link(entry, .upNext))
  }
}

// MARK: Working

struct WorkingRectView: View {
  let entry: GlanceEntry
  var body: some View {
    // A dated copy can't say who is working now: the neutral card, with how old it is.
    let run = entry.dated ? nil : entry.glance?.liveRuns.first
    VStack(alignment: .leading, spacing: 2) {
      if let run, entry.signedIn {
        HStack(spacing: 5) {
          BotMarkView(name: run.bot, avatar: run.botAvatar, size: 18)
          Text(WatchL10n.isWorking(run.bot)).font(.caption.weight(.semibold)).lineLimit(1).widgetAccentable()
        }
        if !run.step.isEmpty, !entry.hideWords { Text(run.step).font(.caption2).lineLimit(1).privacySensitive() }
        if let start = run.startedAt {
          Text(timerInterval: start...Date.distantFuture, countsDown: false)
            .font(.caption2.monospacedDigit())
            .foregroundStyle(WatchTheme.green)
        }
      } else {
        Text(WatchL10n.compCasama).font(.headline).widgetAccentable()
        Text(entry.dated ? (entry.asOf ?? WatchL10n.allClear) : (entry.signedIn ? WatchL10n.allClear : WatchL10n.openToSignIn))
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(link(entry, run.map { .run($0.id) } ?? .now))
  }
}

// MARK: Brief

struct BriefRectView: View {
  let entry: GlanceEntry
  var body: some View {
    let brief = entry.glance?.brief
    VStack(alignment: .leading, spacing: 2) {
      Text(WatchL10n.brief.uppercased())
        .font(.system(.caption2, design: .rounded).weight(.heavy))
        .foregroundStyle(.secondary)
      if let brief, entry.signedIn {
        if let text = brief.text, !entry.hideWords {
          Text(text).font(.caption2).lineLimit(3).privacySensitive()
        } else if let next = brief.nextAt {
          Text(WatchTime.briefLine(next, now: entry.date)).font(.caption2)
        } else {
          Text(WatchL10n.noBrief).font(.caption2).foregroundStyle(.secondary)
        }
      } else {
        Text(entry.signedIn ? WatchL10n.noBrief : WatchL10n.openToSignIn).font(.caption2).foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(link(entry, .brief))
  }
}

// MARK: - The widgets

struct WatchInlineWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WatchSync.Kind.inline, provider: GlanceProvider()) { InlineView(entry: $0) }
      .configurationDisplayName(WatchL10n.compCasama)
      .description(WatchL10n.compDescNeedsYou)
      .supportedFamilies([.accessoryInline])
  }
}

struct WatchNeedsCircularWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WatchSync.Kind.needsCircular, provider: GlanceProvider(relevanceKind: .needs)) { NeedsCircularView(entry: $0) }
      .configurationDisplayName(WatchL10n.compNeedsYou)
      .description(WatchL10n.compDescNeedsYou)
      .supportedFamilies([.accessoryCircular])
  }
}

struct WatchNeedsCornerWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WatchSync.Kind.needsCorner, provider: GlanceProvider(relevanceKind: .needs)) { NeedsCornerView(entry: $0) }
      .configurationDisplayName(WatchL10n.compNeedsYou)
      .description(WatchL10n.compDescNeedsYou)
      .supportedFamilies([.accessoryCorner])
  }
}

struct WatchNeedsRectWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WatchSync.Kind.needsRect, provider: GlanceProvider(relevanceKind: .needs)) { NeedsRectView(entry: $0) }
      .configurationDisplayName(WatchL10n.compNeedsYou)
      .description(WatchL10n.compDescNeedsYou)
      .supportedFamilies([.accessoryRectangular])
  }
}

struct WatchAskWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: WatchSync.Kind.ask, intent: ChooseWatchBotIntent.self, provider: BotProvider()) { AskCircularView(entry: $0) }
      .configurationDisplayName(WatchL10n.compAsk)
      .description(WatchL10n.compDescAsk)
      .supportedFamilies([.accessoryCircular])
  }
}

struct WatchCreditsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WatchSync.Kind.credits, provider: GlanceProvider()) { CreditsCircularView(entry: $0) }
      .configurationDisplayName(WatchL10n.credits)
      .description(WatchL10n.compDescCredits)
      .supportedFamilies([.accessoryCircular])
  }
}

struct WatchBotWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: WatchSync.Kind.bot, intent: ChooseWatchBotIntent.self, provider: BotProvider()) { BotRectView(entry: $0) }
      .configurationDisplayName(WatchL10n.compBot)
      .description(WatchL10n.compDescBot)
      .supportedFamilies([.accessoryRectangular])
  }
}

struct WatchUpNextWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WatchSync.Kind.upNext, provider: GlanceProvider(relevanceKind: .upNext)) { UpNextRectView(entry: $0) }
      .configurationDisplayName(WatchL10n.compUpNext)
      .description(WatchL10n.compDescUpNext)
      .supportedFamilies([.accessoryRectangular])
  }
}

struct WatchWorkingWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WatchSync.Kind.working, provider: GlanceProvider(relevanceKind: .working)) { WorkingRectView(entry: $0) }
      .configurationDisplayName(WatchL10n.working)
      .description(WatchL10n.compDescWorking)
      .supportedFamilies([.accessoryRectangular])
  }
}

struct WatchBriefWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WatchSync.Kind.brief, provider: GlanceProvider(relevanceKind: .brief)) { BriefRectView(entry: $0) }
      .configurationDisplayName(WatchL10n.brief)
      .description(WatchL10n.compDescBrief)
      .supportedFamilies([.accessoryRectangular])
  }
}
