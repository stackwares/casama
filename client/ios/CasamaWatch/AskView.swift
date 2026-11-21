import AVFoundation
import SwiftUI

// MARK: - Ask (§6.1 C, mockups "Ask", "Heard", "Kept offline")
//
// Opens listening. The recording is AAC, mono, 16 kHz, and stops by itself after a second and a
// half of quiet; the server transcribes it (no Speech framework on the watch). Type instead uses
// the system's text input, which includes the watch's own dictation and Scribble. What the server
// heard shows for a moment with Undo, then Ask becomes the run it started. With no connection the
// ask is kept and sent later; one older than ten minutes asks first (AppModel.sendKept).

@MainActor
final class Recorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
  enum State: Equatable { case idle, listening, denied, failed }

  @Published var state: State = .idle
  /// 0…1, for the level bars.
  @Published var level: CGFloat = 0
  private(set) var fileURL: URL?

  private var recorder: AVAudioRecorder?
  private var timer: Timer?
  private var heardSpeech = false
  private var quietSince: Date?
  private var startedAt = Date()
  private var onFinish: ((URL?) -> Void)?

  static let silenceLevel: Float = -42
  static let silenceStop: TimeInterval = 1.5
  static let nothingHeardStop: TimeInterval = 6
  static let longest: TimeInterval = 60

  func start(onFinish: @escaping (URL?) -> Void) async {
    guard state != .listening else { return }
    self.onFinish = onFinish
    let allowed = await AVAudioApplication.requestRecordPermission()
    guard allowed else {
      state = .denied
      return
    }
    let url = AskQueueStore.tempRecordingURL()
    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 16_000,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
    ]
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.record, mode: .default)
      try session.setActive(true)
      let r = try AVAudioRecorder(url: url, settings: settings)
      r.delegate = self
      r.isMeteringEnabled = true
      guard r.record(forDuration: Self.longest) else { throw CocoaError(.fileWriteUnknown) }
      recorder = r
      fileURL = url
      heardSpeech = false
      quietSince = nil
      startedAt = Date()
      state = .listening
      timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
        Task { @MainActor in self?.tick() }
      }
    } catch {
      state = .failed
    }
  }

  private func tick() {
    guard let r = recorder, r.isRecording else { return }
    r.updateMeters()
    let power = r.averagePower(forChannel: 0)
    level = CGFloat(max(0, min(1, (power + 60) / 60)))
    let now = Date()
    if power > Self.silenceLevel {
      heardSpeech = true
      quietSince = nil
    } else if heardSpeech {
      if quietSince == nil { quietSince = now }
      if let q = quietSince, now.timeIntervalSince(q) >= Self.silenceStop { stop() }
    } else if now.timeIntervalSince(startedAt) >= Self.nothingHeardStop {
      cancel()
      onFinish?(nil)
      onFinish = nil
    }
  }

  /// Stops and hands over the recording.
  func stop() {
    guard let r = recorder else { return }
    r.stop()
  }

  /// Stops and throws the recording away.
  func cancel() {
    timer?.invalidate()
    timer = nil
    recorder?.delegate = nil
    recorder?.stop()
    recorder?.deleteRecording()
    recorder = nil
    fileURL = nil
    if state == .listening { state = .idle }
    level = 0
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    Task { @MainActor in
      self.timer?.invalidate()
      self.timer = nil
      self.state = .idle
      self.level = 0
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
      let url = flag && self.heardSpeech ? self.fileURL : nil
      // Not handed over (nothing was said, or the recording failed): it doesn't stay in the temp folder.
      if url == nil, let left = self.fileURL { try? FileManager.default.removeItem(at: left) }
      self.recorder = nil
      self.onFinish?(url)
      self.onFinish = nil
    }
  }
}

struct AskView: View {
  let botId: String?
  let conversationId: String?

  enum Stage: Equatable {
    case ready
    case sending
    case heard(String, runId: String?, conversationId: String, typed: Bool = false)
    case kept
    case problem(String)
  }

  @EnvironmentObject private var model: AppModel
  @StateObject private var recorder = Recorder()
  @State private var stage: Stage = .ready
  @State private var typed = ""
  @State private var chosenBot: String?
  @State private var choosing = false
  @State private var moveOn: Task<Void, Never>?

  private var activeBotId: String? {
    chosenBot ?? botId ?? model.defaultAskBot
  }
  private var bot: Glance.Bot? {
    guard let id = activeBotId else { return nil }
    return model.glance?.bot(id)
  }
  private var botName: String { bot?.name ?? "" }
  private var dictation: Bool { model.me?.features.dictation ?? true }
  private var outOfCredits: Bool { model.me?.features.outOfCredits ?? false }

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        header
        switch stage {
        case .ready: ready
        case .sending:
          HStack(spacing: 6) {
            ProgressView().frame(width: 18, height: 18)
            Text(WatchL10n.sending).font(.watchCaption)
          }
        case .heard(let text, let runId, _, let typed):
          VStack(alignment: .leading, spacing: 4) {
            // A typed ask says "Sent": nothing was heard.
            Eyebrow(text: typed ? WatchL10n.replySent : WatchL10n.heard, color: WatchTheme.secondary)
            PrivateText(text, font: .watchBody, lines: 4)
            Button(WatchL10n.undo) { undo(runId: runId) }
              .buttonStyle(PillStyle(tone: .plain, small: true))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        case .kept:
          VStack(spacing: 4) {
            Image(systemName: "tray.and.arrow.up.fill").font(.title3).foregroundStyle(WatchTheme.secondary)
            Text(WatchL10n.keptOffline).font(.watchCaption).multilineTextAlignment(.center)
          }
          .accessibilityElement(children: .combine)
        case .problem(let text):
          Text(text).font(.watchCaption).foregroundStyle(WatchTheme.amber).multilineTextAlignment(.center)
          Button(WatchL10n.tryAgain) {
            stage = .ready
            listen()
          }
          .buttonStyle(PillStyle(tone: .main, small: true))
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 4)
    }
    .navigationTitle(WatchL10n.ask)
    .onAppear {
      if chosenBot == nil { chosenBot = botId ?? model.defaultAskBot }
      if stage == .ready, dictation, !outOfCredits { listen() }
    }
    .onChange(of: model.defaultAskBot) { _, next in
      if chosenBot == nil { chosenBot = next }
    }
    .onDisappear {
      recorder.cancel()
      moveOn?.cancel()
    }
  }

  private var header: some View {
    Button { choosing = true } label: {
      HStack(spacing: 6) {
        BotMarkView(name: botName, avatar: bot?.avatar, size: 22)
        Text(botName.isEmpty ? WatchL10n.ask : WatchL10n.askBot(botName))
          .font(.watchCaption.weight(.semibold))
          .lineLimit(1)
        Image(systemName: "chevron.down").font(.caption2).foregroundStyle(WatchTheme.secondary)
      }
    }
    .buttonStyle(.plain)
    .disabled(stage != .ready || (model.glance?.bots.count ?? 0) < 2)
    .sheet(isPresented: $choosing) {
      List(model.glance?.bots ?? []) { b in
        Button {
          chosenBot = b.id
          choosing = false
        } label: {
          HStack(spacing: 8) {
            BotMarkView(name: b.name, avatar: b.avatar, size: 24)
            Text(b.name).lineLimit(1)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var ready: some View {
    if outOfCredits {
      Text(WatchL10n.outOfCredits).font(.watchBody).foregroundStyle(WatchTheme.amber)
    } else {
      if recorder.state == .listening {
        Button { recorder.stop() } label: {
          VStack(spacing: 4) {
            LevelBars(level: recorder.level)
            Text(WatchL10n.listening).font(.watchTitle)
            Text(WatchL10n.tapToStop).font(.watchCaption).foregroundStyle(WatchTheme.secondary)
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(WatchL10n.tapToStop)
      } else if !dictation {
        Text(WatchL10n.noDictation).font(.watchCaption).foregroundStyle(WatchTheme.secondary).multilineTextAlignment(.center)
      } else if recorder.state == .denied {
        Text(WatchL10n.micDenied).font(.watchCaption).foregroundStyle(WatchTheme.secondary).multilineTextAlignment(.center)
      } else {
        Button { listen() } label: { RoundIcon(symbol: "mic.fill", size: 52, tone: .main) }
          .buttonStyle(.plain)
          .accessibilityLabel(WatchL10n.ask)
      }

      TextFieldLink(prompt: Text(WatchL10n.typeInstead)) {
        Label(WatchL10n.typeInstead, systemImage: "keyboard")
          .font(.watchCaption.weight(.semibold))
          .frame(maxWidth: .infinity)
      } onSubmit: { text in
        recorder.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        send(text: trimmed, audio: nil)
      }
      .buttonStyle(PillStyle(tone: .plain, small: true))

      ForEach(Array((model.glance?.starters ?? []).prefix(3)), id: \.self) { starter in
        Button {
          recorder.cancel()
          send(text: starter.text, audio: nil)
        } label: {
          Text(starter.emoji.isEmpty ? starter.text : "\(starter.emoji) \(starter.text)")
            .font(.watchCaption)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PillStyle(tone: .plain, small: true))
      }
    }
  }

  private func listen() {
    guard dictation, !outOfCredits else { return }
    Task {
      await recorder.start { url in
        if let url {
          send(text: nil, audio: url)
        } else if recorder.state != .denied && recorder.state != .failed {
          stage = .problem(WatchL10n.didntCatch)
        }
      }
      if recorder.state == .failed { stage = .problem(WatchL10n.didntCatch) }
    }
  }

  private func send(text: String?, audio: URL?) {
    guard let botId = activeBotId else {
      if let audio { try? FileManager.default.removeItem(at: audio) }
      Haptic.problem()
      stage = .problem(WatchL10n.couldntReach)
      return
    }
    stage = .sending
    let askedAt = Date()
    let key = UUID().uuidString
    Task {
      var body = WatchAskBody(botId: botId, conversationId: conversationId, text: text, askedAt: askedAt, surface: "app")
      var audioData: Data?
      // The recording leaves the temp folder on every way out of here: sent, refused, or moved
      // into the kept asks. Nothing from it stays behind (§10).
      func discardRecording() {
        if let audio { try? FileManager.default.removeItem(at: audio) }
      }
      if let audio {
        audioData = try? Data(contentsOf: audio)
        guard let audioData else {
          discardRecording()
          stage = .problem(WatchL10n.didntCatch)
          return
        }
        body.audio = .init(data: audioData.base64EncodedString(), mime: "audio/mp4")
        body.language = WatchDevice.languageHint
      }
      guard let api = WatchAPI.current() else {
        discardRecording()
        return
      }
      do {
        let asked = try await api.ask(body, idempotencyKey: key)
        discardRecording()
        WatchAccount.lastAskBot = botId
        model.online = true
        Haptic.done()
        let heard = asked.heard.isEmpty ? (text ?? "") : asked.heard
        stage = .heard(heard, runId: asked.runId, conversationId: asked.conversationId, typed: audio == nil)
        moveOn = Task {
          try? await Task.sleep(nanoseconds: 2_500_000_000)
          guard !Task.isCancelled else { return }
          if let run = asked.runId {
            model.askedRunBots[run] = botId
            model.replaceTop(with: .run(run))
          } else {
            model.replaceTop(with: .chat(bot: botId, conversation: asked.conversationId))
          }
        }
      } catch WatchAPIError.offline {
        keep(botId: botId, text: text, audio: audio, askedAt: askedAt, key: key)
      } catch WatchAPIError.signedOut {
        discardRecording()
        model.keyGone()
      } catch WatchAPIError.forbidden {
        discardRecording()
        Haptic.problem()
        stage = .problem(WatchL10n.outOfCredits)
      } catch WatchAPIError.refused(let status, let problem) {
        discardRecording()
        Haptic.problem()
        // The recording had no words in it, or a limit was reached: neither is "couldn't reach".
        if problem?.code == "nothing_heard" || problem?.code == "bad_audio" {
          stage = .problem(WatchL10n.didntCatch)
        } else if status == 402 {
          stage = .problem(WatchL10n.outOfCredits)
        } else {
          stage = .problem(WatchL10n.couldntReach)
        }
      } catch {
        discardRecording()
        Haptic.problem()
        stage = .problem(WatchL10n.couldntReach)
      }
    }
  }

  /// No connection: keep the ask (and its recording) to send when back online.
  private func keep(botId: String, text: String?, audio: URL?, askedAt: Date, key: String) {
    var fileName: String?
    if let audio, let dir = AskQueueStore.audioDir {
      let name = "\(key).m4a"
      do {
        try FileManager.default.moveItem(at: audio, to: dir.appendingPathComponent(name))
        fileName = name
      } catch {}
    }
    guard text != nil || fileName != nil else {
      // The recording couldn't be moved into the kept asks: it isn't left in the temp folder.
      if let audio { try? FileManager.default.removeItem(at: audio) }
      stage = .problem(WatchL10n.couldntReach)
      return
    }
    model.online = false
    model.keep(QueuedAsk(
      id: key, botId: botId, botName: botName, conversationId: conversationId, text: text,
      audioFile: fileName, mime: fileName == nil ? nil : "audio/mp4", askedAt: askedAt, idempotencyKey: key))
    Haptic.done()
    stage = .kept
    moveOn = Task {
      try? await Task.sleep(nanoseconds: 2_200_000_000)
      guard !Task.isCancelled else { return }
      model.popTop()
    }
  }

  /// Undo: the ask was sent, so stop the run it started.
  private func undo(runId: String?) {
    moveOn?.cancel()
    Task {
      if let runId { _ = await model.stop(runId) }
      model.popTop()
    }
  }
}

/// Five bars that follow the voice (still with Reduce Motion: they just don't animate).
struct LevelBars: View {
  let level: CGFloat
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    HStack(spacing: 4) {
      ForEach(0..<5, id: \.self) { i in
        let shape: [CGFloat] = [0.5, 0.8, 1, 0.8, 0.5]
        Capsule()
          .fill(WatchTheme.orchid)
          .frame(width: 6, height: 8 + 30 * level * shape[i])
      }
    }
    .frame(height: 40)
    .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: level)
    .accessibilityHidden(true)
  }
}
