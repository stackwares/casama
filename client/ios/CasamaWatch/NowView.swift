import SwiftUI

// MARK: - Now (§6.1 A, mockup "Now")
//
// What needs the person, what is working, what is next, the brief. Drawn from the saved glance at
// once and refreshed behind it: no spinner. Offline it greys the live colours and says how old it
// is. At the largest text sizes it keeps the first of each and drops the rest (§6.9).

struct NowView: View {
  @EnvironmentObject private var model: AppModel
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.hideWords) private var hideWords

  private var big: Bool { typeSize.isAccessibilitySize }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        if !model.online {
          DatedBanner(savedAt: model.savedAt)
        }
        if let glance = model.glance {
          content(glance)
        } else {
          placeholder
        }
        if !model.queue.isEmpty {
          Label(WatchL10n.keptOffline, systemImage: "tray.and.arrow.up")
            .font(.watchCaption)
            .foregroundStyle(WatchTheme.secondary)
        }
        Button { model.path.append(.settings) } label: {
          Label(WatchL10n.settings, systemImage: "gearshape")
            .font(.watchCaption)
            .foregroundStyle(WatchTheme.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
      }
      .padding(.horizontal, 2)
    }
    .navigationTitle(WatchL10n.now)
    .refreshable { await model.refreshNow() }
    .toolbar {
      ToolbarItemGroup(placement: .bottomBar) {
        Button { model.path.append(.bots) } label: { RoundIcon(symbol: "person.2.fill") }
          .accessibilityLabel(WatchL10n.bots)
        Spacer()
        Button { model.path.append(.ask(bot: nil, conversation: nil)) } label: {
          RoundIcon(symbol: "mic.fill", size: 40, tone: .main)
        }
        .handGestureShortcut(.primaryAction)
        .accessibilityLabel(WatchL10n.ask)
        Spacer()
        Button { model.path.append(.upNext) } label: { RoundIcon(symbol: "clock.fill") }
          .accessibilityLabel(WatchL10n.upNext)
      }
    }
  }

  @ViewBuilder
  private func content(_ glance: Glance) -> some View {
    let live = model.online
    let runs = glance.liveRuns.filter { $0.phase == .working }
    if glance.needsCount > 0 {
      NeedsCard(glance: glance, live: live)
    }
    ForEach(big ? Array(runs.prefix(1)) : runs) { run in
      Button { model.path.append(.run(run.id)) } label: { WorkingCard(run: run, live: live) }
        .buttonStyle(.plain)
    }
    if glance.needsCount == 0 && runs.isEmpty {
      AllClear()
    }
    if let next = glance.nextRoutine, let at = next.nextAt {
      Button { model.path.append(.upNext) } label: {
        Card {
          VStack(alignment: .leading, spacing: 2) {
            Eyebrow(text: WatchL10n.upNext, color: WatchTheme.secondary)
            Text(next.name).font(.watchBody).lineLimit(2)
            Text(WatchTime.upcoming(at)).font(.watchCaption).foregroundStyle(WatchTheme.secondary)
          }
        }
      }
      .buttonStyle(.plain)
    }
    if !big, let brief = glance.brief {
      Button { model.path.append(.brief) } label: {
        Card {
          VStack(alignment: .leading, spacing: 2) {
            Eyebrow(text: WatchL10n.brief, color: WatchTheme.secondary)
            if let text = brief.text {
              PrivateText(text, font: .watchCaption, lines: 2)
            } else if let at = brief.nextAt {
              Text(WatchTime.briefLine(at)).font(.watchCaption).foregroundStyle(WatchTheme.secondary)
            }
          }
        }
      }
      .buttonStyle(.plain)
    }
  }

  /// Before the first glance: the shape of Now in grey, never a spinner.
  private var placeholder: some View {
    VStack(spacing: 8) {
      ForEach(0..<2, id: \.self) { _ in
        Card {
          VStack(alignment: .leading, spacing: 6) {
            Capsule().fill(WatchTheme.dim).frame(width: 60, height: 7)
            Capsule().fill(WatchTheme.dim).frame(width: 110, height: 9)
          }
        }
      }
    }
    .redacted(reason: .placeholder)
    .accessibilityHidden(true)
  }
}

struct NeedsCard: View {
  let glance: Glance
  let live: Bool
  @EnvironmentObject private var model: AppModel
  @Environment(\.hideWords) private var hideWords

  var body: some View {
    let first = glance.needs.first
    Button {
      if glance.needsCount == 1, let first {
        model.path.append(model.screen(for: first))
      } else {
        model.path.append(.needs)
      }
    } label: {
      Card(WatchTheme.needsCard(live)) {
        VStack(alignment: .leading, spacing: 4) {
          Eyebrow(text: "\(WatchL10n.needsYou) · \(glance.needsCount)", color: hideWords ? WatchTheme.needs(live) : WatchTheme.onAmber)
          if let first {
            HStack(alignment: .top, spacing: 6) {
              BotMarkView(name: first.bot, avatar: first.botAvatar, size: 24, muted: hideWords)
              VStack(alignment: .leading, spacing: 1) {
                Text(first.bot).font(.watchCaption.weight(.semibold)).lineLimit(1)
                PrivateText(first.text, font: .watchCaption, color: hideWords ? .white : WatchTheme.onAmber, lines: 2)
              }
            }
            .foregroundStyle(hideWords ? Color.white : WatchTheme.onAmber)
          }
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(glance.needsCount == 1 ? WatchL10n.needsYouOne : WatchL10n.needsYouMany("\(glance.needsCount)"))
    .accessibilityHint(hideWords ? "" : (first.map { "\($0.bot): \($0.text)" } ?? ""))
  }
}

struct WorkingCard: View {
  let run: Glance.Run
  let live: Bool
  @Environment(\.hideWords) private var hideWords

  var body: some View {
    Card(WatchTheme.liveCard(live)) {
      HStack(spacing: 8) {
        BotMarkView(name: run.bot, avatar: run.botAvatar, size: 28, muted: hideWords)
        VStack(alignment: .leading, spacing: 1) {
          Text(WatchL10n.isWorking(run.bot)).font(.watchCaption.weight(.semibold)).lineLimit(1)
          if !run.step.isEmpty {
            PrivateText(run.step, font: .watchCaption, color: WatchTheme.greenText, lines: 1)
          }
          RunClock(start: run.startedAt, color: WatchTheme.working(live))
        }
      }
    }
    .accessibilityElement(children: .combine)
  }
}

struct AllClear: View {
  var body: some View {
    VStack(spacing: 4) {
      MascotView(name: "sleepy", size: 54)
      Text(WatchL10n.allClear).font(.watchTitle)
      Text(WatchL10n.nothingWaiting).font(.watchCaption).foregroundStyle(WatchTheme.secondary).multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 6)
    .accessibilityElement(children: .combine)
  }
}

// MARK: - Needs you, all of them (mockup "Needs you" list)

struct NeedsListView: View {
  @EnvironmentObject private var model: AppModel

  var body: some View {
    let needs = model.glance?.needs ?? []
    ScrollView {
      VStack(alignment: .leading, spacing: 6) {
        if !model.online { DatedBanner(savedAt: model.savedAt) }
        if needs.isEmpty {
          AllClear()
        }
        ForEach(needs) { need in
          Button { model.path.append(model.screen(for: need)) } label: { NeedRow(need: need) }
            .buttonStyle(.plain)
        }
      }
    }
    .navigationTitle(WatchL10n.needsYou)
  }
}

struct NeedRow: View {
  let need: Glance.Need
  @Environment(\.hideWords) private var hideWords

  var body: some View {
    Card {
      HStack(alignment: .top, spacing: 8) {
        BotMarkView(name: need.bot, avatar: need.botAvatar, size: 26, muted: hideWords)
        VStack(alignment: .leading, spacing: 2) {
          Text(need.bot).font(.watchCaption.weight(.semibold)).foregroundStyle(WatchTheme.amber).lineLimit(1)
          PrivateText(need.text, font: .watchCaption, lines: 3)
          if need.kind == "approval", let risk = need.risk { RiskChip(risk: risk) }
        }
      }
    }
    .accessibilityElement(children: .combine)
  }
}
