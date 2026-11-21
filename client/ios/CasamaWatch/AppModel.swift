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
  /// The kind of something the push says is from the person's other workspace: only the phone
  /// can answer it.
  static let elsewhere = "elsewhere"
  /// The kind of something the server said isn't in this watch's workspace (404 `not_found`,
  /// from a server that doesn't put the workspace in its pushes): the same, said neutrally.
  static let notHere = "not_here"

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
  enum Kind: Equatable {
    case allowed, denied, done, started
    /// Open on iPhone: the phone has it.
    case sent
    /// A reply went to the bot.
    case replied
    case alreadyAnswered
  }
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
  /// Not in this watch's workspace: the phone answers it.
  case elsewhere
  /// A limit was reached, so nothing started.
  case outOfCredits
  /// The server said no for a reason of its own (its words, when it gave any).
  case refused(String?)
  case failed

  /// What to say under the buttons when it didn't work. Nil when there is nothing to explain
  /// (done, already answered) or the screen says it its own way (another workspace).
  var note: String? {
    switch self {
    case .done, .alreadyAnswered, .elsewhere: return nil
    case .noPasscode: return WatchL10n.lockToAllow
    case .offline: return WatchL10n.offline
    case .forbidden(let why): return why
    case .outOfCredits: return WatchL10n.outOfCredits
    case .refused(let why): return why ?? WatchL10n.couldntReach
    case .failed: return WatchL10n.couldntReach
    }
  }
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
  /// The phone gave a server this watch can't call (plain http that isn't on the local network).
  @Published var needsHttps = false
  /// A short line across the top: an ask that was kept, or one that couldn't be sent.
  @Published var notice: String?
  /// One that came up while nobody was looking (the app in the background): said when the app is
  /// next in front.
  private var heldNotice: String?
  /// What went wrong answering from a notification, by request or suggestion id. Its screen takes
  /// it when it opens, or at once when it is open already; one nobody took is dropped after a while.
  @Published private(set) var pendingNotes: [String: String] = [:]
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
  /// When the phone was last asked to sign this watch in.
  private var lastPhoneAsk = Date.distantPast
  /// Why the phone last said no (`sign_in_failed`'s reason), until the person asks again.
  private var lastFailReason: String?
  /// A sign-in code is being fetched: the screen still says it is waiting on the phone.
  private var fetchingCode = false
  /// The app started while the keychain couldn't be read (woken before the watch's first unlock
  /// since it restarted). It may well be signed in, so it looks again when it comes forward.
  private var keyLocked = false
  private var codeTask: Task<Void, Never>?
  private var refreshTask: Task<Void, Never>?
  /// A refresh was asked for while one was running: run once more after it.
  private var refreshAgain = false
  private let pathMonitor = NWPathMonitor()
  private var started = false
  private var pushToken: String?

  // MARK: Start

  func start() {
    guard !started else { return }
    started = true
    #if DEBUG
    if let raw = UserDefaults.standard.string(forKey: "CasamaWatchServer"),
       let url = URL(string: raw), WatchServer.usable(url) {
      WatchAccount.server = url
    }
    #endif
    loadSaved()
    // A recording left by an ask that never finished (the app was closed mid-send).
    AskQueueStore.purgeTemp()
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
    } else if WatchAccount.accepted, WatchKeyStore.isLocked || WKApplication.shared().applicationState == .background {
      // Signed in, but the key can't be read right now: a push or a refresh woke the app before
      // the watch was first unlocked since it restarted. That isn't "never signed in": nothing is
      // asked of the phone, no new key is made and nothing is wiped. becameActive() looks again,
      // when the person has the watch open (and so unlocked).
      keyLocked = true
      phase = .signingIn(waiting: false)
    } else if WatchAccount.removed {
      phase = .signedOut
    } else {
      #if DEBUG
      // Simulator captures and UI tests with no iPhone: `-CasamaWatchCode YES` goes straight to a code.
      if UserDefaults.standard.bool(forKey: "CasamaWatchCode") {
        startCode()
        return
      }
      #endif
      if WKApplication.shared().applicationState == .background {
        // Woken in the background (a refresh, a push): the phone is asked when the person opens
        // the app (becameActive), not behind their back.
        phase = .signingIn(waiting: true)
      } else {
        askPhoneToSignIn()
      }
    }
    if let link = WatchOpen.takePending() { open(link) }
    #if DEBUG
    // Simulator captures: `-CasamaWatchOpen casama://app/…` opens that screen (watchOS simulators
    // can't open links from simctl).
    if phase == .signedIn, let raw = UserDefaults.standard.string(forKey: "CasamaWatchOpen"),
       let url = URL(string: raw) {
      open(WatchLink.parse(url))
    }
    #endif
  }

  /// The app came forward: refresh, and pick up anything an intent left.
  func becameActive() {
    if phase == .signedIn {
      refresh()
    } else if keyLocked {
      // Started before the key could be read. The person is looking now, so the watch is unlocked.
      if !adoptKeyIfReadable(), !WatchKeyStore.isLocked {
        // The key really is gone: sign in again.
        keyLocked = false
        askPhoneToSignIn()
      }
    } else if PhoneReask.allowed(
      waiting: phase == .signingIn(waiting: true), lastAsk: lastPhoneAsk, now: Date(),
      lastReason: lastFailReason, needsHttps: needsHttps, fetchingCode: fetchingCode) {
      // Still waiting on the phone: ask again, in case the first request never arrived or the
      // phone has only now been signed in. Same key, a new request id; the screen stays as it is.
      askPhoneToSignIn(quiet: true)
    }
    if let link = WatchOpen.takePending() { open(link) }
    // Something that went wrong while nobody was looking (a kept ask that was given up on).
    if let held = heldNotice {
      heldNotice = nil
      show(held)
    }
  }

  /// Started before the key could be read (`keyLocked`): when it reads now, the watch was signed
  /// in all along. Answers whether it is. Also asked before a notification's button is handled,
  /// which can come before the app is in front.
  @discardableResult
  func adoptKeyIfReadable() -> Bool {
    guard keyLocked, phase != .signedIn, WatchAccount.accepted, WatchKeyStore.read() != nil else { return false }
    keyLocked = false
    phase = .signedIn
    refresh()
    registerForPushes()
    return true
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
    guard refreshTask == nil else {
      // Something changed while this one was in flight (the phone switched workspace, an answer
      // was just given): it may have read the old state, so run once more when it ends.
      refreshAgain = true
      return
    }
    refreshTask = Task { [weak self] in
      repeat {
        self?.refreshAgain = false
        await self?.doRefresh()
      } while self?.refreshAgain == true && self?.phase == .signedIn
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
      // The key answers for its own workspace. When that isn't the one saved here (the phone moved
      // this watch while it was away), take the server's word and drop what was saved for the old one.
      if !fresh.orgId.isEmpty, fresh.orgId != WatchAccount.orgId {
        WatchAccount.orgId = fresh.orgId
        GlanceCache.wipe(keepMe: true)
        glance = nil
        savedAt = nil
        refreshAgain = true
      }
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

  /// Asks the iPhone to sign this watch in. [quiet] asks again without changing the screen.
  func askPhoneToSignIn(quiet: Bool = false) {
    WatchAccount.removed = false
    if !quiet {
      // The person asked: a code on its way is dropped, and what the screen said about the last
      // try goes. A quiet ask leaves all of that as it is.
      codeTask?.cancel()
      fetchingCode = false
      needsHttps = false
      lastFailReason = nil
    }
    guard let key = WatchKeyStore.readOrCreate() else {
      phase = .signingIn(waiting: true)
      return
    }
    let id = UUID().uuidString
    let fingerprint = WatchKeyMaker.fingerprint(key)
    // Remembered with the key it is for: only an answer to one of these signs the watch in.
    WatchAccount.signIns = WatchAccount.signIns.adding(id, for: fingerprint)
    signInRequest = id
    lastPhoneAsk = Date()
    if !quiet { phase = .signingIn(waiting: false) }
    var message: [String: Any] = [
      "type": "sign_in",
      "request_id": id,
      "fingerprint": fingerprint,
      "platform": "watchos",
      "name": WatchDevice.name,
      "app_version": WatchDeviceInfo.appVersion,
      "os_version": WatchDeviceInfo.osVersion,
    ]
    if let model = WatchDevice.model { message["model"] = model }
    PhoneLink.shared.send(message)
    guard !quiet else { return }
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
      // Only an answer to a request this watch made for the key it holds now: one made for a key
      // since wiped, or for another watch, would mark this watch signed in with a key the server
      // doesn't know.
      guard let key = WatchKeyStore.read(),
            WatchAccount.signIns.accepts(message["request_id"] as? String, for: WatchKeyMaker.fingerprint(key)) else { return }
      // The phone app reaches a plain-http server anywhere; the watch only one on the local network.
      guard WatchServer.usable(server) else {
        needsHttps = true
        phase = .signingIn(waiting: true)
        return
      }
      codeTask?.cancel()
      finishSignIn(server: server, orgId: org, orgName: message["org_name"] as? String ?? "", person: message["person_name"] as? String ?? "")
    case "sign_in_failed":
      // Why, so a No on the phone (`declined`) isn't asked again by itself (becameActive).
      if case .signingIn = phase {
        lastFailReason = message["reason"] as? String
        phase = .signingIn(waiting: true)
      }
    case "context":
      guard phase == .signedIn else { return }
      if let raw = message["server"] as? String, let server = URL(string: raw), WatchServer.usable(server) { WatchAccount.server = server }
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
    needsHttps = false
    lastFailReason = nil
    fetchingCode = false
    keyLocked = false
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
    needsHttps = false
    guard let key = WatchKeyStore.readOrCreate(), let base = WatchAccount.serverOrDefault else {
      codeFailed = true
      return
    }
    let device = WatchDeviceBody(
      fingerprint: WatchKeyMaker.fingerprint(key), name: WatchDevice.name, model: WatchDevice.model,
      appVersion: WatchDeviceInfo.appVersion, osVersion: WatchDeviceInfo.osVersion)
    fetchingCode = true
    codeTask = Task { [weak self] in
      let code: WatchCode
      do {
        code = try await WatchAPI.requestCode(base: base, device: device)
      } catch {
        // Dropped for another way in (Try again, a newer code request): that one owns the screen.
        if Task.isCancelled { return }
        await MainActor.run {
          self?.fetchingCode = false
          self?.codeFailed = true
        }
        return
      }
      if Task.isCancelled { return }
      await MainActor.run {
        self?.fetchingCode = false
        self?.phase = .code(code)
      }
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
      if Task.isCancelled { return }
      await MainActor.run {
        if case .code = self?.phase { self?.phase = .codeExpired }
      }
    }
  }

  func cancelCode() {
    codeTask?.cancel()
    askPhoneToSignIn()
  }

  /// Sign out of this watch: the server forgets the key, the watch forgets everything. The server
  /// is told first, with a short wait: once the key is wiped there is nothing left to tell it with.
  func signOut() async {
    if let api = WatchAPI.current() { try? await api.signOut() }
    WatchSync.wipe(removed: true)
    resetToSignedOut()
  }

  /// The server said this watch's key is gone (a 401 from anywhere).
  func keyGone() {
    handleSignedOut()
  }

  private func handleSignedOut() {
    WatchSync.signedOut()
    resetToSignedOut()
  }

  private func resetToSignedOut() {
    codeTask?.cancel()
    fetchingCode = false
    lastFailReason = nil
    keyLocked = false
    heldNotice = nil
    // Stop this watch's own pushes too: if the server couldn't be told (signed out offline), its
    // copy of the token would otherwise keep delivering this account's alerts here.
    WKApplication.shared().unregisterForRemoteNotifications()
    pushToken = nil
    pendingNotes = [:]
    notice = nil
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
    #if DEBUG
    // Simulator captures can't tap the system prompt: `-CasamaWatchNoPush YES` skips it.
    if UserDefaults.standard.bool(forKey: "CasamaWatchNoPush") { return }
    #endif
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

  /// Something from the person's other workspace (a notification the iPhone mirrored): this
  /// watch's key can't answer it, so say so and offer Open on iPhone.
  func showElsewhere(_ seed: NeedSeed) {
    guard phase == .signedIn else { return }
    path = [.phoneOnly(seed)]
  }

  /// Leaves what went wrong for the screen of the request or suggestion with [id]. A screen that
  /// is open already sees it at once (it watches `pendingNotes`); one nobody opened in a while is
  /// dropped, so it can't turn up under that request much later.
  func leaveNote(_ text: String?, for id: String) {
    guard let text, !text.isEmpty else {
      pendingNotes[id] = nil
      return
    }
    pendingNotes[id] = text
    Task { [weak self] in
      try? await Task.sleep(nanoseconds: 20_000_000_000)
      guard let self, self.pendingNotes[id] == text else { return }
      self.pendingNotes[id] = nil
    }
  }

  func takeNote(for id: String) -> String? {
    pendingNotes.removeValue(forKey: id)
  }

  /// Says a short line across the top for a few seconds, when the person can see it: one that
  /// comes up while the app isn't in front (a kept ask given up on during a background refresh)
  /// waits until it is (becameActive).
  func say(_ text: String) {
    guard WKApplication.shared().applicationState == .active else {
      heldNotice = text
      return
    }
    show(text)
  }

  private func show(_ text: String) {
    notice = text
    Task { [weak self] in
      try? await Task.sleep(nanoseconds: 3_500_000_000)
      guard let self, self.notice == text else { return }
      self.notice = nil
    }
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
  func allow(_ approval: WatchApproval, surface: String = WatchSurface.app) async -> ActionResult {
    guard approval.isPending else { return .alreadyAnswered }
    guard approval.canAllow != .phone else { return .forbidden(approval.whyPhoneText) }
    switch await WristCheck.check() {
    case .ok: break
    case .noPasscode: return .noPasscode
    case .failed: return .failed
    }
    return await perform { try await $0.decide(approval.id, allow: true, surface: surface) }
  }

  func deny(_ approvalId: String, surface: String = WatchSurface.app) async -> ActionResult {
    await perform { try await $0.decide(approvalId, allow: false, surface: surface) }
  }

  func doIt(_ suggestionId: String, surface: String = WatchSurface.app) async -> ActionResult {
    await perform { _ = try await $0.acceptSuggestion(suggestionId, surface: surface) }
  }

  func notNow(_ suggestionId: String, surface: String = WatchSurface.app) async -> ActionResult {
    await perform { try await $0.dismissSuggestion(suggestionId, surface: surface) }
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
      case .conflict(let problem), .notFound(let problem), .refused(_, let problem):
        // The code says which it is: answered already, in another workspace, out of credits, or
        // a run the server couldn't start (docs/WATCH-PROTOCOL.md §1).
        online = true
        refresh()
        switch WatchRefusal.of(status: e.status ?? 409, problem: problem) {
        case .alreadyAnswered: return .alreadyAnswered
        case .elsewhere: return .elsewhere
        case .outOfCredits: return .outOfCredits
        case .refused(let why): return .refused(why)
        }
      case .forbidden(let problem):
        // `watch_allow_refused` gives its reason as a word (high_risk, setting…): say it in the
        // person's words, never the word itself.
        if let why = WatchWhy.text(problem?.detail) { return .forbidden(why) }
        return .forbidden(problem?.code == "watch_allow_refused" ? nil : problem?.detail)
      case .offline:
        online = false
        return .offline
      default: return .failed
      }
    } catch {
      return .failed
    }
  }

  /// Open on iPhone (§6.10). The phone app is told the link, and says whether it is open in front
  /// of the person. If it is, that's all. If it isn't (in a pocket, not running, an older app that
  /// doesn't say, or out of reach) the server leaves a notification on the person's phones, so
  /// there is something to tap when they pick the phone up.
  @discardableResult
  func openOnPhone(link: String, title: String) async -> Bool {
    guard !link.isEmpty else { return false }
    let route = link.hasPrefix("/") ? link : "/" + link
    let reply = await PhoneLink.shared.ask(["type": "open", "link": route])
    if (reply?["front"] as? Bool) == true {
      showFlash(.sent, pop: false)
      return true
    }
    if let api = WatchAPI.current() {
      do {
        try await api.handoff(link: route, title: title.isEmpty ? WatchL10n.openOnIphone : title)
        showFlash(.sent, pop: false)
        return true
      } catch WatchAPIError.signedOut {
        handleSignedOut()
        return false
      } catch WatchAPIError.offline {
        online = false
      } catch {}
    }
    // No notification could be left, but the phone app has the link and opens there when it
    // comes forward.
    if reply != nil {
      showFlash(.sent, pop: false)
      return true
    }
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
      // A refusal that won't change (nothing heard, no such bot, out of credits) ends it. A server
      // that failed, or a voice service that was down, may be fine next time: keep it for a few
      // more tries. Either way the person is told when what they asked is given up on.
      let tries = AskQueueStore.noteTry(ask.id)
      if AskQueuePolicy.afterFailure(status: WatchAPI.map(error).status, tries: tries) == .keep {
        queue = AskQueueStore.all()
        return false
      }
      AskQueueStore.remove(ask.id)
      queue = AskQueueStore.all()
      say(WatchL10n.askDropped(WatchTime.past(ask.askedAt)))
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
