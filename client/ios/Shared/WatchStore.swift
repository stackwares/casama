import Foundation

// MARK: - What the watch keeps (D-410 §10)
//
// Who it is signed in as, its settings, the last glance and the last chats it showed, and asks kept
// while offline: all in the app group the watch app shares with its complications, so they open
// from the same data. Everything here is wiped at sign-out. The key itself is in the keychain
// (WatchKeyStore.swift), never here.

enum WatchGroup {
  /// The watch app and its widget extension share this group (CasamaWatch.entitlements).
  static let id = "group.ai.casama.app.watch"

  static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }

  static var container: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
  }
}

enum WatchAccount {
  /// Code sign-in goes to Casama Cloud; a self-hosted server signs a watch in through the phone.
  static let defaultServer = "https://api.casama.ai"

  private enum K {
    static let server = "server"
    static let orgId = "org_id"
    static let orgName = "org_name"
    static let person = "person_name"
    static let accepted = "accepted"
    static let removed = "removed"
    static let askBot = "ask_bot"
    static let lastAskBot = "last_ask_bot"
    static let hideWristDown = "hide_wrist_down"
    static let readAloud = "read_aloud"
    static let pushSent = "push_sent"
    static let welcomed = "welcomed"
    static let signIns = "sign_in_requests"
  }

  private static var d: UserDefaults { WatchGroup.defaults }

  /// The server's API base without a trailing slash.
  static var server: URL? {
    get {
      guard var raw = d.string(forKey: K.server)?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return nil }
      while raw.hasSuffix("/") { raw.removeLast() }
      guard let url = URL(string: raw), let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else { return nil }
      return url
    }
    set { d.set(newValue?.absoluteString, forKey: K.server) }
  }

  static var serverOrDefault: URL? { server ?? URL(string: defaultServer) }

  /// Whether the server is Casama Cloud (Handoff through casama.ai/open links only works there).
  static var isCloud: Bool { (server?.host ?? "api.casama.ai") == "api.casama.ai" }

  static var orgId: String? {
    get { d.string(forKey: K.orgId) }
    set { d.set(newValue, forKey: K.orgId) }
  }
  static var orgName: String {
    get { d.string(forKey: K.orgName) ?? "" }
    set { d.set(newValue, forKey: K.orgName) }
  }
  static var personName: String {
    get { d.string(forKey: K.person) ?? "" }
    set { d.set(newValue, forKey: K.person) }
  }
  /// The server has accepted this watch's key.
  static var accepted: Bool {
    get { d.bool(forKey: K.accepted) }
    set { d.set(newValue, forKey: K.accepted) }
  }
  /// The key was removed (a 401, or Sign out): the watch says so until it signs in again.
  static var removed: Bool {
    get { d.bool(forKey: K.removed) }
    set { d.set(newValue, forKey: K.removed) }
  }
  /// "Signed in as …" has been shown once.
  static var welcomed: Bool {
    get { d.bool(forKey: K.welcomed) }
    set { d.set(newValue, forKey: K.welcomed) }
  }
  /// The bot Ask uses when the person picked one in Settings.
  static var askBot: String? {
    get { d.string(forKey: K.askBot) }
    set { d.set(newValue, forKey: K.askBot) }
  }
  /// The bot the person last asked: Ask opens to it.
  static var lastAskBot: String? {
    get { d.string(forKey: K.lastAskBot) }
    set { d.set(newValue, forKey: K.lastAskBot) }
  }
  /// Hide details when the wrist is down: on unless turned off.
  static var hideWhenWristDown: Bool {
    get { d.object(forKey: K.hideWristDown) as? Bool ?? true }
    set { d.set(newValue, forKey: K.hideWristDown) }
  }
  /// Read replies aloud: off unless turned on.
  static var readAloud: Bool {
    get { d.bool(forKey: K.readAloud) }
    set { d.set(newValue, forKey: K.readAloud) }
  }
  /// The push token, key and server last registered, so it is sent once.
  static var pushSent: String? {
    get { d.string(forKey: K.pushSent) }
    set { d.set(newValue, forKey: K.pushSent) }
  }

  /// The sign-in requests this watch sent the phone, with the key they were for (WatchLogic).
  static var signIns: IssuedSignIns {
    get {
      guard let data = d.data(forKey: K.signIns), let v = try? JSONDecoder().decode(IssuedSignIns.self, from: data) else { return .none }
      return v
    }
    set { d.set(try? JSONEncoder().encode(newValue), forKey: K.signIns) }
  }

  /// Signs this watch in: where its server is and who it belongs to.
  static func signIn(server: URL, orgId: String, orgName: String, person: String) {
    self.server = server
    self.orgId = orgId
    self.orgName = orgName
    self.personName = person
    accepted = true
    removed = false
    welcomed = false
    // Answered: later answers to the same requests are not sign-ins.
    d.removeObject(forKey: K.signIns)
  }

  /// Forgets everything about the account. The server's address stays, so signing in again
  /// through a code goes to the same place.
  static func wipe(removed wasRemoved: Bool) {
    for key in [K.orgId, K.orgName, K.person, K.accepted, K.askBot, K.lastAskBot, K.pushSent, K.welcomed, K.signIns] {
      d.removeObject(forKey: key)
    }
    removed = wasRemoved
  }
}

// MARK: - The last glance, who the watch is, the last chats

enum GlanceCache {
  private enum K {
    static let glance = "glance"
    static let glanceSaved = "glance_saved"
    static let etag = "glance_etag"
    static let me = "me"
    static let chatPrefix = "chat_"
    static let chats = "chat_keys"
  }

  private static var d: UserDefaults { WatchGroup.defaults }

  struct Saved {
    var glance: Glance
    var savedAt: Date
    var etag: String?
  }

  static func saveGlance(_ data: Data, etag: String?, at date: Date = Date()) {
    d.set(data, forKey: K.glance)
    d.set(date.timeIntervalSince1970, forKey: K.glanceSaved)
    d.set(etag, forKey: K.etag)
  }

  /// Notes that the server said the saved glance is still current (a 304).
  static func touchGlance(at date: Date = Date()) {
    d.set(date.timeIntervalSince1970, forKey: K.glanceSaved)
  }

  static func glance() -> Saved? {
    guard let data = d.data(forKey: K.glance), let g = try? WatchJSON.decoder().decode(Glance.self, from: data) else { return nil }
    let t = d.double(forKey: K.glanceSaved)
    return Saved(glance: g, savedAt: t > 0 ? Date(timeIntervalSince1970: t) : Date.distantPast, etag: d.string(forKey: K.etag))
  }

  static func saveMe(_ data: Data) { d.set(data, forKey: K.me) }

  static func me() -> WatchSelf? {
    guard let data = d.data(forKey: K.me) else { return nil }
    return try? WatchJSON.decoder().decode(WatchSelf.self, from: data)
  }

  static func saveChat(bot: String, data: Data) {
    d.set(data, forKey: K.chatPrefix + bot)
    var keys = Set(d.stringArray(forKey: K.chats) ?? [])
    keys.insert(bot)
    d.set(Array(keys), forKey: K.chats)
  }

  static func chat(bot: String) -> WatchChat? {
    guard let data = d.data(forKey: K.chatPrefix + bot) else { return nil }
    return try? WatchJSON.decoder().decode(WatchChat.self, from: data)
  }

  /// Forgets the saved glance and chats. [keepMe] keeps who the watch is and the person's own
  /// settings (hide reply text, show details), which don't change with the workspace.
  static func wipe(keepMe: Bool = false) {
    for bot in d.stringArray(forKey: K.chats) ?? [] { d.removeObject(forKey: K.chatPrefix + bot) }
    for key in [K.glance, K.glanceSaved, K.etag, K.chats] { d.removeObject(forKey: key) }
    if !keepMe { d.removeObject(forKey: K.me) }
  }
}

// MARK: - Asks kept while offline

enum AskQueueStore {
  private static let key = "ask_queue"
  private static var d: UserDefaults { WatchGroup.defaults }

  /// Recordings wait here, not in preferences: they can be a megabyte.
  static var audioDir: URL? {
    let base = WatchGroup.container ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    guard let dir = base?.appendingPathComponent("asks", isDirectory: true) else { return nil }
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  static func all() -> [QueuedAsk] {
    guard let data = d.data(forKey: key), let list = try? JSONDecoder().decode([QueuedAsk].self, from: data) else { return [] }
    return list.sorted { $0.askedAt < $1.askedAt }
  }

  private static func save(_ list: [QueuedAsk]) {
    d.set(try? JSONEncoder().encode(list), forKey: key)
  }

  /// Keeps [ask]; the oldest goes when too many wait.
  static func add(_ ask: QueuedAsk) {
    var list = all()
    list.append(ask)
    while list.count > AskQueuePolicy.maxKept, let first = list.first {
      list.removeFirst()
      deleteAudio(first)
    }
    save(list)
  }

  static func remove(_ id: String) {
    var list = all()
    if let i = list.firstIndex(where: { $0.id == id }) {
      deleteAudio(list[i])
      list.remove(at: i)
    }
    save(list)
  }

  /// Counts a try the server failed for [id], and answers how many that makes.
  @discardableResult
  static func noteTry(_ id: String) -> Int {
    var list = all()
    guard let i = list.firstIndex(where: { $0.id == id }) else { return 1 }
    let tries = (list[i].tries ?? 0) + 1
    list[i].tries = tries
    save(list)
    return tries
  }

  static func audioURL(_ ask: QueuedAsk) -> URL? {
    guard let name = ask.audioFile else { return nil }
    return audioDir?.appendingPathComponent(name)
  }

  private static func deleteAudio(_ ask: QueuedAsk) {
    if let url = audioURL(ask) { try? FileManager.default.removeItem(at: url) }
  }

  static func wipe() {
    for ask in all() { deleteAudio(ask) }
    d.removeObject(forKey: key)
    purgeTemp()
  }

  /// A recording being made or sent waits in the temp folder under this name.
  static func tempRecordingURL() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("\(tempPrefix)\(UUID().uuidString).m4a")
  }

  private static let tempPrefix = "ask-"

  /// Removes recordings left in the temp folder (a send that failed, an app that was closed
  /// mid-ask): nothing from a recording is kept unless the ask itself is kept.
  static func purgeTemp() {
    let dir = FileManager.default.temporaryDirectory
    for name in (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
    where name.hasPrefix(tempPrefix) && name.hasSuffix(".m4a") {
      try? FileManager.default.removeItem(at: dir.appendingPathComponent(name))
    }
  }
}
