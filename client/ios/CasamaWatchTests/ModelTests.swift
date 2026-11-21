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
    let vectors = CommandLine.arguments.dropFirst(2).first ?? "packages/domain/test/fixtures/bot-avatar-vectors.json"
    botAvatars(URL(fileURLWithPath: vectors))
    botPictureFiles()
    key()
    codes()
    times()
    links()
    sse()
    queue()
    signIns()
    phoneRoutes()
    problems()
    scope()
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
    // An ask kept by an older build has no try count.
    let old = #"[{"id":"x","botId":"b","botName":"B","askedAt":0,"idempotencyKey":"k"}]"#
    eq((try? JSONDecoder().decode([QueuedAsk].self, from: Data(old.utf8)))?.first?.tries, nil, "an older kept ask still reads")
    // A refusal that won't change ends a kept ask; a server that failed keeps it for a few tries.
    eq(AskQueuePolicy.afterFailure(status: 400, tries: 1), .drop, "nothing heard is dropped")
    eq(AskQueuePolicy.afterFailure(status: 402, tries: 1), .drop, "out of credits is dropped")
    eq(AskQueuePolicy.afterFailure(status: 404, tries: 1), .drop, "no such bot is dropped")
    eq(AskQueuePolicy.afterFailure(status: 500, tries: 1), .keep, "a server error is kept")
    eq(AskQueuePolicy.afterFailure(status: 502, tries: 3), .keep, "and kept again")
    eq(AskQueuePolicy.afterFailure(status: 409, tries: 1), .keep, "a voice service that is down is kept")
    eq(AskQueuePolicy.afterFailure(status: nil, tries: 1), .keep, "an answer that couldn't be read is kept")
    eq(AskQueuePolicy.afterFailure(status: 500, tries: AskQueuePolicy.maxTries), .drop, "but not for ever")
  }

  // MARK: Sign-in requests to the phone

  static func signIns() {
    let a = IssuedSignIns.none.adding("r1", for: "fp-a")
    check(a.accepts("r1", for: "fp-a"), "an answer to this watch's request signs it in")
    check(!a.accepts("r2", for: "fp-a"), "an answer to a request it never made doesn't")
    check(!a.accepts("r1", for: "fp-b"), "nor one made for a key it no longer holds")
    check(!a.accepts(nil, for: "fp-a"), "nor one with no request id")
    check(!IssuedSignIns.none.accepts("r1", for: ""), "nothing is accepted with no key")
    // Asking again keeps the earlier ids for the same key (the phone may answer an older one).
    let b = a.adding("r2", for: "fp-a")
    check(b.accepts("r1", for: "fp-a") && b.accepts("r2", for: "fp-a"), "both requests for one key count")
    // A new key starts over: the old key's requests are forgotten.
    let c = b.adding("r3", for: "fp-b")
    eq(c.ids, ["r3"], "a new key forgets the old key's requests")
    check(!c.accepts("r1", for: "fp-b"), "an old request can't sign a new key in")
    // Only the last few are kept.
    var many = IssuedSignIns.none
    for i in 0..<10 { many = many.adding("r\(i)", for: "fp") }
    eq(many.ids.count, IssuedSignIns.kept, "the last few requests are kept")
    check(many.accepts("r9", for: "fp") && !many.accepts("r0", for: "fp"), "the newest stay, the oldest go")
    if let data = try? JSONEncoder().encode(b), let back = try? JSONDecoder().decode(IssuedSignIns.self, from: data) {
      eq(back, b, "requests round trip")
    } else {
      check(false, "requests encode")
    }

    // Asking the phone again by itself, when the app comes forward while it is still waiting.
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    let longAgo = now.addingTimeInterval(-120)
    func reask(waiting: Bool = true, last: Date = longAgo, reason: String? = nil, https: Bool = false, code: Bool = false) -> Bool {
      PhoneReask.allowed(waiting: waiting, lastAsk: last, now: now, lastReason: reason, needsHttps: https, fetchingCode: code)
    }
    check(reask(), "still waiting, and it has been a while: ask again")
    check(reask(reason: "signed_out") && reask(reason: "error"), "a phone that wasn't signed in, or failed, is asked again")
    check(!reask(reason: "declined"), "a No on the phone is not asked again")
    check(!reask(waiting: false), "not while the first ask is still out, or on another screen")
    check(!reask(last: now.addingTimeInterval(-5)), "not on every wrist raise")
    check(!reask(https: true), "not while the screen says the phone's server can't be reached")
    check(!reask(code: true), "not while a code is being fetched")
  }

  // MARK: Links for Open on iPhone

  static func phoneRoutes() {
    eq(PhoneRoutes.first("/approvals/a1", "/x", else: "/bots"), "/approvals/a1", "the server's link comes first")
    eq(PhoneRoutes.first(nil, "", "/bots/b1/chat", else: "/bots"), "/bots/b1/chat", "empty and missing links are skipped")
    eq(PhoneRoutes.first(nil, "", else: PhoneRoutes.needsYou), "/inbox?tab=0", "with none, the fallback")
    // Fallbacks are routes the phone's router has (client/lib/core/router.dart).
    eq(PhoneRoutes.needsYou, "/inbox?tab=0", "Needs you on the phone, as the glance links a suggestion")
    eq(PhoneRoutes.home, "/bots", "the chats")
    eq(PhoneRoutes.approval("a1"), "/approvals/a1", "a request")
    eq(PhoneRoutes.chat(bot: "b1", conversation: "c1"), "/bots/b1/chat?c=c1", "a chat")
    eq(PhoneRoutes.call(bot: "b1"), "/bots/b1/call", "a call")
  }

  // MARK: What a refusal means

  static func problems() {
    func problem(_ json: String) -> WatchProblem? { WatchProblem.parse(Data(json.utf8)) }
    let elsewhere = problem(#"{"type":"https://casama.ai/problems/not_found","title":"Not Found","status":404,"code":"not_found","detail":"Not found in this watch's workspace"}"#)
    eq(elsewhere?.code, "not_found", "the problem's code is read")
    eq(elsewhere?.detail, "Not found in this watch's workspace", "and its detail")
    eq(problem(#"{"title":"Conflict"}"#)?.detail, "Conflict", "the title stands in for a missing detail")
    check(WatchProblem.parse(Data("not json".utf8)) == nil && WatchProblem.parse(nil) == nil, "no problem in an answer that isn't one")

    eq(WatchRefusal.of(status: 404, problem: elsewhere), .elsewhere, "404 not_found is another workspace")
    eq(WatchRefusal.of(status: 404, problem: WatchProblem(code: "approval_not_found", detail: nil)), .alreadyAnswered, "a request that is gone was answered")
    eq(WatchRefusal.of(status: 404, problem: nil), .alreadyAnswered, "a bare 404 too")
    eq(WatchRefusal.of(status: 409, problem: WatchProblem(code: "approval_already_decided", detail: "x")), .alreadyAnswered, "already decided")
    eq(WatchRefusal.of(status: 409, problem: WatchProblem(code: "suggestion_closed", detail: "x")), .alreadyAnswered, "a closed suggestion")
    eq(WatchRefusal.of(status: 409, problem: nil), .alreadyAnswered, "a bare 409")
    // Stop on a run that ended a moment ago (POST /v1/runs/{id}/cancel): over already, not a refusal.
    eq(WatchRefusal.of(status: 409, problem: WatchProblem(code: "run_finished", detail: "The run is already completed")), .alreadyAnswered, "a run that already ended")
    eq(WatchRefusal.of(status: 409, problem: WatchProblem(code: "something_finished", detail: "x")), .alreadyAnswered, "anything else that is over")
    eq(WatchRefusal.of(status: 409, problem: WatchProblem(code: "no_model_configured", detail: "This bot has no model.")),
       .refused("This bot has no model."), "a run that couldn't start says why, not 'already answered'")
    // Do It on a suggestion whose run can't start for another reason (startVerdict's codes): its words.
    for code in ["run_not_found", "max_steps_exceeded", "wall_time_exceeded"] {
      eq(WatchRefusal.of(status: 409, problem: WatchProblem(code: code, detail: "Why")), .refused("Why"), "\(code) says why")
    }
    // The limits the server answers 402 for, whatever their code.
    for code in ["out_of_credits", "quota_exceeded", "cloud_daily_cap", "computer_hours_exceeded", "plan_limit"] {
      eq(WatchRefusal.of(status: 402, problem: WatchProblem(code: code, detail: "x")), .outOfCredits, "\(code) is a limit")
    }
    eq(WatchRefusal.of(status: 402, problem: WatchProblem(code: "out_of_credits", detail: "x")), .outOfCredits, "402 is out of credits")
    eq(WatchRefusal.of(status: 400, problem: WatchProblem(code: "nothing_heard", detail: "Nothing was heard")), .refused("Nothing was heard"), "another refusal keeps its words")

    // The reason a watch may not allow is never shown as the server's word.
    for reason in ["high_risk", "payment", "setting", "workspace", "not_yours"] {
      let text = WatchWhy.text(reason)
      check(text != nil && text != reason, "\(reason) is said in the person's words")
    }
    eq(WatchWhy.text("something_new"), nil, "an unknown reason has no words here")
    eq(WatchWhy.text(nil), nil, "no reason, no words")
  }

  // MARK: Workspaces, servers, staleness

  static func scope() {
    check(PushScope.isElsewhere(pushOrg: "aaaa", watchOrg: "bbbb"), "a push about another workspace")
    check(!PushScope.isElsewhere(pushOrg: "AAAA", watchOrg: "aaaa"), "the same workspace, whatever the case")
    check(!PushScope.isElsewhere(pushOrg: nil, watchOrg: "aaaa"), "an older server's push has no workspace: this one's")
    check(!PushScope.isElsewhere(pushOrg: "", watchOrg: "aaaa"), "an empty workspace too")
    check(!PushScope.isElsewhere(pushOrg: "aaaa", watchOrg: nil), "a watch that doesn't know its workspace guesses nothing")

    func usable(_ s: String) -> Bool { URL(string: s).map(WatchServer.usable) ?? false }
    check(usable("https://api.casama.ai"), "https anywhere")
    check(usable("http://192.168.1.20:8787"), "http to an address on the network")
    check(usable("http://casama.local:8787"), "http to a .local name")
    check(usable("http://localhost:8787") && usable("http://nas"), "http to a bare name")
    check(!usable("http://casama.example.com"), "not plain http to a public name")
    check(!usable("http://1.2.3.4.example.com") && !usable("http://300.1.1.1.com"), "a name that only looks like an address")
    check(!usable("ftp://192.168.1.20"), "nothing but http and https")

    let now = Date(timeIntervalSince1970: 2_000_000_000)
    check(!GlanceAge.isStale(savedAt: now.addingTimeInterval(-10 * 60), now: now), "ten minutes old is still now")
    check(GlanceAge.isStale(savedAt: now.addingTimeInterval(-31 * 60), now: now), "half an hour old is dated")
    check(GlanceAge.isStale(savedAt: nil, now: now), "never saved is dated")

    check(WristPolicy.isNoPasscode(errorCode: -5, passcodeNotSetCode: -5), "passcodeNotSet is reported as noPasscode")
    check(!WristPolicy.isNoPasscode(errorCode: -6, passcodeNotSetCode: -5), "other LocalAuthentication errors are not noPasscode")
    check(!WristPolicy.isNoPasscode(errorCode: nil, passcodeNotSetCode: -5), "missing error is not noPasscode")
  }

  // MARK: Bot pictures (docs/BOT-PICTURES-PLAN.md §5)

  /// Every shared vector of `bots.avatar_url` (the same file the TypeScript, Dart and Kotlin parsers
  /// read), through BotPalette and BotPicture.
  static func botAvatars(_ file: URL) {
    guard let data = try? Data(contentsOf: file),
          let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
          let vectors = root["vectors"] as? [[String: Any]], !vectors.isEmpty else {
      check(false, "no bot avatar vectors in \(file.path)")
      return
    }
    func hex(_ s: String) -> UInt32 { UInt32(s.dropFirst(), radix: 16) ?? 0 }
    for v in vectors {
      let value = v["value"] as? String
      let kind = v["kind"] as? String ?? ""
      let picture = BotPalette.picture(value)
      let mascot = BotPalette.mascot(value)
      switch kind {
      case "image":
        let id = v["id"] as? String ?? ""
        let colors = v["colors"] as? [String] ?? []
        eq(picture?.id, id, "\(value ?? "nil") is the picture \(id)")
        eq(picture?.colors.0, colors.first.map(hex), "\(value ?? "nil") first colour")
        eq(picture?.colors.1, colors.last.map(hex), "\(value ?? "nil") second colour")
        check(mascot == nil, "\(value ?? "nil") is no mascot")
      case "mascot":
        eq(mascot, v["mascot"] as? String, "\(value ?? "nil") is that mascot")
        check(picture == nil, "\(value ?? "nil") is no picture")
      default:
        check(picture == nil && mascot == nil, "\(value ?? "nil") reads as initials")
      }
    }
    check(BotPicture.ids([vectors[7]["value"] as? String, nil, "mascot:winky"]) == [vectors[7]["id"] as? String ?? ""],
          "ids are the pictures' ids only")
    // A trailing newline is not part of a picture value, whatever a regex's `$` would say.
    check(BotPalette.picture("image:6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f:7a90ff7de9f4\n") == nil, "no trailing newline")
  }

  /// The store's files: ids become file names only when they are uuids, PNGs are told by their
  /// signature, and a prune keeps what is listed and what is new.
  static func botPictureFiles() {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("bot-pictures-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: dir) }
    let store = BotPictureStore(directory: dir)
    let kept = "6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f"
    let old = "00000000-0000-0000-0000-000000000000"
    let fresh = "11111111-1111-1111-1111-111111111111"
    check(store.file("../etc/passwd") == nil && store.file(kept.uppercased()) == nil, "only a uuid names a file")
    check(store.image(kept) == nil && !store.has(kept), "nothing there before it is saved")
    check(BotPictureStore.isPNG(Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0])), "a PNG signature")
    check(!BotPictureStore.isPNG(Data("<html>".utf8)), "not a page")
    for id in [kept, old, fresh] { try? Data([0x89, 0x50]).write(to: store.file(id)!) }
    try? FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -2 * 86400)], ofItemAtPath: store.file(old)!.path)
    try? FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -2 * 86400)], ofItemAtPath: store.file(kept)!.path)
    store.prune(keep: [kept])
    check(store.has(kept), "a listed picture stays")
    check(!store.has(old), "an unused old picture goes")
    check(store.has(fresh), "an unused new one waits out the grace period")
  }
}
