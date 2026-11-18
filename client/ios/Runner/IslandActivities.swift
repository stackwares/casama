import ActivityKit
import AppIntents
import Flutter
import Foundation

// MARK: - The island on the iPhone: Live Activities (D-324, docs/ISLAND-AND-MENU-BAR-PLAN.md §8.5)
//
// The casama/island channel's iOS side. Dart sends the island feed (only runs the person started,
// already cut down for the Lock Screen); this starts an activity for each new run, updates it as
// the feed changes, ends it as Finished (kept 15 minutes) or at once when the person stopped it,
// and hands each activity's push token to Dart so the server can update it while the app sleeps.

final class IslandActivities {
  static let shared = IslandActivities()

  /// A Lock Screen state goes stale two minutes after its last update.
  static let staleAfter: TimeInterval = 120
  /// Finished stays on the Lock Screen for 15 minutes (decision 9).
  static let finishedFor: TimeInterval = 15 * 60

  private var channel: FlutterMethodChannel?
  /// The content each activity was last given, so an unchanged feed sends no update.
  private var lastContent: [String: RunActivityAttributes.ContentState] = [:]
  /// Runs this process has shown, so one it never saw isn't ended before Dart has caught up.
  private var shown = Set<String>()
  /// Token watchers, keyed "run|activity" (a run can briefly have two activities: the app's and
  /// one the server started).
  private var tokenTasks: [String: Task<Void, Never>] = [:]
  /// The state being applied, so states apply one at a time in the order they came: two at once
  /// could both find a new run without an activity and start two.
  private var applying: Task<Void, Never>?
  /// Each run's newest push token, as sent to Dart.
  private var tokens: [String: String] = [:]
  /// Push-to-start (iOS 17.2+) and new-activity watchers, started once.
  private var startTasks: [Task<Void, Never>] = []
  /// Dart has sent a state since launch, so its bridge answers actions.
  private var ready = false
  /// Where to open the app once Dart is ready, after a button that couldn't act in place.
  private var pendingLink: String?
  /// The newest push-to-start token, sent again once Dart listens (a message sent before Dart's
  /// handler exists can be dropped).
  private var startToken: String?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/island", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "state":
        let state = call.arguments as? [String: Any] ?? [:]
        guard #available(iOS 16.2, *), let self = self else { return result(false) }
        let previous = self.applying
        if !self.ready {
          // Dart listens now: tokens handed over before it did may have been dropped.
          if let token = self.startToken {
            self.channel?.invokeMethod("start_token", arguments: ["token": token])
          }
          for (run, token) in self.tokens {
            self.channel?.invokeMethod("token", arguments: ["run_id": run, "token": token])
          }
        }
        self.ready = true
        if let link = self.pendingLink {
          self.pendingLink = nil
          self.channel?.invokeMethod("action", arguments: ["kind": "open", "link": link])
        }
        let task = Task { @MainActor in
          await previous?.value
          await self.apply(state)
          result(ActivityAuthorizationInfo().areActivitiesEnabled)
        }
        self.applying = task
      #if DEBUG
      case "debug":
        // The on-device check (client/integration_test/island_ios_test.dart) reads what is shown.
        guard #available(iOS 16.2, *) else { return result([]) }
        result(Activity<RunActivityAttributes>.activities.map { a -> [String: Any] in
          let s = a.content.state
          return [
            "run_id": a.attributes.runId,
            "bot": a.attributes.botName,
            "state": "\(a.activityState)",
            "phase": s.phase,
            "step": s.step,
            "detail": s.detail ?? "",
            "steps": s.steps,
            "approval_id": s.approvalId ?? "",
            "stale_in": a.content.staleDate.map { Int($0.timeIntervalSinceNow) } ?? -1,
            "token": self?.tokens[a.attributes.runId] != nil,
            "enabled": ActivityAuthorizationInfo().areActivitiesEnabled,
          ]
        })
      #endif
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
    if #available(iOS 17.0, *) {
      // attach runs on the main thread, as the engine is set up.
      MainActor.assumeIsolated { installActions() }
    }
    if #available(iOS 16.2, *) {
      // Activities that outlived the last launch: their tokens may have changed.
      for activity in Activity<RunActivityAttributes>.activities { watchToken(activity) }
      watchStarts()
    }
  }

  /// Lets the Live Activity buttons (RunActionIntents.swift) act through this app.
  @available(iOS 17.0, *)
  @MainActor
  private func installActions() {
    RunActions.perform = { [weak self] args, fallback, intent in
      if await self?.perform(args, fallback: fallback) == true { return }
      // Couldn't act in place: iOS brings the app forward, where the fallback opens.
      switch intent {
      case let i as StopRunIntent: throw i.needsToContinueInForegroundError()
      case let i as AnswerRequestIntent: throw i.needsToContinueInForegroundError()
      case let i as RunRoutineWidgetIntent: throw i.needsToContinueInForegroundError()
      case let i as AcceptSuggestionIntent: throw i.needsToContinueInForegroundError()
      default: return
      }
    }
  }

  /// A Live Activity button (RunActionIntents.swift) acting through Dart without opening the app.
  /// iOS may have just started the app for it, so Dart gets 10 seconds to come up. If it can't act,
  /// [fallback] opens once the app is in front (the intent asks iOS to bring it there).
  @MainActor
  func perform(_ args: [String: Any], fallback: String) async -> Bool {
    var waited = 0
    while !ready && waited < 40 {
      try? await Task.sleep(nanoseconds: 250_000_000)
      waited += 1
    }
    guard ready, let channel = channel else {
      pendingLink = fallback
      return false
    }
    let done: Bool = await withCheckedContinuation { c in
      channel.invokeMethod("action", arguments: args) { c.resume(returning: ($0 as? Bool) == true) }
    }
    if !done {
      // Dart is up: open it there as soon as iOS brings the app forward.
      channel.invokeMethod("action", arguments: ["kind": "open", "link": fallback])
    }
    return done
  }

  /// Push-to-start (D-324, Phase 6; decision 11). ActivityKit hands over a token that lets the
  /// server start an activity for a run the person began on another device; it goes to Dart, which
  /// registers it unless Settings → Bots you start elsewhere is off. An activity the server started
  /// shows up in `activityUpdates`, and its own push token is watched like any other, so later
  /// updates follow it.
  @available(iOS 16.2, *)
  private func watchStarts() {
    guard startTasks.isEmpty else { return }
    if #available(iOS 17.2, *) {
      startTasks.append(Task { [weak self] in
        for await data in Activity<RunActivityAttributes>.pushToStartTokenUpdates {
          let token = data.map { String(format: "%02x", $0) }.joined()
          await MainActor.run {
            self?.startToken = token
            _ = self?.channel?.invokeMethod("start_token", arguments: ["token": token])
          }
        }
      })
    }
    startTasks.append(Task { [weak self] in
      for await activity in Activity<RunActivityAttributes>.activityUpdates {
        await MainActor.run { self?.watchToken(activity) }
      }
    })
  }

  @available(iOS 16.2, *)
  @MainActor
  private func apply(_ state: [String: Any]) async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let labels = state["labels"] as? [String: String] ?? [:]
    // Dart has checked the server at least once since launch: a run it doesn't list is over.
    let synced = state["synced"] as? Bool ?? false
    var wanted: [String: [String: Any]] = [:]
    for case let item as [String: Any] in state["items"] as? [Any] ?? [] {
      if let run = item["run_id"] as? String, !(item["here"] as? Bool ?? false) { wanted[run] = item }
    }
    var existing: [String: Activity<RunActivityAttributes>] = [:]
    // Runs whose activity has ended (here or by a server push) but is still on the Lock Screen:
    // never started again, even if the feed hasn't caught up yet.
    var ended = Set<String>()
    for a in Activity<RunActivityAttributes>.activities {
      switch a.activityState {
      case .active, .stale:
        // The server's start and this app's can cross for one run: keep one activity.
        if existing[a.attributes.runId] != nil {
          tokenTasks.removeValue(forKey: "\(a.attributes.runId)|\(a.id)")?.cancel()
          await a.end(nil, dismissalPolicy: .immediate)
          continue
        }
        existing[a.attributes.runId] = a
      case .ended: ended.insert(a.attributes.runId)
      default: break
      }
    }

    for (run, item) in wanted {
      let content = Self.content(item)
      if let activity = existing[run] {
        shown.insert(run)
        if let last = lastContent[run], Self.same(last, content) { continue }
        lastContent[run] = content
        if content.ended {
          await activity.end(ActivityContent(state: content, staleDate: nil), dismissalPolicy: .after(Date().addingTimeInterval(Self.finishedFor)))
        } else {
          await activity.update(ActivityContent(state: content, staleDate: Date().addingTimeInterval(Self.staleAfter)))
        }
      } else if !content.ended, !ended.contains(run) {
        let attributes = RunActivityAttributes(
          runId: run,
          botId: item["bot_id"] as? String ?? "",
          botName: item["bot"] as? String ?? "",
          botAvatar: (item["bot_avatar"] as? String).flatMap { $0.isEmpty ? nil : $0 },
          startedAt: (item["started_at"] as? NSNumber)?.doubleValue ?? Date().timeIntervalSince1970,
          link: item["link"] as? String ?? "/",
          labels: labels
        )
        do {
          let activity = try Activity.request(
            attributes: attributes,
            content: ActivityContent(state: content, staleDate: Date().addingTimeInterval(Self.staleAfter)),
            pushType: .token
          )
          shown.insert(run)
          lastContent[run] = content
          watchToken(activity)
        } catch {
          // Too many activities, or the person turned them off: the app still shows the run.
          NSLog("island: no Live Activity for \(run): \(error)")
        }
      }
    }

    // A run the feed no longer lists: the person stopped it (it leaves at once, D-324), or it
    // ended while Finished wasn't shown. Only once Dart has caught up with the server.
    for (run, activity) in existing where wanted[run] == nil && (shown.contains(run) || synced) {
      let last = lastContent[run] ?? activity.content.state
      if last.ended { continue }
      await activity.end(nil, dismissalPolicy: .immediate)
      forget(run)
    }
  }

  private func forget(_ run: String) {
    lastContent[run] = nil
    shown.remove(run)
    for key in tokenTasks.keys where key.hasPrefix("\(run)|") { tokenTasks.removeValue(forKey: key)?.cancel() }
    tokens[run] = nil
  }

  /// Sends each push token the activity is given to Dart, which registers it for the run.
  @available(iOS 16.2, *)
  private func watchToken(_ activity: Activity<RunActivityAttributes>) {
    let run = activity.attributes.runId
    let key = "\(run)|\(activity.id)"
    guard tokenTasks[key] == nil else { return }
    tokenTasks[key] = Task { [weak self] in
      for await data in activity.pushTokenUpdates {
        let token = data.map { String(format: "%02x", $0) }.joined()
        await MainActor.run {
          self?.tokens[run] = token
          self?.channel?.invokeMethod("token", arguments: ["run_id": run, "token": token])
        }
      }
    }
  }

  /// Whether two states show the same thing (when they were made doesn't count).
  static func same(_ a: RunActivityAttributes.ContentState, _ b: RunActivityAttributes.ContentState) -> Bool {
    var b = b
    b.updatedAt = a.updatedAt
    return a == b
  }

  /// A feed item as an activity's content (island_feed.dart, IslandItem.toJson).
  static func content(_ item: [String: Any]) -> RunActivityAttributes.ContentState {
    RunActivityAttributes.ContentState(
      phase: item["phase"] as? String ?? "working",
      step: item["step"] as? String ?? "",
      detail: item["detail"] as? String,
      steps: item["steps"] as? Int ?? 0,
      approvalId: item["approval_id"] as? String,
      risk: item["risk"] as? String,
      updatedAt: Date().timeIntervalSince1970.rounded(),
      endedAt: (item["ended_at"] as? NSNumber)?.doubleValue
    )
  }
}

// Only the app may ask iOS to bring it forward (RunActionIntents.swift is built into the widget
// extension too, where this is unavailable).
@available(iOS 17.0, *)
extension StopRunIntent: ForegroundContinuableIntent {}

@available(iOS 17.0, *)
extension AnswerRequestIntent: ForegroundContinuableIntent {}

// The widgets' and controls' buttons (D-405 §8.4).
@available(iOS 17.0, *)
extension RunRoutineWidgetIntent: ForegroundContinuableIntent {}

@available(iOS 17.0, *)
extension AcceptSuggestionIntent: ForegroundContinuableIntent {}
