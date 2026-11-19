import Foundation

// MARK: - The watch's calls to the person's server (D-410 §8.4)
//
// Plain HTTPS through URLSession, the one network path a watch can count on (no WebSockets on
// watchOS). Every call carries `Authorization: Watch <key>`; every write carries an
// Idempotency-Key so a retry on a bad connection can't send twice. A 401 means the key is gone:
// the caller wipes the watch (docs/WATCH-PROTOCOL.md §1).

enum WatchAPIError: Error, Equatable {
  /// 401: the key was removed. Wipe and show "signed out".
  case signedOut
  /// 404, with the server's code: `not_found` means "not in this watch's workspace".
  case notFound(WatchProblem?)
  /// 409: already answered, already running, or couldn't start (the code says which).
  case conflict(WatchProblem?)
  /// 403, with the server's code and reason when it gave them.
  case forbidden(WatchProblem?)
  /// Another 4xx (400 nothing heard, 402 out of credits): the server understood and said no.
  case refused(Int, WatchProblem?)
  /// 429, with how long to wait when the server said.
  case rateLimited(TimeInterval?)
  /// No connection, or it dropped.
  case offline
  case server(Int)
  case badResponse

  /// The HTTP status behind this error, when the server answered at all.
  var status: Int? {
    switch self {
    case .signedOut: return 401
    case .notFound: return 404
    case .conflict: return 409
    case .forbidden: return 403
    case .refused(let status, _): return status
    case .rateLimited: return 429
    case .server(let status): return status
    case .offline, .badResponse: return nil
    }
  }

  var problem: WatchProblem? {
    switch self {
    case .notFound(let p), .conflict(let p), .forbidden(let p), .refused(_, let p): return p
    default: return nil
    }
  }
}

/// Where on the watch an answer was made, for the server's counting (`X-Casama-Surface`).
enum WatchSurface {
  static let app = "app"
  static let notification = "notification"
  static let complication = "complication"
  static let control = "control"
  static let siri = "siri"
}

struct WatchAPI {
  let base: URL
  let key: String

  /// The signed-in watch's client, or nil when it isn't signed in.
  static func current() -> WatchAPI? {
    guard WatchAccount.accepted, let base = WatchAccount.server, let key = WatchKeyStore.read() else { return nil }
    return WatchAPI(base: base, key: key)
  }

  static let session: URLSession = {
    let c = URLSessionConfiguration.ephemeral
    c.timeoutIntervalForRequest = 20
    c.timeoutIntervalForResource = 45
    c.waitsForConnectivity = false
    c.requestCachePolicy = .reloadIgnoringLocalCacheData
    c.httpAdditionalHeaders = ["User-Agent": "CasamaWatch/\(WatchDeviceInfo.appVersion)"]
    return URLSession(configuration: c)
  }()

  /// A spoken ask: up to a minute of audio through the phone's Bluetooth link, then the server's
  /// own wait for the words (up to 60 s), so the whole exchange gets longer than a plain call.
  static let askSession: URLSession = {
    let c = URLSessionConfiguration.ephemeral
    c.timeoutIntervalForRequest = 75
    c.timeoutIntervalForResource = 120
    c.waitsForConnectivity = false
    c.requestCachePolicy = .reloadIgnoringLocalCacheData
    c.httpAdditionalHeaders = ["User-Agent": "CasamaWatch/\(WatchDeviceInfo.appVersion)"]
    return URLSession(configuration: c)
  }()

  /// Background refresh and signing out: the system gives a refresh a few seconds, so it gives up
  /// early and the saved glance stays.
  static let quickSession: URLSession = {
    let c = URLSessionConfiguration.ephemeral
    c.timeoutIntervalForRequest = 8
    c.timeoutIntervalForResource = 10
    c.waitsForConnectivity = false
    c.requestCachePolicy = .reloadIgnoringLocalCacheData
    c.httpAdditionalHeaders = ["User-Agent": "CasamaWatch/\(WatchDeviceInfo.appVersion)"]
    return URLSession(configuration: c)
  }()

  /// The run stream: the server ends it at 110 s, under Apple's 150 s cut-off for a request.
  static let streamSession: URLSession = {
    let c = URLSessionConfiguration.ephemeral
    c.timeoutIntervalForRequest = 60
    c.timeoutIntervalForResource = 140
    c.waitsForConnectivity = false
    c.requestCachePolicy = .reloadIgnoringLocalCacheData
    c.httpAdditionalHeaders = ["User-Agent": "CasamaWatch/\(WatchDeviceInfo.appVersion)"]
    return URLSession(configuration: c)
  }()

  // MARK: Plumbing

  private func url(_ path: String, query: [URLQueryItem] = []) -> URL? {
    guard var c = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false) else { return nil }
    if !query.isEmpty { c.queryItems = query }
    return c.url
  }

  private func request(_ path: String, method: String = "GET", query: [URLQueryItem] = [], body: Data? = nil,
                       idempotencyKey: String? = nil, accept: String = "application/json", surface: String? = nil) throws -> URLRequest {
    guard let u = url(path, query: query) else { throw WatchAPIError.badResponse }
    var r = URLRequest(url: u)
    r.httpMethod = method
    r.setValue("Watch \(key)", forHTTPHeaderField: "Authorization")
    r.setValue(accept, forHTTPHeaderField: "Accept")
    if let body {
      r.httpBody = body
      r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    if let idempotencyKey { r.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key") }
    if let surface { r.setValue(surface, forHTTPHeaderField: "X-Casama-Surface") }
    return r
  }

  static func map(_ error: Error) -> WatchAPIError {
    if let e = error as? WatchAPIError { return e }
    if let e = error as? URLError {
      switch e.code {
      case .badServerResponse, .cannotParseResponse, .cannotDecodeContentData, .cannotDecodeRawData, .badURL, .unsupportedURL:
        return .badResponse
      default:
        // No route, a dropped link, a timeout, a TLS failure behind a captive portal: to the person
        // these all mean "no connection", and what was saved is shown with its age.
        return .offline
      }
    }
    return .badResponse
  }

  /// Turns a status into an error, or nil when it is a success.
  static func check(_ response: URLResponse, data: Data?) -> WatchAPIError? {
    guard let http = response as? HTTPURLResponse else { return .badResponse }
    switch http.statusCode {
    case 200..<300, 304: return nil
    case 401: return .signedOut
    case 403: return .forbidden(WatchProblem.parse(data))
    case 404: return .notFound(WatchProblem.parse(data))
    case 409: return .conflict(WatchProblem.parse(data))
    case 429:
      let wait = (http.value(forHTTPHeaderField: "Retry-After")).flatMap { TimeInterval($0.trimmingCharacters(in: .whitespaces)) }
      return .rateLimited(wait)
    case 400..<500: return .refused(http.statusCode, WatchProblem.parse(data))
    default: return .server(http.statusCode)
    }
  }

  private func send(_ r: URLRequest, session: URLSession = WatchAPI.session) async throws -> (Data, HTTPURLResponse) {
    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: r)
    } catch {
      throw WatchAPI.map(error)
    }
    if let e = WatchAPI.check(response, data: data) { throw e }
    guard let http = response as? HTTPURLResponse else { throw WatchAPIError.badResponse }
    return (data, http)
  }

  private func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
    do { return try WatchJSON.decoder().decode(T.self, from: data) } catch { throw WatchAPIError.badResponse }
  }

  private func json<T: Encodable>(_ value: T) throws -> Data {
    do { return try WatchJSON.encoder().encode(value) } catch { throw WatchAPIError.badResponse }
  }

  // MARK: Who, and the glance

  /// GET /v1/watch/me. Also how a watch signing in with a code learns it was allowed.
  func me() async throws -> (WatchSelf, Data) {
    let (data, _) = try await send(try request("v1/watch/me"))
    return (try decode(WatchSelf.self, data), data)
  }

  enum GlanceResult {
    case fresh(Glance, Data, etag: String?)
    case notModified
  }

  /// GET /v1/glance, answering "not changed" when [etag] still holds. No `org_id`: the server
  /// answers for the key's own workspace, so a watch whose phone switched workspace while it was
  /// away still gets an answer (and learns the new workspace from /v1/watch/me).
  func glance(etag: String?, quick: Bool = false) async throws -> GlanceResult {
    var r = try request("v1/glance")
    if let etag, !etag.isEmpty { r.setValue(etag, forHTTPHeaderField: "If-None-Match") }
    let (data, http) = try await send(r, session: quick ? WatchAPI.quickSession : WatchAPI.session)
    if http.statusCode == 304 { return .notModified }
    let g = try decode(Glance.self, data)
    let tag = http.value(forHTTPHeaderField: "ETag") ?? (g.version.isEmpty ? nil : "\"\(g.version)\"")
    return .fresh(g, data, etag: tag)
  }

  // MARK: Chats, asking, replying

  func chat(bot: String, conversation: String? = nil) async throws -> (WatchChat, Data) {
    let q = conversation.map { [URLQueryItem(name: "conversation_id", value: $0)] } ?? []
    let (data, _) = try await send(try request("v1/watch/chats/\(bot)", query: q))
    return (try decode(WatchChat.self, data), data)
  }

  func ask(_ body: WatchAskBody, idempotencyKey: String) async throws -> WatchAsked {
    var r = try request("v1/watch/ask", method: "POST", body: try json(body), idempotencyKey: idempotencyKey)
    // A minute of audio through the phone's Bluetooth link takes a while, and the server may wait
    // up to a minute for the words: the plain session's 45 s for the whole exchange is too short.
    r.timeoutInterval = body.audio == nil ? 20 : 75
    let (data, _) = try await send(r, session: body.audio == nil ? WatchAPI.session : WatchAPI.askSession)
    return try decode(WatchAsked.self, data)
  }

  /// GET /v1/messages/{id}/speech: the reply in the bot's voice (MP3).
  func speech(message: String) async throws -> Data {
    var r = try request("v1/messages/\(message)/speech", accept: "audio/mpeg")
    r.timeoutInterval = 40
    let (data, _) = try await send(r)
    guard !data.isEmpty else { throw WatchAPIError.badResponse }
    return data
  }

  // MARK: Runs

  func run(_ id: String) async throws -> WatchRun {
    let (data, _) = try await send(try request("v1/watch/runs/\(id)"))
    return try decode(WatchRun.self, data)
  }

  /// The run as a stream of whole snapshots, until the server ends it (110 s, or the run ends).
  /// A server that answers with one JSON snapshot instead gives one element.
  func runStream(_ id: String) -> AsyncThrowingStream<WatchRun, Error> {
    let req: URLRequest
    do {
      req = try request("v1/watch/runs/\(id)", query: [URLQueryItem(name: "stream", value: "1")], accept: "text/event-stream")
    } catch {
      return AsyncThrowingStream { $0.finish(throwing: error) }
    }
    return AsyncThrowingStream { continuation in
      let task = Task {
        do {
          let (bytes, response) = try await WatchAPI.streamSession.bytes(for: req)
          if let e = WatchAPI.check(response, data: nil) { throw e }
          let type = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type") ?? ""
          let decoder = WatchJSON.decoder()
          if !type.contains("event-stream") {
            var data = Data()
            for try await b in bytes { data.append(b) }
            continuation.yield(try decoder.decode(WatchRun.self, from: data))
            continuation.finish()
            return
          }
          var lines = SSELineSplitter()
          var parser = SSEParser()
          for try await byte in bytes {
            guard let line = lines.push(byte), let event = parser.feed(line: line) else { continue }
            guard event.event == "run" || event.event == "message",
                  let run = try? decoder.decode(WatchRun.self, from: Data(event.data.utf8)) else { continue }
            continuation.yield(run)
          }
          if let last = lines.flush(), let event = parser.feed(line: last), event.event == "run",
             let run = try? decoder.decode(WatchRun.self, from: Data(event.data.utf8)) {
            continuation.yield(run)
          }
          continuation.finish()
        } catch is CancellationError {
          continuation.finish()
        } catch {
          continuation.finish(throwing: WatchAPI.map(error))
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  func cancelRun(_ id: String, surface: String = WatchSurface.app, idempotencyKey: String = UUID().uuidString) async throws {
    _ = try await send(try request("v1/runs/\(id)/cancel", method: "POST", body: Data("{}".utf8), idempotencyKey: idempotencyKey, surface: surface))
  }

  // MARK: Requests and suggestions

  func approval(_ id: String) async throws -> WatchApproval {
    let (data, _) = try await send(try request("v1/watch/approvals/\(id)"))
    return try decode(WatchApproval.self, data)
  }

  /// POST /v1/approvals/{id}/decision. Never Always Allow: that is a phone decision (§6.1 B).
  func decide(_ id: String, allow: Bool, surface: String = WatchSurface.app, idempotencyKey: String = UUID().uuidString) async throws {
    let body = try JSONSerialization.data(withJSONObject: ["decision": allow ? "approved" : "denied"])
    _ = try await send(try request("v1/approvals/\(id)/decision", method: "POST", body: body, idempotencyKey: idempotencyKey, surface: surface))
  }

  struct Started: Decodable {
    var runId: String?
    var conversationId: String?
  }

  func acceptSuggestion(_ id: String, surface: String = WatchSurface.app, idempotencyKey: String = UUID().uuidString) async throws -> Started? {
    let (data, _) = try await send(try request("v1/suggestions/\(id)/accept", method: "POST", body: Data("{}".utf8), idempotencyKey: idempotencyKey, surface: surface))
    return try? WatchJSON.decoder().decode(Started.self, from: data)
  }

  func dismissSuggestion(_ id: String, surface: String = WatchSurface.app, idempotencyKey: String = UUID().uuidString) async throws {
    let body = try JSONSerialization.data(withJSONObject: ["dont_suggest_again": false])
    _ = try await send(try request("v1/suggestions/\(id)/dismiss", method: "POST", body: body, idempotencyKey: idempotencyKey, surface: surface))
  }

  // MARK: Routines

  func runRoutine(_ id: String, surface: String = WatchSurface.app, idempotencyKey: String = UUID().uuidString) async throws -> Started? {
    let (data, _) = try await send(try request("v1/routines/\(id)/run", method: "POST", body: Data("{}".utf8), idempotencyKey: idempotencyKey, surface: surface))
    return try? WatchJSON.decoder().decode(Started.self, from: data)
  }

  // MARK: This watch

  func updateSelf(_ body: WatchSelfUpdateBody) async throws {
    _ = try await send(try request("v1/watch-keys/current", method: "PUT", body: try json(body), idempotencyKey: UUID().uuidString))
  }

  /// DELETE /v1/watch-keys/current: Sign out of this watch. A short wait: signing out mustn't
  /// hang on a bad connection.
  func signOut() async throws {
    _ = try await send(try request("v1/watch-keys/current", method: "DELETE"), session: WatchAPI.quickSession)
  }

  /// Open on iPhone when the phone isn't in reach: the person's phones get a notification.
  func handoff(link: String, title: String) async throws {
    let body = try json(WatchHandoffBody(link: link, title: String(title.prefix(100))))
    _ = try await send(try request("v1/watch/handoff", method: "POST", body: body, idempotencyKey: UUID().uuidString))
  }

  // MARK: Signed out

  /// POST /v1/watch/codes: a code to type into Casama on a phone or computer.
  static func requestCode(base: URL, device: WatchDeviceBody) async throws -> WatchCode {
    var r = URLRequest(url: base.appendingPathComponent("v1/watch/codes"))
    r.httpMethod = "POST"
    r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    r.setValue("application/json", forHTTPHeaderField: "Accept")
    do { r.httpBody = try WatchJSON.encoder().encode(device) } catch { throw WatchAPIError.badResponse }
    let data: Data
    let response: URLResponse
    do { (data, response) = try await session.data(for: r) } catch { throw map(error) }
    if let e = check(response, data: data) { throw e }
    do { return try WatchJSON.decoder().decode(WatchCode.self, from: data) } catch { throw WatchAPIError.badResponse }
  }
}

// MARK: - What the watch says about itself

enum WatchDeviceInfo {
  static var appVersion: String {
    (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
  }

  static var osVersion: String {
    let v = ProcessInfo.processInfo.operatingSystemVersion
    return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
  }

  /// Whether this build's push tokens belong to Apple's sandbox: a build installed from Xcode
  /// carries a profile that says aps-environment development; an App Store build has none.
  static var apnsSandbox: Bool {
    #if DEBUG
    return true
    #else
    let profile = Bundle.main.bundleURL.appendingPathComponent("embedded.mobileprovision")
    guard let data = try? Data(contentsOf: profile), let text = String(data: data, encoding: .isoLatin1) else { return false }
    return text.range(of: #"aps-environment</key>\s*<string>development</string>"#, options: .regularExpression) != nil
    #endif
  }
}
