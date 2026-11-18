import Foundation
import Network
import SwiftUI
import UserNotifications
import WatchKit

// MARK: - The watch app's state (D-410)
//
// One model for the whole app: who the watch is signed in as, the saved glance, whether it is
// live or dated, where navigation is, and the actions every screen shares (allow, deny, do it,
// run, stop, open on iPhone). It opens from what was saved and refreshes behind it: never a
// spinner (§6.1 A).

/// A request as the glance first describes it, so its screen draws before the server answers.
struct NeedSeed: Hashable {
  var id: String
  var kind: String
  var botId: String
  var bot: String
  var avatar: String
  var text: String
  var risk: String?
  var link: String

  init(_ n: Glance.Need) {
    id = n.id
    kind = n.kind
    botId = n.botId
    bot = n.bot
    avatar = n.botAvatar
    text = n.text
    risk = n.risk?.rawValue
    link = n.link
  }

  init(id: String, kind: String, botId: String = "", bot: String = "", avatar: String = "", text: String = "", risk: String? = nil, link: String = "") {
    self.id = id
    self.kind = kind
    self.botId = botId
    self.bot = bot
    self.avatar = avatar
    self.text = text
    self.risk = risk
    self.link = link
  }
}

enum Screen: Hashable {
  case needs
  case approval(String, NeedSeed?)
  case suggestion(NeedSeed)
  /// A takeover, a password, anything the watch doesn't answer: Open on iPhone.
  case phoneOnly(NeedSeed)
  case ask(bot: String?, conversation: String?)
  case run(String)
  case chat(bot: String, conversation: String?)
  case bots
  case upNext
  case brief
  case talk(bot: String?)
  case settings
}

/// The full-screen tick after an answer (§6.1 B).
struct Flash: Identifiable, Equatable {
  enum Kind: Equatable { case allowed, denied, done, started, sent, alreadyAnswered }
  let id = UUID()
  let kind: Kind
  /// Close the screen it came from once the tick has shown.
  let pop: Bool
}

enum ActionResult: Equatable {
  case done
  case alreadyAnswered
  case noPasscode
  case offline
  case forbidden(String?)
  case failed
}

@MainActor
final class AppModel: ObservableObject {
  static let shared = AppModel()

  enum Phase: Equatable {
    case signedIn
    /// Waiting on the phone; `waiting` once it has taken long enough to say "Open Casama".
    case signingIn(waiting: Bool)
    case code(WatchCode)
    case codeExpired
    case signedOut
    case tooOld
  }

  @Published var phase: Phase = .signingIn(waiting: false)
  @Published var glance: Glance?
  @Published var savedAt: Date?
  @Published var me: WatchSelf?
  /// The last call reached the server. Off, screens drop the live colours and say how old they are.
  @Published var online = true
  @Published var path: [Screen] = []
  @Published var flash: Flash?
  @Published var welcome: String?
  @Published var queue: [QueuedAsk] = []
  /// A kept ask older than ten minutes, waiting for the person to say send or discard.
  @Published var confirmAsk: QueuedAsk?
  @Published var codeFailed = false
  @Published var hideWhenWristDown = WatchAccount.hideWhenWristDown {
    didSet { WatchAccount.hideWhenWristDown = hideWhenWristDown }
  }
  @Published var readAloud = WatchAccount.readAloud {
    didSet { WatchAccount.readAloud = readAloud }
  }
  @Published var askBot: String? = WatchAccount.askBot {
    didSet { WatchAccount.askBot = askBot }
  }

  private var signInRequest: String?
  private var codeTask: Task<Void, Never>?
  private var refreshTask: Task<Void, Never>?
  private let pathMonitor = NWPathMonitor()
  private var started = false
  private var pushToken: String?

  // MARK: Start

  func start() {
    guard !started else { return }
    started = true
    loadSaved()
    PhoneLink.shared.onMessage = { [weak self] in self?.handlePhone($0) }
    PhoneLink.shared.activate()
    WatchOpen.handler = { [weak self] in self?.open($0) }
    pathMonitor.pathUpdateHandler = { [weak self] path in
      let up = path.status == .satisfied
      Task { @MainActor in self?.networkChanged(up) }
    }
    pathMonitor.start(queue: DispatchQueue(label: "ai.casama.watch.path"))

    if WatchAccount.accepted, WatchKeyStore.read() != nil {
      phase = .signedIn
      refresh()
      registerForPushes()
    } else if WatchAccount.removed {
      phase = .signedOut
    } else {
      askPhoneToSignIn()
    }
    if let link = WatchOpen.takePending() { open(link) }
  }

  /// The app came forward: refresh, and pick up anything an intent left.
  func becameActive() {
    if phase == .signedIn { refresh() }
    if let link = WatchOpen.takePending() { open(link) }
  }

  private func loadSaved() {
    if let saved = GlanceCache.glance() {
      glance = saved.glance
      savedAt = saved.savedAt
    }
    me = GlanceCache.me()
    queue = AskQueueStore.all()
  }

  /// Whether what is shown is live, or dated and grey.
  var isLive: Bool { online }

  var hideReplyText: Bool { me?.hideReplyText ?? glance?.flags.hideReplyText ?? false }

  /// The bot Ask goes to: the last one asked, the one picked in Settings, the server's default.
  var defaultAskBot: String? {
    let known = Set(glance?.bots.map(\.id) ?? [])
    for candidate in [WatchAccount.lastAskBot, askBot, me?.askBotId] {
      if let c = candidate, known.isEmpty || known.contains(c) { return c }
    }
    return glance?.bots.first?.id
  }

  // MARK: Refreshing

  func refresh() {
    guard refreshTask == nil else { return }
    refreshTask = Task { [weak self] in
      await self?.doRefresh()
      self?.refreshTask = nil
    }
  }

  func refreshNow() async {
    if let t = refreshTask { await t.value; return }
    await doRefresh()
  }

  private func doRefresh() async {
    guard let api = WatchAPI.current() else {
      if phase == .signedIn { handleSignedOut() }
      return
    }
    let outcome = await WatchSync.refreshGlance(api: api)
    switch outcome {
    case .fresh, .unchanged:
      online = true
      if let saved = GlanceCache.glance() {
        glance = saved.glance
        savedAt = saved.savedAt
      }
      if outcome == .fresh { WatchSync.reloadWidgets() }
    case .offline, .failed:
      online = false
    case .signedOut:
      handleSignedOut()
      return
    }
    do {
      let (fresh, data) = try await api.me()
      GlanceCache.saveMe(data)
      me = fresh
      WatchAccount.orgName = fresh.orgName
      if !fresh.personName.isEmpty { WatchAccount.personName = fresh.personName }
    } catch WatchAPIError.signedOut {
      handleSignedOut()
      return
    } catch WatchAPIError.notFound {
      // A server without the watch routes (§6.8 "Server too old").
      phase = .tooOld
      return
    } catch {}
    if online { await sendKept() }
    await sendPushToken()
  }

  private func networkChanged(_ up: Bool) {
    if up && phase == .signedIn {
      refresh()
    } else if !up {
      online = false
    }
  }

  // MARK: Signing in (§8.2)

  func askPhoneToSignIn() {
    WatchAccount.removed = false
    codeTask?.cancel()
    guard let key = WatchKeyStore.readOrCreate() else {
      phase = .signingIn(waiting: true)
      return
    }
    let id = UUID().uuidString
    signInRequest = id
    phase = .signingIn(waiting: false)
    var message: [String: Any] = [
      "type": "sign_in",
      "request_id": id,
      "fingerprint": WatchKeyMaker.fingerprint(key),
      "platform": "watchos",
      "name": WatchDevice.name,
      "app_version": WatchDeviceInfo.appVersion,
      "os_version": WatchDeviceInfo.osVersion,
    ]
    if let model = WatchDevice.model { message["model"] = model }
    PhoneLink.shared.send(message)
    // Said at once when there is no phone app to answer, else after a moment's wait.
    let delay: UInt64 = PhoneLink.shared.reachable ? 4_000_000_000 : 1_500_000_000
    Task { [weak self] in
      try? await Task.sleep(nanoseconds: delay)
      guard let self, self.phase == .signingIn(waiting: false), self.signInRequest == id else { return }
      self.phase = .signingIn(waiting: true)
    }
  }

  private func handlePhone(_ message: [String: Any]) {
    guard let type = message["type"] as? String else { return }
    switch type {
    case "signed_in":
      guard phase != .signedIn,
            let raw = message["server"] as? String, let server = URL(string: raw), server.scheme != nil,
            let org = message["org_id"] as? String, !org.isEmpty else { return }
      codeTask?.cancel()
      finishSignIn(server: server, orgId: org, orgName: message["org_name"] as? String ?? "", person: message["person_name"] as? String ?? "")
    case "sign_in_failed":
      if case .signingIn = phase { phase = .signingIn(waiting: true) }
    case "context":
      guard phase == .signedIn else { return }
      if let raw = message["server"] as? String, let server = URL(string: raw), server.scheme != nil { WatchAccount.server = server }
      if let org = message["org_id"] as? String, !org.isEmpty, org != WatchAccount.orgId {
        WatchAccount.orgId = org
        GlanceCache.wipe()
        glance = nil
      }
      if let name = message["org_name"] as? String { WatchAccount.orgName = name }
      if let person = message["person_name"] as? String, !person.isEmpty { WatchAccount.personName = person }
      refresh()
    case "sign_out":
      WatchSync.wipe(removed: true)
      resetToSignedOut()
    default:
      break
    }
  }

  private func finishSignIn(server: URL, orgId: String, orgName: String, person: String) {
    WatchAccount.signIn(server: server, orgId: orgId, orgName: orgName, person: person)
    phase = .signedIn
    online = true
    if !person.isEmpty {
      welcome = WatchL10n.signedInAs(person)
      WatchAccount.welcomed = true
      Task { [weak self] in
        try? await Task.sleep(nanoseconds: 2_800_000_000)
        self?.welcome = nil
      }
    }
    refresh()
    registerForPushes()
  }

  /// Sign in with a code (§8.2): show it, then ask the server every few seconds whether it was
  /// allowed. A 401 here only means "not yet".
  func startCode() {
    codeTask?.cancel()
    codeFailed = false
    guard let key = WatchKeyStore.readOrCreate(), let base = WatchAccount.serverOrDefault else {
      codeFailed = true
      return
    }
    let device = WatchDeviceBody(
      fingerprint: WatchKeyMaker.fingerprint(key), name: WatchDevice.name, model: WatchDevice.model,
      appVersion: WatchDeviceInfo.appVersion, osVersion: WatchDeviceInfo.osVersion)
    codeTask = Task { [weak self] in
      let code: WatchCode
      do {
        code = try await WatchAPI.requestCode(base: base, device: device)
      } catch {
        await MainActor.run { self?.codeFailed = true }
        return
      }
      await MainActor.run { self?.phase = .code(code) }
      let api = WatchAPI(base: base, key: key)
      while !Task.isCancelled, Date() < code.expiresAt {
        try? await Task.sleep(nanoseconds: UInt64(code.pollEveryS) * 1_000_000_000)
        if Task.isCancelled { return }
        guard let result = try? await api.me() else { continue }
        await MainActor.run {
          guard let self else { return }
          let me = result.0
          GlanceCache.saveMe(result.1)
          self.me = me
          self.finishSignIn(server: base, orgId: me.orgId, orgName: me.orgName, person: me.personName)
        }
        return
      }
      await MainActor.run {
        if case .code = self?.phase { self?.phase = .codeExpired }
      }
    }
  }

  func cancelCode() {
    codeTask?.cancel()
    askPhoneToSignIn()
  }

  /// Sign out of this watch: the server forgets the key, the watch forgets everything.
  func signOut() async {
    if let api = WatchAPI.current() { try? await api.signOut() }
    WatchSync.wipe(removed: true)
    resetToSignedOut()
  }

  private func handleSignedOut() {
    WatchSync.signedOut()
    resetToSignedOut()
  }

  private func resetToSignedOut() {
    codeTask?.cancel()
    glance = nil
    savedAt = nil
    me = nil
    queue = []
    path = []
    confirmAsk = nil
    askBot = nil
    phase = .signedOut
  }

  // MARK: Pushes (the watch's own token, §8.5)

  func registerForPushes() {
    Task {
      let center = UNUserNotificationCenter.current()
      _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
      WKApplication.shared().registerForRemoteNotifications()
    }
  }

  func gotPushToken(_ token: Data) {
    pushToken = token.map { String(format: "%02x", $0) }.joined()
    Task { await sendPushToken() }
  }

  private func sendPushToken() async {
    guard let token = pushToken, let api = WatchAPI.current() else { return }
    let marker = "\(token)|\(api.base.absoluteString)|\(WatchKeyMaker.fingerprint(api.key).prefix(12))|\(WatchDeviceInfo.appVersion)"
    guard WatchAccount.pushSent != marker else { return }
    let body = WatchSelfUpdateBody(
      pushToken: token, pushKind: "apns", sandbox: WatchDeviceInfo.apnsSandbox,
      appVersion: WatchDeviceInfo.appVersion, osVersion: WatchDeviceInfo.osVersion, name: WatchDevice.name)
    do {
      try await api.updateSelf(body)
      WatchAccount.pushSent = marker
    } catch WatchAPIError.signedOut {
      handleSignedOut()
    } catch {}
  }

  // MARK: Navigation

  func open(_ link: WatchLink) {
    guard phase == .signedIn else { return }
    switch link {
    case .now: path = []
    case .needs: path = [.needs]
    case .approval(let id): path = [.approval(id, seed(for: id))]
    case .suggestion(let id): path = [.suggestion(seed(for: id) ?? NeedSeed(id: id, kind: "suggestion"))]
    case .run(let id): path = [.run(id)]
    case .chat(let bot, let c): path = [.chat(bot: bot, conversation: c)]
    case .ask(let bot): path = [.ask(bot: bot, conversation: nil)]
    case .bots: path = [.bots]
    case .upNext: path = [.upNext]
    case .brief: path = [.brief]
    case .talk(let bot): path = [.talk(bot: bot)]
    case .settings: path = [.settings]
    }
  }

  /// The screen for a waiting item on Now or in Needs you.
  func screen(for need: Glance.Need) -> Screen {
    let s = NeedSeed(need)
    switch need.kind {
    case "approval": return .approval(need.id, s)
    case "suggestion": return .suggestion(s)
    default: return .phoneOnly(s)
    }
  }

  private func seed(for id: String) -> NeedSeed? {
    glance?.needs.first { $0.id == id }.map(NeedSeed.init)
  }

  /// Replaces the top screen (Ask becomes the run it started).
  func replaceTop(with screen: Screen) {
    if !path.isEmpty { path.removeLast() }
    path.append(screen)
  }

  func popTop() {
    if !path.isEmpty { path.removeLast() }
  }

  /// Shows the tick, then closes it (and the screen under it when asked).
  func showFlash(_ kind: Flash.Kind, pop: Bool) {
    let f = Flash(kind: kind, pop: pop)
    flash = f
    switch kind {
    case .alreadyAnswered: WKInterfaceDevice.current().play(.retry)
    default: WKInterfaceDevice.current().play(.success)
    }
    Task { [weak self] in
      try? await Task.sleep(nanoseconds: 1_200_000_000)
      guard let self, self.flash?.id == f.id else { return }
      self.flash = nil
      if f.pop { self.popTop() }
    }
  }

  // MARK: Actions every screen shares

  /// Allow: the server's word on whether this watch may, the wrist check, then the answer.
  func allow(_ approval: WatchApproval) async -> ActionResult {
    guard approval.isPending else { return .alreadyAnswered }
    guard approval.canAllow != .phone else { return .forbidden(approval.whyPhoneText) }
    switch await WristCheck.check() {
    case .ok: break
    case .noPasscode: return .noPasscode
    case .failed: return .failed
    }
    return await perform { try await $0.decide(approval.id, allow: true) }
  }

  func deny(_ approvalId: String) async -> ActionResult {
    await perform { try await $0.decide(approvalId, allow: false) }
  }

  func doIt(_ suggestionId: String) async -> ActionResult {
    await perform { _ = try await $0.acceptSuggestion(suggestionId) }
  }

  func notNow(_ suggestionId: String) async -> ActionResult {
    await perform { try await $0.dismissSuggestion(suggestionId) }
  }

  func runRoutine(_ routineId: String) async -> ActionResult {
    await perform { _ = try await $0.runRoutine(routineId) }
  }

  func stop(_ runId: String) async -> ActionResult {
    await perform { try await $0.cancelRun(runId) }
  }

  private func perform(_ call: (WatchAPI) async throws -> Void) async -> ActionResult {
    guard let api = WatchAPI.current() else {
      handleSignedOut()
      return .failed
    }
    do {
      try await call(api)
      online = true
      refresh()
      return .done
    } catch let e as WatchAPIError {
      switch e {
      case .signedOut:
        handleSignedOut()
        return .failed
      case .conflict, .notFound: refresh(); return .alreadyAnswered
      case .forbidden(let why): return .forbidden(why)
      case .offline:
        online = false
        return .offline
      default: return .failed
      }
    } catch {
      return .failed
    }
  }

  /// Open on iPhone (§6.10): straight to the phone app when it is in reach, else the server
  /// leaves a notification on the person's phones.
  @discardableResult
  func openOnPhone(link: String, title: String) async -> Bool {
    guard !link.isEmpty else { return false }
    let route = link.hasPrefix("/") ? link : "/" + link
    if PhoneLink.shared.reachable {
      PhoneLink.shared.send(["type": "open", "link": route])
      showFlash(.sent, pop: false)
      return true
    }
    guard let api = WatchAPI.current() else { return false }
    do {
      try await api.handoff(link: route, title: title.isEmpty ? WatchL10n.openOnIphone : title)
      showFlash(.sent, pop: false)
      return true
    } catch WatchAPIError.signedOut {
      handleSignedOut()
    } catch WatchAPIError.offline {
      online = false
    } catch {}
    return false
  }

  // MARK: Asks kept while offline (§6.1 C)

  func keep(_ ask: QueuedAsk) {
    AskQueueStore.add(ask)
    queue = AskQueueStore.all()
  }

  /// Sends kept asks now; one older than ten minutes waits for a yes.
  func sendKept() async {
    let all = AskQueueStore.all()
    guard !all.isEmpty else { return }
    for ask in all where AskQueuePolicy.isStale(ask) { AskQueueStore.remove(ask.id) }
    let (send, confirm) = AskQueuePolicy.split(AskQueueStore.all())
    for ask in send {
      guard await sendKept(ask) else { break }
    }
    queue = AskQueueStore.all()
    if confirmAsk == nil, let first = confirm.first { confirmAsk = first }
  }

  /// Sends one kept ask. Answers false when the connection is still down.
  @discardableResult
  func sendKept(_ ask: QueuedAsk) async -> Bool {
    guard let api = WatchAPI.current() else { return false }
    var body = WatchAskBody(botId: ask.botId, conversationId: ask.conversationId, text: ask.text, askedAt: ask.askedAt, surface: "app")
    if let url = AskQueueStore.audioURL(ask) {
      guard let data = try? Data(contentsOf: url) else {
        AskQueueStore.remove(ask.id)
        return true
      }
      body.audio = .init(data: data.base64EncodedString(), mime: ask.mime ?? "audio/mp4")
      body.language = WatchDevice.languageHint
    }
    do {
      _ = try await api.ask(body, idempotencyKey: ask.idempotencyKey)
      AskQueueStore.remove(ask.id)
      queue = AskQueueStore.all()
      return true
    } catch WatchAPIError.offline {
      online = false
      return false
    } catch WatchAPIError.signedOut {
      handleSignedOut()
      return false
    } catch WatchAPIError.rateLimited {
      return false
    } catch {
      // The server refused it for good (no such bot, out of credits): don't keep retrying.
      AskQueueStore.remove(ask.id)
      queue = AskQueueStore.all()
      return true
    }
  }

  func answerConfirm(send: Bool) {
    guard let ask = confirmAsk else { return }
    confirmAsk = nil
    if send {
      Task { await sendKept(ask) }
    } else {
      AskQueueStore.remove(ask.id)
      queue = AskQueueStore.all()
    }
  }
}

// MARK: - The watch, described for Settings → Watch on the phone

enum WatchDevice {
  static var name: String {
    let n = WKInterfaceDevice.current().name
    return n.isEmpty ? "Apple Watch" : String(n.prefix(80))
  }

  /// "Apple Watch, 46 mm", from the screen's width in points.
  static var model: String? {
    let width = Int(WKInterfaceDevice.current().screenBounds.width.rounded())
    let sizes: [Int: String] = [162: "40 mm", 176: "41 mm", 184: "44 mm", 187: "42 mm", 198: "45 mm", 205: "49 mm", 208: "46 mm", 211: "49 mm"]
    let base = WKInterfaceDevice.current().model
    guard let size = sizes[width] else { return base.isEmpty ? nil : base }
    return "\(base.isEmpty ? "Apple Watch" : base), \(size)"
  }

  /// A BCP 47 hint for transcription ("en", "fil").
  static var languageHint: String? {
    Locale.current.language.languageCode?.identifier
  }
}
