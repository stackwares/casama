import SwiftUI
import WidgetKit

// MARK: - Root: signed in or not, navigation, the tick and the welcome (§6.1, §6.8)

struct RootView: View {
  @EnvironmentObject private var model: AppModel
  @Environment(\.isLuminanceReduced) private var wristDown

  var body: some View {
    ZStack {
      switch model.phase {
      case .signedIn:
        NavigationStack(path: $model.path) {
          NowView()
            .navigationDestination(for: Screen.self) { destination($0) }
        }
      case .signingIn(let waiting):
        SigningInView(waiting: waiting)
      case .code(let code):
        CodeView(code: code)
      case .codeExpired:
        MessageScreen(mascot: "sleepy", title: WatchL10n.useCode) {
          Button(WatchL10n.newCode) { model.startCode() }.buttonStyle(PillStyle(tone: .main))
        }
      case .signedOut:
        SignedOutView()
      case .tooOld:
        MessageScreen(mascot: "thinker", title: WatchL10n.serverTooOld) {
          Button(WatchL10n.tryAgain) {
            model.phase = .signedIn
            model.refresh()
          }
          .buttonStyle(PillStyle(tone: .plain))
        }
      }

      if let flash = model.flash {
        DoneOverlay(flash: flash)
          .transition(.opacity)
          .zIndex(2)
      }

      if let welcome = model.welcome {
        VStack {
          Text(welcome)
            .font(.watchCaption.weight(.semibold))
            .foregroundStyle(WatchTheme.onOrchid)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(WatchTheme.orchid))
            .multilineTextAlignment(.center)
          Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(3)
        .accessibilityAddTraits(.isStaticText)
      }
    }
    .animation(.easeOut(duration: 0.2), value: model.flash)
    .animation(.easeOut(duration: 0.25), value: model.welcome)
    .environment(\.hideWords, wristDown && model.hideWhenWristDown)
    .alert(
      model.confirmAsk.map { WatchL10n.keptOld(WatchTime.past($0.askedAt)) } ?? "",
      isPresented: Binding(get: { model.confirmAsk != nil }, set: { if !$0 { model.confirmAsk = nil } })
    ) {
      Button(WatchL10n.send) { model.answerConfirm(send: true) }
      Button(WatchL10n.discard, role: .destructive) { model.answerConfirm(send: false) }
    }
    .onOpenURL { url in
      model.open(WatchLink.parse(url))
    }
    // A tap on the run's Live Activity on the watch's Smart Stack opens that run.
    .onContinueUserActivity(NSUserActivityTypeLiveActivity) { activity in
      if let raw = activity.userInfo?["link"] as? String {
        model.open(WatchLink.parse(route: raw))
      } else if let run = model.glance?.liveRuns.first {
        model.open(.run(run.id))
      }
    }
  }

  @ViewBuilder
  private func destination(_ screen: Screen) -> some View {
    switch screen {
    case .needs: NeedsListView()
    case .approval(let id, let seed): ApprovalView(id: id, seed: seed)
    case .suggestion(let seed): SuggestionView(seed: seed)
    case .phoneOnly(let seed): PhoneOnlyView(seed: seed)
    case .ask(let bot, let conversation): AskView(botId: bot ?? model.defaultAskBot, conversationId: conversation)
    case .run(let id): RunView(runId: id)
    case .chat(let bot, let conversation): ChatView(botId: bot, conversationId: conversation)
    case .bots: BotsView()
    case .upNext: UpNextView()
    case .brief: BriefView()
    case .talk(let bot): TalkView(botId: bot)
    case .settings: SettingsView()
    }
  }
}

// MARK: - Signing in (§8.2, mockup "Sign in")

struct SigningInView: View {
  let waiting: Bool
  @EnvironmentObject private var model: AppModel

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        MascotView(name: "winky", size: 58)
        if waiting {
          Text(WatchL10n.openPhoneToFinishIphone)
            .font(.watchTitle)
            .multilineTextAlignment(.center)
        } else {
          HStack(spacing: 6) {
            ProgressView().frame(width: 18, height: 18)
            Text(WatchL10n.signingIn).font(.watchTitle)
          }
        }
        if waiting {
          Button(WatchL10n.tryAgain) { model.askPhoneToSignIn() }
            .buttonStyle(PillStyle(tone: .main))
        }
        Button(WatchL10n.useCode) { model.startCode() }
          .buttonStyle(PillStyle(tone: .plain, small: true))
        if model.codeFailed {
          Text(WatchL10n.couldntReach).font(.watchCaption).foregroundStyle(WatchTheme.red).multilineTextAlignment(.center)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 6)
    }
  }
}

struct CodeView: View {
  let code: WatchCode
  @EnvironmentObject private var model: AppModel

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        Text(WatchCodeFormat.display(code.code))
          .font(.system(size: 26, weight: .bold, design: .monospaced))
          .minimumScaleFactor(0.6)
          .lineLimit(1)
          .foregroundStyle(WatchTheme.orchid)
          .accessibilityLabel(WatchCodeFormat.spoken(code.code))
        Text(WatchL10n.codeHelp)
          .font(.watchCaption)
          .foregroundStyle(WatchTheme.secondary)
          .multilineTextAlignment(.center)
        Text(timerInterval: Date()...max(Date(), code.expiresAt), countsDown: true)
          .font(.watchCaption.monospacedDigit())
          .foregroundStyle(WatchTheme.secondary)
        Button(WatchL10n.newCode) { model.startCode() }
          .buttonStyle(PillStyle(tone: .plain, small: true))
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 6)
    }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button { model.cancelCode() } label: { Image(systemName: "xmark") }
          .accessibilityLabel(WatchL10n.signingIn)
      }
    }
  }
}

struct SignedOutView: View {
  @EnvironmentObject private var model: AppModel

  var body: some View {
    MessageScreen(mascot: "sleepy", title: WatchL10n.signedOut) {
      VStack(spacing: 6) {
        Button(WatchL10n.tryAgain) { model.askPhoneToSignIn() }
          .buttonStyle(PillStyle(tone: .main))
        Button(WatchL10n.useCode) { model.startCode() }
          .buttonStyle(PillStyle(tone: .plain, small: true))
        if model.codeFailed {
          Text(WatchL10n.couldntReach).font(.watchCaption).foregroundStyle(WatchTheme.red)
        }
      }
    }
  }
}
