import AVFoundation
import SwiftUI

// MARK: - Following a run (§6.1 D, mockups "Working", "Reply")
//
// The run's own event stream (SSE over URLSession; the server ends each stream at 110 s and the
// watch picks it up again). A wrist tap when it needs the person, finishes or fails. When it
// finishes the screen becomes the reply, read aloud when the person asked for that.

@MainActor
final class RunFollower: ObservableObject {
  @Published var run: WatchRun?
  @Published var reachable = true
  private var task: Task<Void, Never>?
  private var followingId: String?

  func follow(_ id: String) {
    if followingId != id {
      stopFollowing()
      followingId = id
    }
    guard task == nil else { return }
    task = Task { [weak self] in
      var wait: UInt64 = 1
      while !Task.isCancelled {
        guard let api = WatchAPI.current() else { return }
        do {
          for try await fresh in api.runStream(id) {
            guard !Task.isCancelled, let self else { return }
            self.update(fresh)
            self.reachable = true
            wait = 1
          }
          // The server closed the stream (110 s) or the run ended.
          if Task.isCancelled || (self?.run?.phase.ended ?? false) { return }
        } catch is CancellationError {
          return
        } catch WatchAPIError.notFound {
          return
        } catch WatchAPIError.signedOut {
          return
        } catch {
          guard !Task.isCancelled else { return }
          self?.reachable = false
          try? await Task.sleep(nanoseconds: wait * 1_000_000_000)
          wait = min(wait * 2, 30)
        }
      }
    }
  }

  func stopFollowing() {
    task?.cancel()
    task = nil
  }

  private func update(_ fresh: WatchRun) {
    let change = RunChange.between(run?.phase, fresh.phase)
    let first = run == nil
    run = fresh
    guard !first else { return }
    switch change {
    case .needsYou: Haptic.needsYou()
    case .finished: Haptic.done()
    case .problem: Haptic.problem()
    case .none: break
    }
  }
}

/// Read aloud: the server's voice when it has one, else the watch's own.
@MainActor
final class Speaker: NSObject, ObservableObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
  static let shared = Speaker()

  @Published var speaking: String?
  private var player: AVAudioPlayer?
  private var speechTask: Task<Void, Never>?
  private var activeUtterance: AVSpeechUtterance?
  private let synth = AVSpeechSynthesizer()

  override init() {
    super.init()
    synth.delegate = self
  }

  func toggle(_ message: WatchMessage, serverVoice: Bool) {
    if speaking == message.id { stop(); return }
    stop()
    speaking = message.id
    speechTask = Task {
      activate()
      if serverVoice && message.canSpeak, let api = WatchAPI.current(), let data = try? await api.speech(message: message.id),
         !Task.isCancelled, speaking == message.id, let p = try? AVAudioPlayer(data: data) {
        p.delegate = self
        player = p
        p.play()
        return
      }
      guard !Task.isCancelled, speaking == message.id else { return }
      let utterance = AVSpeechUtterance(string: message.text)
      utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
      activeUtterance = utterance
      synth.speak(utterance)
    }
  }

  func stop() {
    speechTask?.cancel()
    speechTask = nil
    activeUtterance = nil
    player?.delegate = nil
    player?.stop()
    player = nil
    if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    speaking = nil
    deactivate()
  }

  private func activate() {
    let s = AVAudioSession.sharedInstance()
    try? s.setCategory(.playback, mode: .spokenAudio, policy: .default)
    try? s.setActive(true)
  }

  private func deactivate() {
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    Task { @MainActor in
      guard self.player === player else { return }
      self.stop()
    }
  }

  nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    Task { @MainActor in
      guard self.activeUtterance === utterance else { return }
      self.stop()
    }
  }
}

struct RunView: View {
  let runId: String
  @EnvironmentObject private var model: AppModel
  @StateObject private var follower = RunFollower()
  @Environment(\.hideWords) private var hideWords
  @State private var stopping = false
  @State private var spokeReply = false

  /// The glance's row, so the screen draws before the stream answers.
  private var seed: Glance.Run? { model.glance?.runs.first { $0.id == runId } }

  /// Where Open on iPhone goes: the server's link for the run, else its bot's chat, else the
  /// chats. The phone has no page for a run by its id alone.
  private var phoneLink: String {
    let run = follower.run
    let bot = PhoneRoutes.first(run?.botId, seed?.botId, else: "")
    return PhoneRoutes.first(
      run?.link, seed?.link,
      else: bot.isEmpty ? PhoneRoutes.home : PhoneRoutes.chat(bot: bot, conversation: run?.conversationId))
  }

  var body: some View {
    let run = follower.run
    let phase = run?.phase ?? seed?.phase ?? .working
    // A run just asked from this watch: neither the glance nor the stream knows it yet.
    let asked = model.askedRunBots[runId].flatMap { model.glance?.bot($0) }
    let bot = PhoneRoutes.first(run?.bot, seed?.bot, asked?.name, else: "")
    let avatar = PhoneRoutes.first(run?.botAvatar, seed?.botAvatar, asked?.avatar, else: "")
    let live = follower.reachable && model.online

    ScrollView {
      VStack(spacing: 8) {
        if !live { DatedBanner(savedAt: nil) }
        switch phase {
        case .working:
          WorkingRing(name: bot, avatar: avatar, color: WatchTheme.working(live))
          Text(WatchL10n.isWorking(bot)).font(.watchTitle).multilineTextAlignment(.center)
          let step = run?.step ?? seed?.step ?? ""
          if !step.isEmpty { PrivateText(step, font: .watchCaption, color: WatchTheme.greenText, lines: 2) }
          HStack(spacing: 8) {
            let steps = run?.steps ?? seed?.steps ?? 0
            if steps > 0 { Text(WatchL10n.stepCount("\(steps)")).font(.watchCaption).foregroundStyle(WatchTheme.secondary) }
            RunClock(start: run?.startedAt ?? seed?.startedAt, color: WatchTheme.working(live))
          }
          Button(WatchL10n.stop) { stop() }
            .buttonStyle(PillStyle(tone: .stop, small: true))
            .disabled(stopping)
        case .needsOk:
          WorkingRing(name: bot, avatar: avatar, color: WatchTheme.needs(live))
          Text(WatchL10n.needsOkFrom(bot)).font(.watchTitle).multilineTextAlignment(.center)
          if let a = run?.approval {
            PrivateText(a.title, font: .watchCaption, lines: 3)
            Button(WatchL10n.review) { model.path.append(.approval(a.id, nil)) }
              .buttonStyle(PillStyle(tone: .allow))
          } else if let id = seed?.approvalId {
            Button(WatchL10n.review) { model.path.append(.approval(id, nil)) }
              .buttonStyle(PillStyle(tone: .allow))
          }
        case .takeOver:
          BotMarkView(name: bot, avatar: avatar, size: 44, muted: hideWords)
          Text(WatchL10n.takeOver).font(.watchTitle)
          Text(WatchL10n.continuesOnIphone).font(.watchCaption).foregroundStyle(WatchTheme.secondary)
          Button {
            Task { await model.openOnPhone(link: phoneLink, title: WatchL10n.takeOver) }
          } label: { Label(WatchL10n.openOnIphone, systemImage: "iphone") }
          .buttonStyle(PillStyle(tone: .main))
        case .finished:
          if let reply = run?.reply {
            ReplyContent(botId: run?.botId ?? "", bot: bot, avatar: avatar, message: reply, conversationId: run?.conversationId, link: run?.link ?? "")
          } else {
            BotMarkView(name: bot, avatar: avatar, size: 44)
            Text(WatchL10n.finished).font(.watchTitle)
            if let botId = run?.botId, !botId.isEmpty {
              Button(WatchL10n.chat) { model.replaceTop(with: .chat(bot: botId, conversation: run?.conversationId)) }
                .buttonStyle(PillStyle(tone: .plain, small: true))
            }
          }
        case .problem:
          BotMarkView(name: bot, avatar: avatar, size: 44)
          Text(WatchL10n.couldntFinish).font(.watchTitle).foregroundStyle(WatchTheme.red).multilineTextAlignment(.center)
          Button { Task { await model.openOnPhone(link: phoneLink, title: WatchL10n.problem) } } label: {
            Label(WatchL10n.openOnIphone, systemImage: "iphone")
          }
          .buttonStyle(PillStyle(tone: .plain, small: true))
        case .stopped:
          BotMarkView(name: bot, avatar: avatar, size: 44)
          Text(WatchL10n.stopped).font(.watchTitle)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 4)
    }
    .navigationTitle(bot)
    .onAppear { follower.follow(runId) }
    .onDisappear { follower.stopFollowing() }
    .onChange(of: follower.run?.phase) { _, phase in
      guard phase == .finished, !spokeReply, model.readAloud, !hideWords, let reply = follower.run?.reply, !reply.text.isEmpty else { return }
      spokeReply = true
      Speaker.shared.toggle(reply, serverVoice: model.me?.features.speech ?? false)
    }
  }

  private func stop() {
    stopping = true
    Task {
      let result = await model.stop(runId)
      stopping = false
      if result != .done && result != .alreadyAnswered { Haptic.problem() }
    }
  }
}

/// A reply: the words (or a line saying it is hidden), Read aloud, Reply, and the chat.
struct ReplyContent: View {
  let botId: String
  let bot: String
  let avatar: String
  let message: WatchMessage
  let conversationId: String?
  let link: String
  @EnvironmentObject private var model: AppModel
  @ObservedObject private var speaker = Speaker.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 6) {
        BotMarkView(name: bot, avatar: avatar, size: 24)
        VStack(alignment: .leading, spacing: 0) {
          Text(bot).font(.watchCaption.weight(.semibold)).lineLimit(1)
          if let at = message.at {
            Text(WatchTime.replied(at)).font(.system(.caption2, design: .rounded)).foregroundStyle(WatchTheme.secondary)
          }
        }
      }
      .accessibilityElement(children: .combine)
      if model.hideReplyText {
        Text(WatchL10n.replyReady).font(.watchBody)
      } else {
        PrivateText(message.text, font: .watchBody, lines: nil)
        if message.cut {
          Text(WatchL10n.continuesOnIphone).font(.watchCaption).foregroundStyle(WatchTheme.secondary)
        }
        ForEach(Array(message.attachments.prefix(3).enumerated()), id: \.offset) { _, a in
          Label(a.title.isEmpty ? a.kind : a.title, systemImage: symbol(a.kind))
            .font(.watchCaption)
            .foregroundStyle(WatchTheme.secondary)
            .lineLimit(1)
        }
      }
      if !message.text.isEmpty && !model.hideReplyText {
        Button {
          speaker.toggle(message, serverVoice: model.me?.features.speech ?? false)
        } label: {
          Label(speaker.speaking == message.id ? WatchL10n.stopReading : WatchL10n.readAloud,
                systemImage: speaker.speaking == message.id ? "stop.fill" : "speaker.wave.2.fill")
        }
        .buttonStyle(PillStyle(tone: .plain, small: true))
      }
      if !botId.isEmpty {
        Button { model.path.append(.ask(bot: botId, conversation: conversationId)) } label: {
          Label(WatchL10n.reply, systemImage: "mic.fill")
        }
        .buttonStyle(PillStyle(tone: .main, small: true))
      }
      if message.cut || model.hideReplyText, !link.isEmpty {
        Button { Task { await model.openOnPhone(link: link, title: bot) } } label: {
          Label(WatchL10n.openOnIphone, systemImage: "iphone")
        }
        .buttonStyle(PillStyle(tone: .plain, small: true))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func symbol(_ kind: String) -> String {
    switch kind {
    case "image": return "photo"
    case "video": return "film"
    case "audio": return "waveform"
    case "page", "link": return "link"
    case "document": return "doc.text"
    default: return "doc"
    }
  }
}

// MARK: - The latest of a chat (mockup "Chat")

struct ChatView: View {
  let botId: String
  let conversationId: String?
  @EnvironmentObject private var model: AppModel
  @Environment(\.hideWords) private var hideWords
  @State private var chat: WatchChat?
  @State private var reachable = true

  var body: some View {
    let glanceBot = model.glance?.bot(botId)
    let name = chat?.bot.name ?? glanceBot?.name ?? ""
    let avatar = chat?.bot.avatar ?? glanceBot?.avatar ?? ""
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        if !reachable || !model.online { DatedBanner(savedAt: nil) }
        if let runId = chat?.runId ?? model.glance?.run(forBot: botId)?.id {
          Button { model.path.append(.run(runId)) } label: {
            Card(WatchTheme.liveCard(model.online)) {
              Label(WatchL10n.isWorking(name), systemImage: "sparkles").font(.watchCaption.weight(.semibold))
            }
          }
          .buttonStyle(.plain)
        }
        let messages = chat?.messages ?? []
        ForEach(messages.suffix(6)) { m in
          if m.isMine {
            HStack {
              Spacer(minLength: 20)
              PrivateText(m.text, font: .watchCaption, color: WatchTheme.onOrchid, lines: 4)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(hideWords ? Color.clear : WatchTheme.orchid))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(hideWords ? WatchL10n.you : "\(WatchL10n.you): \(m.text)")
          } else if m.id == messages.last?.id {
            Card {
              ReplyContent(botId: botId, bot: name, avatar: avatar, message: m, conversationId: chat?.conversationId ?? conversationId, link: chat?.link ?? "")
            }
          } else {
            Card {
              PrivateText(model.hideReplyText ? WatchL10n.replyReady : m.text, font: .watchCaption, lines: 4)
            }
          }
        }
        if messages.isEmpty || messages.last?.isMine == true {
          Button { model.path.append(.ask(bot: botId, conversation: chat?.conversationId ?? conversationId)) } label: {
            Label(WatchL10n.askBot(name), systemImage: "mic.fill")
          }
          .buttonStyle(PillStyle(tone: .main, small: true))
        }
      }
      .padding(.horizontal, 2)
    }
    .navigationTitle(name)
    .refreshable { await load() }
    .task { await load() }
    .onChange(of: model.glance?.madeAt) { _, _ in
      Task { await load() }
    }
  }

  private func load() async {
    if chat == nil, conversationId == nil { chat = GlanceCache.chat(bot: botId) }
    guard let api = WatchAPI.current() else { return }
    do {
      let (fresh, data) = try await api.chat(bot: botId, conversation: conversationId)
      chat = fresh
      reachable = true
      if conversationId == nil { GlanceCache.saveChat(bot: botId, data: data) }
    } catch {
      reachable = false
    }
  }
}
