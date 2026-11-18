import Foundation
import ImageIO

// MARK: - A widget that fetches for itself (D-405 Phase 3, §8.3)
//
// With a widget key in the shared keychain group and the server's address in the app group, a
// timeline refresh asks the server for the glance (`Authorization: Widget <key>`, `If-None-Match`
// with the version it has), writes what it gets back where the app writes it, and fetches creation
// covers for the widgets that show them. Any failure leaves the stored data as it is: a widget
// shows what it has and says how old it is. Shared by the iPhone and Mac widget extensions.

enum GlanceFetch {
  /// A widget has little time to build its timeline.
  static let timeout: TimeInterval = 8
  /// Covers bigger than this aren't kept: a widget's memory is small.
  static let maxCoverBytes = 3_000_000

  private static let session: URLSession = {
    let c = URLSessionConfiguration.ephemeral
    c.timeoutIntervalForRequest = timeout
    c.timeoutIntervalForResource = timeout
    c.waitsForConnectivity = false
    c.requestCachePolicy = .reloadIgnoringLocalCacheData
    return URLSession(configuration: c)
  }()

  /// The server's API base, as the app wrote it, without a trailing slash.
  static func server(_ defaults: UserDefaults? = GlanceStore.defaults) -> URL? {
    guard var raw = defaults?.string(forKey: GlanceStore.serverKey)?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return nil }
    while raw.hasSuffix("/") { raw.removeLast() }
    return URL(string: raw)
  }

  /// What a widget should draw now: the stored glance, refreshed from the server first when this
  /// device holds a widget key. Never throws and never takes much longer than [timeout].
  static func refresh() async -> GlanceSnapshot {
    var snap = GlanceSnapshot.load()
    guard snap.signedIn, let current = snap.glance, let key = WidgetKey.read(), let base = server() else { return snap }
    if let fresh = await fetch(base: base, key: key, current: current) {
      snap.glance = fresh
    }
    snap.glance?.checkedAt = GlanceStore.checkedAt()
    await sendPushToken(base: base, key: key)
    return snap
  }

  /// GET /v1/glance. Answers the new glance, the current one when the server says it hasn't
  /// changed, or nil when it couldn't ask.
  private static func fetch(base: URL, key: String, current: Glance) async -> Glance? {
    guard var c = URLComponents(url: base.appendingPathComponent("v1/glance"), resolvingAgainstBaseURL: false) else { return nil }
    c.queryItems = [URLQueryItem(name: "org_id", value: current.orgId)]
    guard let url = c.url else { return nil }
    var req = URLRequest(url: url)
    req.setValue("Widget \(key)", forHTTPHeaderField: "Authorization")
    req.setValue("\"\(current.version)\"", forHTTPHeaderField: "If-None-Match")
    req.setValue("application/json", forHTTPHeaderField: "Accept")
    guard let (data, response) = try? await session.data(for: req), let http = response as? HTTPURLResponse else { return nil }
    let defaults = GlanceStore.defaults
    switch http.statusCode {
    case 304:
      GlanceStore.markChecked(defaults)
      return current
    case 200:
      guard let fresh = try? GlanceStore.decoder().decode(Glance.self, from: data) else { return nil }
      GlanceStore.markChecked(defaults)
      // The app may have written a newer one while this was in flight: keep the newest.
      if let stored = GlanceStore.glance(from: defaults), stored.madeAt > fresh.madeAt { return stored }
      if let text = String(data: data, encoding: .utf8) { defaults?.set(text, forKey: GlanceStore.glanceKey) }
      return fresh
    default:
      return nil
    }
  }

  // MARK: Covers (the Library widget, Today's extra large strip)

  private static var coverDir: URL? {
    guard let dir = GlanceStore.container?.appendingPathComponent("covers", isDirectory: true) else { return nil }
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  private static func coverFile(_ c: Glance.Creation) -> URL? {
    coverDir?.appendingPathComponent("\(c.id)-\(c.version).img")
  }

  /// The cover file of each of [creations] that has one, fetching any not cached yet when a key
  /// allows (GET /v1/creations/{id}/cover). Covers no longer listed are deleted.
  static func covers(for creations: [Glance.Creation]) async -> [String: URL] {
    let wanted = creations.filter(\.hasCover)
    var out: [String: URL] = [:]
    var missing: [(Glance.Creation, URL)] = []
    for c in wanted {
      guard let file = coverFile(c) else { continue }
      if FileManager.default.fileExists(atPath: file.path) { out[c.id] = file } else { missing.append((c, file)) }
    }
    if !missing.isEmpty, let key = WidgetKey.read(), let base = server() {
      await withTaskGroup(of: (String, URL)?.self) { group in
        for (c, file) in missing {
          group.addTask {
            var req = URLRequest(url: base.appendingPathComponent("v1/creations/\(c.id)/cover"))
            req.setValue("Widget \(key)", forHTTPHeaderField: "Authorization")
            guard let (data, response) = try? await session.data(for: req),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  !data.isEmpty, data.count <= maxCoverBytes,
                  (try? data.write(to: file, options: .atomic)) != nil else { return nil }
            return (c.id, file)
          }
        }
        for await item in group { if let (id, file) = item { out[id] = file } }
      }
    }
    // Keep only the covers of what is listed now.
    if let dir = coverDir, let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
      let keep = Set(wanted.compactMap { coverFile($0)?.lastPathComponent })
      for f in files where !keep.contains(f.lastPathComponent) { try? FileManager.default.removeItem(at: f) }
    }
    return out
  }

  /// A cover, scaled down to about [pixels] on its long side, for drawing in a widget.
  static func coverImage(_ file: URL, pixels: Int = 480) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(file as CFURL, nil) else { return nil }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: pixels,
    ]
    return CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary)
  }

  // MARK: Refresh pushes (iOS 26, macOS 26)

  /// Keeps the WidgetKit push token (WidgetPush.swift); the next send or timeline refresh
  /// registers it with the server.
  static func store(pushToken: Data) {
    let hex = pushToken.map { String(format: "%02x", $0) }.joined()
    GlanceStore.defaults?.set(hex, forKey: GlanceStore.pushTokenKey)
  }

  /// Sends the stored push token now, when a key and a server allow.
  static func sendPushToken() async {
    if let key = WidgetKey.read(), let base = server() { await sendPushToken(base: base, key: key) }
  }

  /// Whether this build's push tokens belong to Apple's sandbox: a build installed from Xcode
  /// (or ad hoc) carries a provisioning profile that says aps-environment development; an App
  /// Store or TestFlight build has no embedded profile and uses production.
  static var apnsSandbox: Bool {
    #if os(macOS)
    let profile = Bundle.main.bundleURL.appendingPathComponent("Contents/embedded.provisionprofile")
    #else
    let profile = Bundle.main.bundleURL.appendingPathComponent("embedded.mobileprovision")
    #endif
    guard let data = try? Data(contentsOf: profile), let text = String(data: data, encoding: .isoLatin1) else { return false }
    return text.range(of: #"aps-environment</key>\s*<string>development</string>"#, options: .regularExpression) != nil
  }

  /// PUT /v1/widget-keys/current/push-token, once per token, key and server.
  private static func sendPushToken(base: URL, key: String) async {
    let defaults = GlanceStore.defaults
    guard let token = defaults?.string(forKey: GlanceStore.pushTokenKey), !token.isEmpty else { return }
    let marker = "\(token)|\(base.absoluteString)|\(key.suffix(8))"
    guard defaults?.string(forKey: GlanceStore.pushTokenSentKey) != marker else { return }
    var req = URLRequest(url: base.appendingPathComponent("v1/widget-keys/current/push-token"))
    req.httpMethod = "PUT"
    req.setValue("Widget \(key)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = ["token": token, "kind": "apns_widgets", "sandbox": apnsSandbox]
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)
    guard let (_, response) = try? await session.data(for: req),
          let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) else { return }
    defaults?.set(marker, forKey: GlanceStore.pushTokenSentKey)
  }
}
