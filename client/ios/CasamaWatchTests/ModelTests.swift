import Foundation

// MARK: - The watch's pure Swift, checked on macOS (scripts/test-watch-swift.sh)
//
// Decodes every shared sample answer (packages/contracts/fixtures/watch, the same files the
// server's and the Wear OS app's tests read), and checks the key's fingerprint, code formatting,
// relative times, links, the SSE parser and the offline queue's aging. No XCTest: a plain
// executable, so it runs without a build of the app or a simulator.

@main
struct ModelTests {
  static var failures = 0
  static var checks = 0

  static func check(_ ok: Bool, _ what: String, file: String = #fileID, line: Int = #line) {
    checks += 1
    if !ok {
      failures += 1
      print("FAIL \(file):\(line) \(what)")
    }
  }

  static func eq<T: Equatable>(_ a: T, _ b: T, _ what: String, file: String = #fileID, line: Int = #line) {
    check(a == b, "\(what): got \(a), want \(b)", file: file, line: line)
  }

  static func main() {
    let dir = CommandLine.arguments.dropFirst().first ?? "packages/contracts/fixtures/watch"
    fixtures(URL(fileURLWithPath: dir))
    key()
    codes()
    times()
    links()
    sse()
    queue()
    print("\(checks) checks, \(failures) failed")
    exit(failures == 0 ? 0 : 1)
  }

  // MARK: Fixtures

  static func load<T: Decodable>(_ type: T.Type, _ url: URL) -> T? {
    do {
      return try WatchJSON.decoder().decode(T.self, from: Data(contentsOf: url))
    } catch {
      check(false, "\(url.lastPathComponent) as \(T.self): \(error)")
      return nil
    }
  }

  static func fixtures(_ dir: URL) {
    guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path).filter({ $0.hasSuffix(".json") }).sorted(),
          !names.isEmpty else {
      check(false, "no fixtures in \(dir.path)")
      return
    }
    for name in names {
      let url = dir.appendingPathComponent(name)
      switch name {
      case let n where n.hasPrefix("approval_"):
        guard let a = load(WatchApproval.self, url) else { continue }
        check(!a.id.isEmpty && a.isPending, "\(n) pending with an id")
        if n == "approval_high.json" {
          eq(a.risk, .high, "high risk")
          eq(a.canAllow, .phone, "high risk is phone only")
          eq(a.whyPhoneText, WatchL10n.whyPayment, "why phone")
        }
        if n == "approval_medium.json" {
          eq(a.risk, .medium, "medium risk")
          eq(a.canAllow, .hold, "medium risk needs a hold")
          check(a.whyPhoneText == nil, "no reason when the watch may allow")
        }
      case "asked.json":
        guard let a = load(WatchAsked.self, url) else { continue }
        check(!a.conversationId.isEmpty && a.runId != nil && !a.heard.isEmpty, "asked has conversation, run and heard")
      case "chat.json":
        guard let c = load(WatchChat.self, url) else { continue }
        check(!c.bot.id.isEmpty && !c.messages.isEmpty, "chat has a bot and messages")
        check(c.messages.contains { $0.isMine } && c.messages.contains { !$0.isMine }, "chat has both sides")
      case "code.json":
        guard let c = load(WatchCode.self, url) else { continue }
        eq(WatchCodeFormat.display(c.code), "KQ7M 2XAB", "code display")
        eq(c.pollEveryS, 3, "poll every")
      case "glance.json":
        guard let g = load(Glance.self, url) else { continue }
        eq(g.needsCount, 2, "needs count")
        eq(g.needs.first?.bot, "Milo", "first need's bot")
        eq(g.needs.first?.risk, .medium, "first need's risk")
        check(!g.bots.isEmpty, "glance has bots")
        check(g.madeAt != nil, "glance has made_at")
        for r in g.liveRuns { check(!r.phase.ended, "live runs are live") }
      case "me.json":
        guard let m = load(WatchSelf.self, url) else { continue }
        eq(m.personName, "Oliver", "person name")
        eq(m.orgName, "Home", "org name")
        check(m.features.dictation && m.features.speech && !m.features.outOfCredits, "features")
        eq(m.quickReplies.count, 4, "quick replies")
      case let n where n.hasPrefix("run_"):
        guard let r = load(WatchRun.self, url) else { continue }
        switch n {
        case "run_working.json":
          eq(r.phase, .working, "working phase")
          eq(r.steps, 3, "working steps")
          check(r.endedAt == nil, "working has no end")
        case "run_needs_ok.json":
          eq(r.phase, .needsOk, "needs_ok phase")
          check(r.approval?.canAllow == .hold, "needs_ok carries its approval")
        case "run_finished.json":
          eq(r.phase, .finished, "finished phase")
          check(r.reply?.canSpeak == true, "finished reply can be spoken")
          if let s = r.startedAt, let e = r.endedAt { eq(e.timeIntervalSince(s), 88, "run length") } else { check(false, "finished has start and end") }
        default:
          check(true, n)
        }
      default:
        check(false, "\(name): no decoder for this fixture; add it to ModelTests")
      }
    }
    // Forgiving decoding: unknown enum values fall back, a bad row is skipped.
    let odd = Data(#"{"id":"a","risk":"spicy","can_allow":"wave","status":"weird"}"#.utf8)
    if let a = try? WatchJSON.decoder().decode(WatchApproval.self, from: odd) {
      eq(a.risk, .high, "unknown risk is high")
      eq(a.canAllow, .phone, "unknown can_allow is phone")
    } else {
      check(false, "odd approval decodes")
    }
    let rows = Data(#"{"bots":[{"id":"b1","name":"A"},{"name":"no id"},{"id":"b2","name":"B"}]}"#.utf8)
    if let g = try? WatchJSON.decoder().decode(Glance.self, from: rows) {
      eq(g.bots.map(\.id), ["b1", "b2"], "a row without an id is skipped")
      eq(g.needsCount, 0, "no needs block is zero")
    } else {
      check(false, "glance with odd rows decodes")
    }
  }

  // MARK: Key

  static func key() {
    let zero = WatchKeyMaker.prefix + WatchKeyMaker.base64url(Data(count: 32))
    eq(zero, "cwt_" + String(repeating: "A", count: 43), "zero key")
    eq(zero.count, 47, "key length")
    // Known vector, same as the Wear OS test: printf '%s' "casama-watch-key:cwt_AAA…A" | shasum -a 256
    eq(WatchKeyMaker.fingerprint(zero), "ac37bdc0613002302fb038066df0bce2d9912dce2e82f625e1f7eacd95677778", "fingerprint vector")
    let made = WatchKeyMaker.make()
    check(WatchKeyMaker.isWellFormed(made), "a made key is well formed")
    check(made != WatchKeyMaker.make(), "keys differ")
    check(!WatchKeyMaker.isWellFormed("cwt_short"), "short key rejected")
    check(!WatchKeyMaker.isWellFormed("xyz_" + String(repeating: "A", count: 43)), "wrong prefix rejected")
    check(WatchKeyMaker.fingerprint(made).range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil, "fingerprint is hex")
  }

  // MARK: Codes

  static func codes() {
    eq(WatchCodeFormat.display("kq7m2xab"), "KQ7M 2XAB", "lowercase code")
    eq(WatchCodeFormat.display("KQ7M-2XAB"), "KQ7M 2XAB", "dashed code")
    eq(WatchCodeFormat.display("ABC"), "ABC", "short code")
    eq(WatchCodeFormat.spoken("KQ7M"), "K Q 7 M", "spoken code")
  }

  // MARK: Times

  static func times() {
    let utc = TimeZone(identifier: "UTC")!
    let en = Locale(identifier: "en_US_POSIX")
    let now = WatchDate.parse("2026-11-19T09:00:00Z")!
    eq(WatchTime.upcoming(now.addingTimeInterval(12 * 60), now: now, locale: en, timeZone: utc), WatchL10n.inMinutes("12"), "in 12 min")
    eq(WatchTime.upcoming(now.addingTimeInterval(30), now: now, locale: en, timeZone: utc), WatchL10n.inMinutes("1"), "under a minute rounds up")
    let later = WatchTime.upcoming(now.addingTimeInterval(3 * 3600), now: now, locale: en, timeZone: utc)
    eq(later, WatchTime.clock(now.addingTimeInterval(3 * 3600), locale: en, timeZone: utc), "later today is a clock")
    check(later.contains("12"), "noon reads as 12: \(later)")
    let friday = WatchTime.upcoming(now.addingTimeInterval(2 * 86_400), now: now, locale: en, timeZone: utc)
    eq(friday, WatchTime.dayClock(now.addingTimeInterval(2 * 86_400), locale: en, timeZone: utc), "this week is day and clock")
    let far = WatchTime.upcoming(now.addingTimeInterval(20 * 86_400), now: now, locale: en, timeZone: utc)
    eq(far, WatchTime.day(now.addingTimeInterval(20 * 86_400), locale: en, timeZone: utc), "later is a day")
    eq(WatchTime.asOf(now.addingTimeInterval(-600), now: now, locale: en, timeZone: utc),
       WatchL10n.asOf(WatchTime.clock(now.addingTimeInterval(-600), locale: en, timeZone: utc)), "as of")
    eq(WatchTime.briefLine(now.addingTimeInterval(22 * 3600), now: now, locale: en, timeZone: utc),
       WatchL10n.briefTomorrow(WatchTime.clock(now.addingTimeInterval(22 * 3600), locale: en, timeZone: utc)), "brief tomorrow")
    eq(WatchTime.elapsed(42), "0:42", "elapsed seconds")
    eq(WatchTime.elapsed(134), "2:14", "elapsed minutes")
    eq(WatchTime.elapsed(3723), "1:02:03", "elapsed hours")
    eq(WatchTime.elapsed(-5), "0:00", "elapsed never negative")
  }

  // MARK: Links

  static func links() {
    eq(WatchLink.parse(route: "/approvals/abc"), .approval("abc"), "approval route")
    eq(WatchLink.parse(route: "/open/approvals/abc"), .approval("abc"), "casama.ai/open route")
    eq(WatchLink.parse(route: "/somewhere/else"), .now, "unknown route is Now")
    if let url = URL(string: "casama://app/approvals/abc") { eq(WatchLink.parse(url), .approval("abc"), "casama:// link") }
    for link in [WatchLink.now, .needs, .approval("a1"), .suggestion("s1"), .run("r1"), .chat(bot: "b1", conversation: "c1"),
                 .chat(bot: "b1", conversation: nil), .ask(bot: "b1"), .ask(bot: nil), .bots, .upNext, .brief, .talk(bot: "b1"), .settings] {
      eq(WatchLink.parse(route: link.route), link, "round trip \(link.route)")
    }
  }

  // MARK: SSE

  static func sse() {
    var splitter = SSELineSplitter()
    var parser = SSEParser()
    var events: [SSEEvent] = []
    let stream = "event: run\r\ndata: {\"a\":\ndata: 1}\n\n: comment\nevent: run\ndata: two\r\rdata: plain\n\n"
    for byte in stream.utf8 {
      if let line = splitter.push(byte), let e = parser.feed(line: line) { events.append(e) }
    }
    if let line = splitter.flush(), let e = parser.feed(line: line) { events.append(e) }
    if let e = parser.finish() { events.append(e) }
    eq(events.count, 3, "three events")
    eq(events.first?.event, "run", "event name")
    eq(events.first?.data, "{\"a\":\n1}", "multi-line data")
    eq(events.dropFirst().first?.data, "two", "CR line ends")
    eq(events.last?.event, "message", "default event name")
  }

  // MARK: Offline queue

  static func queue() {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    func ask(_ age: TimeInterval) -> QueuedAsk {
      QueuedAsk(id: "\(age)", botId: "b", botName: "B", conversationId: nil, text: "hi", audioFile: nil, mime: nil,
                askedAt: now.addingTimeInterval(-age), idempotencyKey: "k\(age)")
    }
    check(!AskQueuePolicy.needsConfirm(ask(60), now: now), "a minute old goes")
    check(AskQueuePolicy.needsConfirm(ask(11 * 60), now: now), "eleven minutes old asks first")
    check(AskQueuePolicy.isStale(ask(25 * 3600), now: now), "a day old is dropped")
    let (send, confirm) = AskQueuePolicy.split([ask(60), ask(11 * 60), ask(25 * 3600)], now: now)
    eq(send.map(\.id), ["60.0"], "sent now")
    eq(confirm.map(\.id), ["660.0"], "waiting for a yes")
    // Kept asks survive a round trip through preferences.
    let a = ask(60)
    if let data = try? JSONEncoder().encode([a]), let back = try? JSONDecoder().decode([QueuedAsk].self, from: data) {
      eq(back, [a], "queue round trip")
    } else {
      check(false, "queue encodes")
    }
  }
}
