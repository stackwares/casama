import CoreGraphics
import Foundation
import ImageIO

// MARK: - A bot's own picture (docs/BOT-PICTURES-PLAN.md §5)
//
// `bots.avatar_url` holds `image:<uuid>:<rrggbb><rrggbb>` when a bot has a picture: the picture's id
// and the two colours the server took from it. Widgets, Live Activities and the watch can't lean
// on the app's image cache, so each keeps its own copy of the 128 px PNG as a file and the mark
// reads that file; a missing file draws the initials on the picture's colours instead.
//
// Foundation, CoreGraphics and ImageIO only, so every target that draws a bot's mark (the iPhone
// app, both widget extensions, the Mac widgets, the watch and its complications) compiles it.

enum BotPicture {
  /// The picture a stored avatar value names, with its two colours, or nil for anything else
  /// (initials, mascots, old web links, typos). Strict like the shared test vectors
  /// (packages/domain/test/fixtures/bot-avatar-vectors.json): lowercase only, nothing around it.
  static func parse(_ avatar: String?) -> (id: String, colors: (UInt32, UInt32))? {
    guard let avatar else { return nil }
    let u = Array(avatar.utf8)
    // `image:` + 36-character uuid + `:` + 12 hex digits.
    guard u.count == 55, u.starts(with: Array("image:".utf8)), u[42] == UInt8(ascii: ":") else { return nil }
    let id = Array(u[6..<42])
    guard isUUID(id) else { return nil }
    guard let a = hex(u[43..<49]), let b = hex(u[49..<55]) else { return nil }
    return (String(decoding: id, as: UTF8.self), (a, b))
  }

  /// Whether [id] is a lowercase uuid. Checked before an id becomes part of a file path or a URL.
  static func isValidId(_ id: String) -> Bool { isUUID(Array(id.utf8)) }

  /// The ids of every picture named by [avatars].
  static func ids(_ avatars: [String?]) -> Set<String> {
    Set(avatars.compactMap { parse($0)?.id })
  }

  private static func isUUID(_ u: [UInt8]) -> Bool {
    guard u.count == 36 else { return false }
    for (i, c) in u.enumerated() {
      if i == 8 || i == 13 || i == 18 || i == 23 {
        if c != UInt8(ascii: "-") { return false }
      } else if digit(c) == nil {
        return false
      }
    }
    return true
  }

  private static func hex(_ s: ArraySlice<UInt8>) -> UInt32? {
    var v: UInt32 = 0
    for c in s {
      guard let d = digit(c) else { return nil }
      v = v << 4 | UInt32(d)
    }
    return v
  }

  /// 0-9 and a-f; capitals are not a picture value.
  private static func digit(_ c: UInt8) -> UInt8? {
    switch c {
    case UInt8(ascii: "0")...UInt8(ascii: "9"): return c - UInt8(ascii: "0")
    case UInt8(ascii: "a")...UInt8(ascii: "f"): return c - UInt8(ascii: "a") + 10
    default: return nil
    }
  }
}

/// The picture files, `bot-images/<id>.png`, kept where the process that draws them can read them.
/// Ids never change what a picture shows, so a file is never replaced, only fetched once and later
/// deleted when no bot uses it.
final class BotPictureStore: @unchecked Sendable {
  static let shared = BotPictureStore()

  /// A widget has little time to build its timeline.
  static let timeout: TimeInterval = 8
  /// 128 px PNGs are a few KB; anything bigger isn't the picture we asked for.
  static let maxBytes = 256 * 1024
  /// A file younger than this survives a prune: another process (the app starting a Live Activity,
  /// a widget that just fetched) may still be about to draw it from a list this one never saw.
  static let pruneGrace: TimeInterval = 24 * 3600
  /// Maximum decoded bitmaps kept in memory: smaller on watchOS so complication extensions stay well
  /// under their 30 MB memory ceiling.
  static let maxMemoryEntries: Int = {
    #if os(watchOS)
    return 12
    #else
    return 24
    #endif
  }()

  /// The app group the process shares files through: the app with its widgets and Live Activities,
  /// or the watch app with its complications. The Mac one is named after the team, because a
  /// sandboxed extension can only use that.
  static let groupId: String = {
    #if os(watchOS)
    return "group.ai.casama.app.watch"
    #elseif os(macOS)
    return "V8V5US964Z.ai.casama.app"
    #else
    return "group.ai.casama.app"
    #endif
  }()

  private let session: URLSession
  private let lock = NSLock()
  private var memory: [String: CGImage] = [:]
  private let fixedDirectory: URL?

  /// [directory] is for tests; the shared store uses the app group, then the caches folder.
  init(directory: URL? = nil) {
    fixedDirectory = directory
    let c = URLSessionConfiguration.ephemeral
    c.timeoutIntervalForRequest = Self.timeout
    c.timeoutIntervalForResource = Self.timeout
    c.waitsForConnectivity = false
    c.requestCachePolicy = .reloadIgnoringLocalCacheData
    session = URLSession(configuration: c)
  }

  /// The folder the files are in. With no app group container (a build without the entitlement, a
  /// simulator quirk) this process's caches folder, which only it can read.
  var directory: URL? {
    let fm = FileManager.default
    let base = fixedDirectory
      ?? fm.containerURL(forSecurityApplicationGroupIdentifier: Self.groupId)?.appendingPathComponent("bot-images", isDirectory: true)
      ?? fm.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("bot-images", isDirectory: true)
    guard let base else { return nil }
    try? fm.createDirectory(at: base, withIntermediateDirectories: true)
    return base
  }

  func file(_ id: String) -> URL? {
    guard BotPicture.isValidId(id) else { return nil }
    return directory?.appendingPathComponent("\(id).png")
  }

  /// The picture, read from disk (a widget reads it on the main thread while drawing, so no
  /// network here), or nil when this process doesn't have the file yet.
  func image(_ id: String) -> CGImage? {
    lock.lock()
    if let hit = memory[id] {
      lock.unlock()
      return hit
    }
    lock.unlock()
    guard let url = file(id), let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
    lock.lock()
    // A mark is a handful of bots; a small cache is enough and keeps a widget's memory low.
    if memory.count >= Self.maxMemoryEntries { memory.removeAll() }
    memory[id] = image
    lock.unlock()
    return image
  }

  func has(_ id: String) -> Bool {
    guard let url = file(id) else { return false }
    return FileManager.default.fileExists(atPath: url.path)
  }

  /// Downloads the pictures in [ids] that aren't on disk yet from `GET {server}/v1/bot-images/{id}`
  /// (no token: the pictures are public, immutable and cached forever). Never throws; whatever
  /// can't be fetched stays missing and the mark shows initials.
  func ensure(ids: [String], server: URL) async {
    let missing = Set(ids).filter { BotPicture.isValidId($0) && !has($0) }
    guard !missing.isEmpty else { return }
    await withTaskGroup(of: Void.self) { group in
      for id in missing {
        group.addTask { await self.download(id, server: server) }
      }
    }
  }

  private func download(_ id: String, server: URL) async {
    guard let target = file(id),
          var c = URLComponents(url: server.appendingPathComponent("v1/bot-images/\(id)"), resolvingAgainstBaseURL: false) else { return }
    c.queryItems = [URLQueryItem(name: "size", value: "128"), URLQueryItem(name: "format", value: "png")]
    guard let url = c.url else { return }
    var request = URLRequest(url: url)
    request.setValue("image/png", forHTTPHeaderField: "Accept")
    guard let (data, response) = try? await session.data(for: request),
          (response as? HTTPURLResponse)?.statusCode == 200,
          data.count <= Self.maxBytes, Self.isPNG(data) else { return }
    try? data.write(to: target, options: .atomic)
  }

  /// Deletes the files of pictures no longer in [keep]. Pass the full set the process knows about
  /// (every bot of the glance and the canvases), never a partial one.
  func prune(keep: Set<String>, now: Date = Date()) {
    lock.lock()
    memory = memory.filter { keep.contains($0.key) }
    lock.unlock()
    guard let dir = directory,
          let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
    for f in files where f.pathExtension == "png" {
      let id = f.deletingPathExtension().lastPathComponent
      if keep.contains(id) { continue }
      let modified = (try? f.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
      if let modified, now.timeIntervalSince(modified) < Self.pruneGrace { continue }
      try? FileManager.default.removeItem(at: f)
    }
  }

  /// The eight bytes every PNG starts with.
  static func isPNG(_ data: Data) -> Bool {
    data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
  }
}
