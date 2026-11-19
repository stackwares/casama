import SwiftUI

// MARK: - Bots (mockup "Bots")

struct BotsView: View {
  @EnvironmentObject private var model: AppModel

  var body: some View {
    let bots = model.glance?.bots ?? []
    ScrollView {
      VStack(alignment: .leading, spacing: 6) {
        if !model.online { DatedBanner(savedAt: model.savedAt) }
        if bots.isEmpty {
          MessageScreen(mascot: "shy", title: WatchL10n.noBots)
        }
        ForEach(bots) { bot in
          Button { model.path.append(.chat(bot: bot.id, conversation: nil)) } label: { BotRow(bot: bot, live: model.online) }
            .buttonStyle(.plain)
        }
      }
    }
    .navigationTitle(WatchL10n.bots)
  }
}

struct BotRow: View {
  let bot: Glance.Bot
  let live: Bool
  @Environment(\.hideWords) private var hideWords

  var body: some View {
    Card {
      HStack(alignment: .top, spacing: 8) {
        BotMarkView(name: bot.name, avatar: bot.avatar, size: 30, muted: hideWords)
        VStack(alignment: .leading, spacing: 1) {
          Text(bot.name).font(.watchBody.weight(.semibold)).lineLimit(1)
          switch bot.status {
          case .working:
            HStack(spacing: 4) {
              Circle().fill(WatchTheme.working(live)).frame(width: 6, height: 6)
              Text(WatchL10n.working).font(.watchCaption).foregroundStyle(WatchTheme.working(live))
            }
            if let step = bot.step { PrivateText(step, font: .watchCaption, color: WatchTheme.secondary, lines: 1) }
          case .waiting:
            Text(WatchL10n.waitingForYou).font(.watchCaption).foregroundStyle(WatchTheme.needs(live))
          case .disabled:
            Text(WatchL10n.off).font(.watchCaption).foregroundStyle(WatchTheme.secondary)
          case .idle:
            if let last = bot.lastText {
              PrivateText(last, font: .watchCaption, color: WatchTheme.secondary, lines: 2)
            }
            if let at = bot.lastAt {
              Text(WatchTime.past(at)).font(.system(.caption2, design: .rounded)).foregroundStyle(WatchTheme.secondary)
            }
          }
        }
      }
    }
    .accessibilityElement(children: .combine)
  }
}

// MARK: - Up next (mockup "Up next")

struct UpNextView: View {
  @EnvironmentObject private var model: AppModel
  @State private var busy: String?
  @State private var note: String?

  var body: some View {
    let routines = (model.glance?.next ?? []).filter(\.enabled)
      .sorted { ($0.nextAt ?? .distantFuture) < ($1.nextAt ?? .distantFuture) }
    ScrollView {
      VStack(alignment: .leading, spacing: 6) {
        if !model.online { DatedBanner(savedAt: model.savedAt) }
        if let note { Text(note).font(.watchCaption).foregroundStyle(WatchTheme.amber) }
        if routines.isEmpty {
          MessageScreen(mascot: "sleepy", title: WatchL10n.noRoutines)
        }
        ForEach(routines) { r in
          Card {
            VStack(alignment: .leading, spacing: 4) {
              HStack(spacing: 6) {
                BotMarkView(name: r.bot, avatar: r.botAvatar, size: 22)
                VStack(alignment: .leading, spacing: 0) {
                  Text(r.name).font(.watchBody.weight(.semibold)).lineLimit(2)
                  if let at = r.nextAt {
                    Text(WatchTime.upcoming(at)).font(.watchCaption).foregroundStyle(WatchTheme.secondary)
                  }
                }
              }
              .accessibilityElement(children: .combine)
              Button(WatchL10n.runNow) { run(r.id) }
                .buttonStyle(PillStyle(tone: .plain, small: true))
                .disabled(busy != nil)
            }
          }
        }
      }
    }
    .navigationTitle(WatchL10n.upNext)
  }

  private func run(_ id: String) {
    busy = id
    note = nil
    Task {
      let result = await model.runRoutine(id)
      busy = nil
      switch result {
      case .done: model.showFlash(.started, pop: false)
      case .elsewhere:
        Haptic.problem()
        note = WatchL10n.notOnWatch
      default:
        // Out of credits, a bot with no model: the server's reason, not "couldn't reach".
        Haptic.problem()
        note = result.note ?? WatchL10n.couldntReach
      }
    }
  }
}

// MARK: - The brief (mockup "Brief")

struct BriefView: View {
  @EnvironmentObject private var model: AppModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        if !model.online { DatedBanner(savedAt: model.savedAt) }
        if let brief = model.glance?.brief {
          HStack(spacing: 6) {
            BotMarkView(name: brief.bot, avatar: brief.botAvatar, size: 24)
            VStack(alignment: .leading, spacing: 0) {
              Text(brief.bot).font(.watchCaption.weight(.semibold)).lineLimit(1)
              if let at = brief.at {
                Text(WatchTime.past(at)).font(.system(.caption2, design: .rounded)).foregroundStyle(WatchTheme.secondary)
              }
            }
          }
          .accessibilityElement(children: .combine)
          if let text = brief.text {
            PrivateText(text, font: .watchBody, lines: nil)
          } else {
            Text(WatchL10n.noBrief).font(.watchBody).foregroundStyle(WatchTheme.secondary)
          }
          if let next = brief.nextAt {
            Text(WatchTime.briefLine(next)).font(.watchCaption).foregroundStyle(WatchTheme.secondary)
          }
          if !brief.botId.isEmpty {
            Button { model.path.append(.chat(bot: brief.botId, conversation: nil)) } label: {
              Label(WatchL10n.chat, systemImage: "bubble.left.fill")
            }
            .buttonStyle(PillStyle(tone: .plain, small: true))
          }
        } else {
          MessageScreen(mascot: "sleepy", title: WatchL10n.noBrief)
        }
      }
      .padding(.horizontal, 2)
    }
    .navigationTitle(WatchL10n.brief)
  }
}

// MARK: - Talk: calls run on the phone (§6.1 H)

struct TalkView: View {
  let botId: String?
  @EnvironmentObject private var model: AppModel
  @State private var sent: Bool?

  var body: some View {
    let id = botId ?? model.defaultAskBot
    let bot = id.flatMap { model.glance?.bot($0) }
    MessageScreen(mascot: "giggly", title: sent == false ? WatchL10n.couldntReach : WatchL10n.talkOnPhone, detail: bot?.name) {
      if sent == false {
        Button(WatchL10n.tryAgain) { Task { await start(id, name: bot?.name) } }
          .buttonStyle(PillStyle(tone: .main, small: true))
      }
    }
    .navigationTitle(WatchL10n.talk)
    .task { if sent == nil { await start(id, name: bot?.name) } }
  }

  private func start(_ id: String?, name: String?) async {
    guard let id else {
      sent = false
      return
    }
    sent = await model.openOnPhone(link: PhoneRoutes.call(bot: id), title: name.map { WatchL10n.askBot($0) } ?? WatchL10n.talk)
  }
}

// MARK: - Settings (mockup "Settings")

struct SettingsView: View {
  @EnvironmentObject private var model: AppModel
  @State private var confirmSignOut = false

  var body: some View {
    List {
      Section {
        LabeledContent(WatchL10n.signedInAsLabel, value: model.me?.personName ?? WatchAccount.personName)
        LabeledContent(WatchL10n.workspace, value: model.me?.orgName ?? WatchAccount.orgName)
      }
      Section {
        if let bots = model.glance?.bots, !bots.isEmpty {
          Picker(WatchL10n.askUses, selection: Binding(
            get: { model.askBot ?? model.defaultAskBot ?? "" },
            set: { model.askBot = $0.isEmpty ? nil : $0; WatchAccount.lastAskBot = nil }
          )) {
            ForEach(bots) { Text($0.name).tag($0.id) }
          }
        }
        Toggle(WatchL10n.hideDetails, isOn: $model.hideWhenWristDown)
        Toggle(WatchL10n.readRepliesAloud, isOn: $model.readAloud)
      }
      Section {
        Button(WatchL10n.signOut, role: .destructive) { confirmSignOut = true }
      } footer: {
        Text(verbatim: WatchDeviceInfo.appVersion)
      }
    }
    .navigationTitle(WatchL10n.settings)
    .confirmationDialog(WatchL10n.signOut, isPresented: $confirmSignOut, titleVisibility: .visible) {
      Button(WatchL10n.signOut, role: .destructive) { Task { await model.signOut() } }
      Button(WatchL10n.notNow, role: .cancel) {}
    }
  }
}
